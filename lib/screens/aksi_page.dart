import 'package:flutter/material.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:ferticore_ai/widgets/rekomendasi_card_widget.dart';
import 'package:ferticore_ai/widgets/manual_dosis_card_widget.dart';

class AksiPage extends StatefulWidget {
  const AksiPage({super.key});

  @override
  State<AksiPage> createState() => _AksiPageState();
}

class _AksiPageState extends State<AksiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Custom TabBar inside the page body
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingMD),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  color: AppTheme.primaryBlue,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textGrey,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Rekomendasi AI'),
                  Tab(text: 'Manual'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: const RekomendasiCardWidget(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: const ManualDosisCardWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
