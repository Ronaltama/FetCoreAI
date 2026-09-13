#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Preferences.h>

// --- KONFIGURASI PIN HARDWARE ---
const int pinSDA      = 21; 
const int pinSCL      = 22;
const int pinMotorDC  = 26;
const int pinBtnGramasiTambah = 32;
const int pinBtnGramasiKurang = 25;
const int pinBtnTrigger = 33; 

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
Preferences preferences;

// --- KONFIGURASI BLE (Nordic UART Service - NUS) ---
// UUID harus persis sama dengan yang ada di Flutter BleService
#define DEVICE_NAME            "FERTICORE-01"
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // HP Kirim Command ke ESP32
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" // ESP32 Kirim Telemetry ke HP

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// --- VARIABEL LOGIKA & STATISTIK ---
float gramasi = 5.0;
float maxGramasi = 200.0;
int waktuPer5Gram = 3000;
unsigned long durasiPupuk = 3000;

float totalVolumePupuk = 0.0;
int totalSesiPemupukan = 0;

bool isMotorRunning = false;
unsigned long waktuMulaiMotor = 0;
bool isMenungguResetLayar = false;
unsigned long waktuSelesaiMotor = 0;

unsigned long lastTelemetryPublish = 0;
String currentStatus = "SIAP";

bool lastGramasiTambahState = HIGH; 
bool lastGramasiKurangState = HIGH;
bool lastTriggerState = HIGH;

// --- PROTOTYPE FUNGSI ---
void updateLayarOLED(String statusTeks);
void kirimDataBLE();

// --- BLE CALLBACKS ---
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* server) {
      deviceConnected = true;
      Serial.println("[BLE] Smartphone Terhubung!");
    }

    void onDisconnect(BLEServer* server) {
      deviceConnected = false;
      Serial.println("[BLE] Smartphone Terputus!");
    }
};

class RxCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) {
      String rxValue = characteristic->getValue();
      if (rxValue.length() > 0) {
        Serial.print("[BLE RX] Diterima: ");
        Serial.println(rxValue);

        StaticJsonDocument<256> doc;
        DeserializationError error = deserializeJson(doc, rxValue);
        if (error) {
          Serial.print("[JSON] Gagal parse: ");
          Serial.println(error.f_str());
          return;
        }

        // Perintah 1: Set Dosis (dari Rekomendasi AI atau Manual)
        if (doc.containsKey("set_dosis")) {
          float val = doc["set_dosis"];
          if (val > 0) {
            gramasi = val;
            durasiPupuk = (gramasi / 5.0) * waktuPer5Gram;
            preferences.putFloat("gramasi", gramasi);
            Serial.printf("[ACTION] Dosis diatur ke: %.2f g\n", gramasi);
            updateLayarOLED("DOSIS BARU");
            kirimDataBLE();
            delay(1000);
            updateLayarOLED("SIAP");
          }
        } 
        // Perintah 2: Reset Statistik
        else if (doc.containsKey("reset_stats")) {
          if (doc["reset_stats"] == true) {
            totalVolumePupuk = 0.0;
            totalSesiPemupukan = 0;
            preferences.putFloat("volume", 0.0);
            preferences.putInt("sesi", 0);
            Serial.println("[ACTION] Statistik di-reset ke 0");
            updateLayarOLED("STAT RESET");
            kirimDataBLE();
            delay(1000);
            updateLayarOLED("SIAP");
          }
        }
        // Perintah 3: Trigger Mulai Pemupukan dari HP
        else if (doc.containsKey("trigger")) {
          if (doc["trigger"] == true && !isMotorRunning) {
            isMotorRunning = true;
            waktuMulaiMotor = millis();
            digitalWrite(pinMotorDC, HIGH);
            Serial.printf("[ACTION] Remote Trigger dari HP! Memupuk %.1f g\n", gramasi);
            updateLayarOLED("MEMUPUK...");
            kirimDataBLE();
          }
        }
        // Perintah 4: Tare Timbangan (Nol-kan)
        else if (doc.containsKey("tare")) {
          if (doc["tare"] == true) {
            Serial.println("[ACTION] Tare Timbangan ke 0g");
            updateLayarOLED("TARE: 0g");
            kirimDataBLE();
            delay(800);
            updateLayarOLED("SIAP");
          }
        }
        // Perintah 5: Permintaan Sinkronisasi Data
        else if (doc.containsKey("sync")) {
          Serial.println("[ACTION] Request Telemetry Sync");
          kirimDataBLE();
        }
      }
    }
};

