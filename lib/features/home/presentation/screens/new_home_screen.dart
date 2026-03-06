import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/live_tab_content.dart';
import '../widgets/teams_tab_content.dart';
import '../widgets/calendar_tab_content.dart';

/// Pantalla principal con diseño Figma
class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen>
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
            // Header personalizado
            const CustomAppBar(),

            // Tabs horizontales
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Live'),
                  Tab(text: 'Equipos'),
                  Tab(text: 'Calendario'),
                ],
              ),
            ),

            // Contenido de tabs
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