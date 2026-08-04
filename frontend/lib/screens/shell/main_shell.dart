import 'package:flutter/material.dart';
import 'package:urbancare_frontend/core/services/geofence_service.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/screens/account/account_screen.dart';
import 'package:urbancare_frontend/screens/complaint/create_complaint_screen.dart';
import 'package:urbancare_frontend/screens/complaint/my_complaints_screen.dart';
import 'package:urbancare_frontend/screens/home/home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.authRepository,
    required this.complaintRepository,
    required this.geofenceService,
    required this.onSignOut,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.notificationsEnabled,
    required this.onNotificationEnabledChanged,
  });

  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;
  final VoidCallback onSignOut;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationEnabledChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  Future<void> _goToCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateComplaintScreen(
          complaintRepository: widget.complaintRepository,
        ),
      ),
    );
    if (created == true) {
      // Switch to My Reports tab so user can see their new complaint
      setState(() => _currentIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        authRepository: widget.authRepository,
        complaintRepository: widget.complaintRepository,
        geofenceService: widget.geofenceService,
        onCreateComplaint: _goToCreate,
      ),
      MyComplaintsScreen(
        complaintRepository: widget.complaintRepository,
      ),
      AccountScreen(
        authRepository: widget.authRepository,
        onSignOut: widget.onSignOut,
        currentThemeMode: widget.currentThemeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        notificationsEnabled: widget.notificationsEnabled,
        onNotificationEnabledChanged: widget.onNotificationEnabledChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _goToCreate,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'My Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
