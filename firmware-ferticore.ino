// ============================================================
//  FETCORE AI — ESP32 BLE FIRMWARE
//  Hardware : ESP32 + OLED SSD1306 + MOSFET Module
//  Versi    : 2.0
//  Update   : Pin D16/D17, satuan mL, hold-to-pump trigger
// ============================================================

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Preferences.h>

// ============================================================
//  KONFIGURASI PIN HARDWARE
// ============================================================
const int pinSDA             = 21;   // OLED SDA
const int pinSCL             = 22;   // OLED SCL
const int pinMosfet          = 26;   // MOSFET module -> kontrol pompa
const int pinBtnDosisKurang  = 16;   // D16 -> kurangi dosis (klik, per 5 mL)
const int pinBtnDosisTambah  = 17;   // D17 -> tambah dosis  (klik, per 5 mL)
const int pinBtnTrigger      = 33;   // Trigger pompa (TAHAN = nyala, LEPAS = mati)

// ============================================================
//  KONFIGURASI OLED
// ============================================================
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_ADDR     0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
Preferences preferences;

// ============================================================
//  KONFIGURASI BLE — Nordic UART Service (NUS)
//  UUID harus sama persis dengan BleService di Flutter
// ============================================================
#define DEVICE_NAME            "FETCORE-01"
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"  // HP -> ESP32
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"  // ESP32 -> HP

BLEServer*         pServer           = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected    = false;
bool oldDeviceConnected = false;

// ============================================================
//  VARIABEL LOGIKA & STATISTIK
// ============================================================
float dosisMl     = 5.0;    // Settingan dosis saat ini (mL)
float maxDosisMl  = 200.0;  // Batas maksimum dosis
float stepDosisMl = 5.0;    // Langkah per klik tombol fisik
int   waktuPer5Ml = 3000;   // Durasi pompa untuk 5 mL (ms) — kalibrasi di sini

float totalVolumeMl  = 0.0;
int   totalSesiPompa = 0;

// Status pompa
bool          isPompaRunning  = false;
bool          pompaFromButton = false;  // true = hold fisik | false = BLE timed
unsigned long waktuMulaiPompa = 0;
unsigned long durasiPompa     = 3000;  // durasi untuk BLE trigger (dihitung dari dosisMl)

// Reset layar
bool          isMenungguResetLayar = false;
unsigned long waktuSelesaiPompa    = 0;

// Telemetry
unsigned long lastTelemetryPublish = 0;
String        currentStatus        = "SIAP";

// State tombol (debounce edge detection)
bool lastDosisTambahState = HIGH;
bool lastDosisKurangState = HIGH;
bool lastTriggerState     = HIGH;

// ============================================================
//  PROTOTYPE FUNGSI
// ============================================================
void updateLayarOLED(String statusTeks);
void kirimDataBLE();
void selesaiPompa(float volumeDisemprotkan);

// ============================================================
//  BLE CALLBACKS
// ============================================================
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) {
    deviceConnected = true;
    Serial.println("[BLE] Smartphone Terhubung!");
  }
  void onDisconnect(BLEServer* server) {
    deviceConnected = false;
    Serial.println("[BLE] Smartphone Terputus!");
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) {
    String rxValue = String(characteristic->getValue().c_str());
    if (rxValue.length() == 0) return;

    Serial.print("[BLE RX] Diterima: ");
    Serial.println(rxValue);

    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, rxValue);
    if (error) {
      Serial.print("[JSON] Gagal parse: ");
      Serial.println(error.f_str());
      return;
    }

    // --- Perintah 1: Set Dosis (angka bebas dari apps / rekomendasi AI) ---
    if (doc.containsKey("set_dosis")) {
      float val = doc["set_dosis"];
      if (val > 0 && !isPompaRunning) {
        dosisMl     = val;
        durasiPompa = (dosisMl / 5.0) * waktuPer5Ml;
        preferences.putFloat("dosis_ml", dosisMl);
        Serial.printf("[ACTION] Dosis diatur ke: %.1f mL\n", dosisMl);
        updateLayarOLED("DOSIS BARU");
        kirimDataBLE();
        delay(1000);
        updateLayarOLED("SIAP");
      }
    }
    // --- Perintah 2: Reset Statistik ---
    else if (doc.containsKey("reset_stats")) {
      if (doc["reset_stats"] == true) {
        totalVolumeMl  = 0.0;
        totalSesiPompa = 0;
        preferences.putFloat("volume_ml", 0.0);
        preferences.putInt("sesi", 0);
        Serial.println("[ACTION] Statistik di-reset ke 0");
        updateLayarOLED("STAT RESET");
        kirimDataBLE();
        delay(1000);
        updateLayarOLED("SIAP");
      }
    }
    // --- Perintah 3: Trigger Pompa dari HP (timed — sesuai dosisMl) ---
    else if (doc.containsKey("trigger")) {
      if (doc["trigger"] == true && !isPompaRunning) {
        isPompaRunning  = true;
        pompaFromButton = false;  // timed mode dari BLE
        waktuMulaiPompa = millis();
        durasiPompa     = (dosisMl / 5.0) * waktuPer5Ml;
        digitalWrite(pinMosfet, HIGH);
        Serial.printf("[ACTION] BLE Trigger! Memompa %.1f mL selama %lu ms\n", dosisMl, durasiPompa);
        updateLayarOLED("MEMOMPA...");
        kirimDataBLE();
      }
    }
    // --- Perintah 4: Sinkronisasi Data ---
    else if (doc.containsKey("sync")) {
      Serial.println("[ACTION] Request Sync");
      kirimDataBLE();
    }
  }
};

