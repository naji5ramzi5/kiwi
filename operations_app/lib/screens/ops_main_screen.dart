import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'modules/overview_screen.dart';
import 'modules/live_monitor_screen.dart';
import 'modules/employees_screen.dart';
import 'modules/delivered_screen.dart';
import 'modules/notifications_screen.dart';

class OpsMainScreen extends StatefulWidget {
  final AuthState auth;
  const OpsMainScreen({super.key, required this.auth});

  @override
  State<OpsMainScreen> createState() => _OpsMainScreenState();
}

class _OpsMainScreenState extends State<OpsMainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      OverviewScreen(auth: widget.auth),
      const LiveMonitorScreen(),
      EmployeesScreen(auth: widget.auth),
      const DeliveredScreen(),
      const NotificationsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'اللوحة',
          ),
          const NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'المباشر',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'المندوبون',
          ),
          const NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: 'الطلبات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'الإشعارات',
          ),
        ],
      ),
    );
  }
}