// --- FUNGSI TAMPILAN OLED ---
void updateLayarOLED(String statusTeks) {
  currentStatus = statusTeks;
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // Baris Status Atas
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print(statusTeks);

  // Status Koneksi BLE di pojok kanan atas
  display.setCursor(82, 0);
  display.print(deviceConnected ? "BLE:ON" : "BLE:--");

  // Nilai Gramasi di tengah
  display.setTextSize(3);
  display.setCursor(0, 24);
  if (gramasi == (int)gramasi) {
    display.printf("%d g", (int)gramasi);
  } else {
    display.printf("%.1f g", gramasi);
  }

  // Baris info bawah
  display.setTextSize(1);
  display.setCursor(0, 54);
  display.printf("Vol:%.0fg | Sesi:%d", totalVolumePupuk, totalSesiPemupukan);

  display.display();
}

// --- FUNGSI KIRIM TELEMETRY VIA BLE NOTIFY ---
void kirimDataBLE() {
  if (!deviceConnected || pTxCharacteristic == NULL) return;

  float rataRata = (totalSesiPemupukan > 0) ? (totalVolumePupuk / totalSesiPemupukan) : 0.0;
  
  StaticJsonDocument<256> doc;
  doc["gramasi"] = gramasi;
  doc["isMotorRunning"] = isMotorRunning;
  doc["totalVolume"] = totalVolumePupuk;
  doc["totalSesi"] = totalSesiPemupukan;
  doc["rataRata"] = rataRata;
  
  char buffer[256];
  size_t len = serializeJson(doc, buffer);
  
  pTxCharacteristic->setValue((uint8_t*)buffer, len);
  pTxCharacteristic->notify();
  Serial.print("[BLE TX] Notifikasi dikirim: ");
  Serial.println(buffer);
}

// --- SETUP ---
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== FERTICORE AI - ESP32 BLE CONTROLLER ===");

  // Inisialisasi Flash Storage (Preferences) agar data tidak hilang saat restart
  preferences.begin("ferticore", false);
  gramasi = preferences.getFloat("gramasi", 5.0);
  totalVolumePupuk = preferences.getFloat("volume", 0.0);
  totalSesiPemupukan = preferences.getInt("sesi", 0);

  // Inisialisasi I2C & OLED Display
  Wire.begin(pinSDA, pinSCL);
  if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println(F("[ERROR] SSD1306 OLED tidak terdeteksi!"));
    // Lanjutkan walau layar gagal agar BLE & Motor tetap dapat bekerja
  } else {
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(WHITE);
    display.setCursor(10, 15);
    display.println("FERTICORE");
    display.setCursor(50, 35);
    display.println("AI");
    display.setTextSize(1);
    display.setCursor(25, 55);
    display.println("BLE Precision");
    display.display();
  }
  
  // Konfigurasi Pin Hardware
  pinMode(pinMotorDC, OUTPUT);
  digitalWrite(pinMotorDC, LOW);
  
  pinMode(pinBtnGramasiTambah, INPUT_PULLUP);
  pinMode(pinBtnGramasiKurang, INPUT_PULLUP);
  pinMode(pinBtnTrigger, INPUT_PULLUP);

  durasiPupuk = (gramasi / 5.0) * waktuPer5Gram;

  // Inisialisasi BLE Device & Server
  Serial.println("[BLE] Memulai BLE Server...");
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Buat Nordic UART Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // TX Characteristic (ESP32 kirim ke HP - NOTIFY)
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // RX Characteristic (HP kirim ke ESP32 - WRITE)
  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
                                           CHARACTERISTIC_UUID_RX,
                                           BLECharacteristic::PROPERTY_WRITE
                                         );
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  // Jalankan BLE Service & Advertising
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Siap! Nama Perangkat: " DEVICE_NAME);
  delay(1500);
  updateLayarOLED("SIAP");
}