// ============================================================
//  FUNGSI TAMPILAN OLED
// ============================================================
void updateLayarOLED(String statusTeks) {
  currentStatus = statusTeks;
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // --- Baris 1: Status & koneksi BLE ---
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print(statusTeks);
  display.setCursor(86, 0);
  display.print(deviceConnected ? "BLE:ON" : "BLE:--");

  // --- Baris 2: Nilai dosis besar di tengah ---
  display.setTextSize(3);
  display.setCursor(0, 22);
  if (dosisMl == (int)dosisMl) {
    display.printf("%d mL", (int)dosisMl);
  } else {
    display.printf("%.1f mL", dosisMl);
  }

  // --- Baris 3: Statistik bawah ---
  display.setTextSize(1);
  display.setCursor(0, 54);
  display.printf("Vol:%.0fmL | Sesi:%d", totalVolumeMl, totalSesiPompa);

  display.display();
}

// ============================================================
//  FUNGSI KIRIM TELEMETRY VIA BLE NOTIFY
// ============================================================
void kirimDataBLE() {
  if (!deviceConnected || pTxCharacteristic == NULL) return;

  float rataRata = (totalSesiPompa > 0) ? (totalVolumeMl / totalSesiPompa) : 0.0;

  StaticJsonDocument<256> doc;
  doc["dosis_ml"]    = dosisMl;
  doc["isPompaOn"]   = isPompaRunning;
  doc["totalVolume"] = totalVolumeMl;
  doc["totalSesi"]   = totalSesiPompa;
  doc["rataRata"]    = rataRata;
  doc["status"]      = currentStatus;

  char buffer[256];
  size_t len = serializeJson(doc, buffer);

  pTxCharacteristic->setValue((uint8_t*)buffer, len);
  pTxCharacteristic->notify();
  Serial.print("[BLE TX] ");
  Serial.println(buffer);
}

// ============================================================
//  FUNGSI SELESAI POMPA — catat statistik
// ============================================================
void selesaiPompa(float volumeDisemprotkan) {
  isPompaRunning  = false;
  pompaFromButton = false;
  digitalWrite(pinMosfet, LOW);

  totalVolumeMl  += volumeDisemprotkan;
  totalSesiPompa += 1;

  preferences.putFloat("volume_ml", totalVolumeMl);
  preferences.putInt("sesi", totalSesiPompa);

  Serial.printf("[SELESAI] +%.1f mL | Total: %.1f mL | Sesi: %d\n",
                volumeDisemprotkan, totalVolumeMl, totalSesiPompa);

  updateLayarOLED("SELESAI");
  kirimDataBLE();
  isMenungguResetLayar = true;
  waktuSelesaiPompa    = millis();
}

// ============================================================
//  SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== FETCORE AI — ESP32 BLE FIRMWARE v2.0 ===");

  // --- Flash Storage ---
  preferences.begin("fetcore", false);
  dosisMl        = preferences.getFloat("dosis_ml", 5.0);
  totalVolumeMl  = preferences.getFloat("volume_ml", 0.0);
  totalSesiPompa = preferences.getInt("sesi", 0);
  durasiPompa    = (dosisMl / 5.0) * waktuPer5Ml;

  // --- OLED ---
  Wire.begin(pinSDA, pinSCL);
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println(F("[ERROR] OLED SSD1306 tidak terdeteksi!"));
  } else {
    // Splash Screen: FetCore AI
    display.clearDisplay();

    display.setTextSize(2);
    display.setTextColor(WHITE);
    display.setCursor(10, 8);
    display.println("FetCore");

    display.setTextSize(2);
    display.setCursor(42, 30);
    display.println("AI");

    display.setTextSize(1);
    display.setCursor(18, 54);
    display.println("Smart Fertigation");

    display.display();
    delay(2000);  // tampilkan splash 2 detik
  }

  // --- Pin Hardware ---
  pinMode(pinMosfet,         OUTPUT);
  digitalWrite(pinMosfet,    LOW);

  pinMode(pinBtnDosisKurang, INPUT_PULLUP);
  pinMode(pinBtnDosisTambah, INPUT_PULLUP);
  pinMode(pinBtnTrigger,     INPUT_PULLUP);

  // --- BLE Init ---
  Serial.println("[BLE] Memulai BLE Server...");
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  // TX — ESP32 -> HP (NOTIFY)
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // RX — HP -> ESP32 (WRITE)
  BLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
                                           CHARACTERISTIC_UUID_RX,
                                           BLECharacteristic::PROPERTY_WRITE
                                         );
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  pService->start();
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Siap! Device: " DEVICE_NAME);
  updateLayarOLED("SIAP");
}

