import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/live_tab_content.dart';
import '../widgets/teams_tab_content.dart';
import '../widgets/calendar_tab_content.dart';

class NewHomeScreen extends ConsumerStatefulWidget {
  const NewHomeScreen({super.key});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends ConsumerState<NewHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(),
            // Tab bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Live'),
                  Tab(text: 'Equipos'),
                  Tab(text: 'Historial'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  LiveTabContent(),
                  TeamsTabContent(),
                  CalendarTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}