// --- LOOP ---
void loop() {
  // 1. Tangani Auto-Reconnecting BLE Advertising saat HP terputus
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // beri waktu bluetooth stack bersiap
    pServer->startAdvertising();
    Serial.println("[BLE] Smartphone terputus, mulai advertising ulang...");
    oldDeviceConnected = deviceConnected;
    updateLayarOLED(currentStatus);
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("[BLE] Smartphone terkoneksi!");
    updateLayarOLED(currentStatus);
    kirimDataBLE(); // Kirim data awal begitu terkoneksi
  }

  // 2. Publish Data Telemetry secara periodik (setiap 2 detik ke HP jika terkoneksi)
  if (millis() - lastTelemetryPublish >= 2000) {
    lastTelemetryPublish = millis();
    if (deviceConnected && !isMotorRunning) {
      kirimDataBLE();
    }
  }

  // 3. Logika Tombol Fisik Tambah Dosis (+5g)
  bool readingTambah = digitalRead(pinBtnGramasiTambah);
  if (readingTambah == LOW && lastGramasiTambahState == HIGH) {
    delay(50); // debounce
    if (digitalRead(pinBtnGramasiTambah) == LOW && !isMotorRunning) {
        gramasi += 5.0;
        if (gramasi > maxGramasi) gramasi = 5.0;
        durasiPupuk = (gramasi / 5.0) * waktuPer5Gram;
        preferences.putFloat("gramasi", gramasi);
        updateLayarOLED("+5g");
        kirimDataBLE();
        Serial.printf("[BUTTON] Dosis Tambah: %.1f g\n", gramasi);
    }
  }
  lastGramasiTambahState = readingTambah;

  // 4. Logika Tombol Fisik Kurang Dosis (-5g)
  bool readingKurang = digitalRead(pinBtnGramasiKurang);
  if (readingKurang == LOW && lastGramasiKurangState == HIGH) {
    delay(50); // debounce
    if (digitalRead(pinBtnGramasiKurang) == LOW && !isMotorRunning) {
        gramasi -= 5.0;
        if (gramasi < 5.0) gramasi = 5.0;
        durasiPupuk = (gramasi / 5.0) * waktuPer5Gram;
        preferences.putFloat("gramasi", gramasi);
        updateLayarOLED("-5g");
        kirimDataBLE();
        Serial.printf("[BUTTON] Dosis Kurang: %.1f g\n", gramasi);
    }
  }
  lastGramasiKurangState = readingKurang;

  // 5. Logika Tombol Fisik Trigger Penaburan
  bool readingTrigger = digitalRead(pinBtnTrigger);
  if (readingTrigger == LOW && lastTriggerState == HIGH) {
    delay(50); // debounce
    if (digitalRead(pinBtnTrigger) == LOW && !isMotorRunning) {
        isMotorRunning = true;
        waktuMulaiMotor = millis();
        digitalWrite(pinMotorDC, HIGH);
        updateLayarOLED("MEMUPUK...");
        kirimDataBLE();
        Serial.printf("[TRIGGER] Mulai memupuk %.1f g (Durasi: %lu ms)\n", gramasi, durasiPupuk);
    }
  }
  lastTriggerState = readingTrigger;

  // 6. Kontrol Durasi Motor Penabur
  if (isMotorRunning) {
    if (millis() - waktuMulaiMotor >= durasiPupuk) {
      isMotorRunning = false;
      digitalWrite(pinMotorDC, LOW);
      totalVolumePupuk += gramasi;
      totalSesiPemupukan += 1;
      
      // Simpan akumulasi terbaru ke memori flash
      preferences.putFloat("volume", totalVolumePupuk);
      preferences.putInt("sesi", totalSesiPemupukan);

      updateLayarOLED("SELESAI");
      kirimDataBLE();
      isMenungguResetLayar = true;
      waktuSelesaiMotor = millis();
      Serial.printf("[SELESAI] Total Vol: %.1f g, Total Sesi: %d\n", totalVolumePupuk, totalSesiPemupukan);
    }
  }

  // 7. Kembalikan Teks Layar ke 'SIAP' setelah selesai memupuk
  if (isMenungguResetLayar && (millis() - waktuSelesaiMotor >= 2000)) {
    updateLayarOLED("SIAP");
    isMenungguResetLayar = false;
  }
}