// ============================================================
//  LOOP
// ============================================================
void loop() {

  // -- 1. BLE Auto-Reconnect -------------------------------------------
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Re-advertising...");
    oldDeviceConnected = deviceConnected;
    updateLayarOLED(currentStatus);
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("[BLE] Smartphone terkoneksi!");
    updateLayarOLED(currentStatus);
    kirimDataBLE();
  }

  // -- 2. Telemetry periodik setiap 2 detik ----------------------------
  if (millis() - lastTelemetryPublish >= 2000) {
    lastTelemetryPublish = millis();
    if (deviceConnected) kirimDataBLE();
  }

  // -- 3. Tombol D17 -> Tambah Dosis (+5 mL, klik) --------------------
  bool readingTambah = digitalRead(pinBtnDosisTambah);
  if (readingTambah == LOW && lastDosisTambahState == HIGH) {
    delay(50);  // debounce
    if (digitalRead(pinBtnDosisTambah) == LOW && !isPompaRunning) {
      dosisMl += stepDosisMl;
      if (dosisMl > maxDosisMl) dosisMl = stepDosisMl;  // wrap ke minimum
      durasiPompa = (dosisMl / 5.0) * waktuPer5Ml;
      preferences.putFloat("dosis_ml", dosisMl);
      updateLayarOLED("+5 mL");
      kirimDataBLE();
      Serial.printf("[BTN D17] Dosis +5 -> %.1f mL\n", dosisMl);
    }
  }
  lastDosisTambahState = readingTambah;

  // -- 4. Tombol D16 -> Kurangi Dosis (-5 mL, klik) -------------------
  bool readingKurang = digitalRead(pinBtnDosisKurang);
  if (readingKurang == LOW && lastDosisKurangState == HIGH) {
    delay(50);  // debounce
    if (digitalRead(pinBtnDosisKurang) == LOW && !isPompaRunning) {
      dosisMl -= stepDosisMl;
      if (dosisMl < stepDosisMl) dosisMl = stepDosisMl;  // batas minimum 5 mL
      durasiPompa = (dosisMl / 5.0) * waktuPer5Ml;
      preferences.putFloat("dosis_ml", dosisMl);
      updateLayarOLED("-5 mL");
      kirimDataBLE();
      Serial.printf("[BTN D16] Dosis -5 -> %.1f mL\n", dosisMl);
    }
  }
  lastDosisKurangState = readingKurang;

  // -- 5. Tombol Trigger Pompa (TAHAN = nyala, LEPAS = mati) ----------
  bool readingTrigger = digitalRead(pinBtnTrigger);

  // Tombol baru ditekan (edge: HIGH -> LOW)
  if (readingTrigger == LOW && lastTriggerState == HIGH) {
    delay(50);  // debounce
    if (digitalRead(pinBtnTrigger) == LOW && !isPompaRunning) {
      isPompaRunning  = true;
      pompaFromButton = true;  // mode HOLD
      waktuMulaiPompa = millis();
      digitalWrite(pinMosfet, HIGH);
      updateLayarOLED("MEMOMPA...");
      kirimDataBLE();
      Serial.println("[BTN TRIGGER] Pompa ON (hold mode)");
    }
  }

  // Tombol dilepas saat pompa hold aktif (edge: LOW -> HIGH)
  if (readingTrigger == HIGH && lastTriggerState == LOW && isPompaRunning && pompaFromButton) {
    unsigned long durHold   = millis() - waktuMulaiPompa;
    float         volActual = (durHold / (float)waktuPer5Ml) * 5.0;
    Serial.printf("[BTN TRIGGER] Pompa OFF - hold %lu ms -> %.2f mL\n", durHold, volActual);
    selesaiPompa(volActual);
  }
  lastTriggerState = readingTrigger;

  // -- 6. Pompa BLE timed -- matikan setelah durasi selesai ------------
  if (isPompaRunning && !pompaFromButton) {
    if (millis() - waktuMulaiPompa >= durasiPompa) {
      Serial.printf("[BLE TRIGGER] Durasi %lu ms selesai -> %.1f mL\n", durasiPompa, dosisMl);
      selesaiPompa(dosisMl);
    }
  }

  // -- 7. Reset teks layar -> SIAP setelah 2 detik selesai ------------
  if (isMenungguResetLayar && (millis() - waktuSelesaiPompa >= 2000)) {
    updateLayarOLED("SIAP");
    isMenungguResetLayar = false;
  }
}