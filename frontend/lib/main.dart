import 'package:flutter/material.dart';
import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/core/config/env.dart';
import 'package:urbancare_frontend/core/services/auth_service.dart';
import 'package:urbancare_frontend/core/services/complaint_service.dart';
import 'package:urbancare_frontend/core/services/geofence_service.dart';
import 'package:urbancare_frontend/core/services/location_service.dart';
import 'package:urbancare_frontend/core/utils/token_storage.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/screens/auth/login_screen.dart';
import 'package:urbancare_frontend/screens/shell/main_shell.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: Env.apiBaseUrl, tokenStorage: tokenStorage);

  final authService = AuthService(apiClient);
  final complaintService = ComplaintService(apiClient);
  final locationService = LocationService();

  final authRepository = AuthRepository(
    authService: authService,
    tokenStorage: tokenStorage,
  );

  final complaintRepository = ComplaintRepository(
    complaintService: complaintService,
    locationService: locationService,
    authRepository: authRepository,
  );

  final geofenceService = AppGeofenceService(
    complaintService: complaintService,
    locationService: locationService,
  );

  try {
    await geofenceService.initialize();
  } catch (error) {
    debugPrint('Geofence initialization skipped: $error');
  }

  runApp(
    UrbanCareApp(
      tokenStorage: tokenStorage,
      authRepository: authRepository,
      complaintRepository: complaintRepository,
      geofenceService: geofenceService,
    ),
  );
}

class UrbanCareApp extends StatefulWidget {
  const UrbanCareApp({
    super.key,
    required this.tokenStorage,
    required this.authRepository,
    required this.complaintRepository,
    required this.geofenceService,
  });

  final TokenStorage tokenStorage;
  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;

  @override
  State<UrbanCareApp> createState() => _UrbanCareAppState();
}

class _UrbanCareAppState extends State<UrbanCareApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadNotificationPreference();
  }

  Future<void> _loadThemeMode() async {
    final stored = await widget.tokenStorage.getThemeMode();
    final mode = stored == 'light' ? ThemeMode.light : ThemeMode.dark;

    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _onThemeModeChanged(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    setState(() => _themeMode = mode);
    await widget.tokenStorage.saveThemeMode(
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> _loadNotificationPreference() async {
    final stored = await widget.tokenStorage.getNotificationEnabled();
    final enabled = stored ?? true;

    widget.geofenceService.setNotificationsEnabled(enabled);

    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _onNotificationEnabledChanged(bool enabled) async {
    if (_notificationsEnabled == enabled) {
      return;
    }

    widget.geofenceService.setNotificationsEnabled(enabled);
    setState(() => _notificationsEnabled = enabled);
    await widget.tokenStorage.saveNotificationEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanCare',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        authRepository: widget.authRepository,
        complaintRepository: widget.complaintRepository,
        geofenceService: widget.geofenceService,
        themeMode: _themeMode,
        onThemeModeChanged: _onThemeModeChanged,
        notificationsEnabled: _notificationsEnabled,
        onNotificationEnabledChanged: _onNotificationEnabledChanged,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.complaintRepository,
    required this.geofenceService,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.notificationsEnabled,
    required this.onNotificationEnabledChanged,
  });

  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationEnabledChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = widget.authRepository.hasValidSession();
  }

  @override
  void dispose() {
    widget.geofenceService.dispose();
    super.dispose();
  }

  void _refreshSession() {
    setState(() {
      _sessionFuture = widget.authRepository.hasValidSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snapshot.data ?? false;

        if (loggedIn) {
          return MainShell(
            authRepository: widget.authRepository,
            complaintRepository: widget.complaintRepository,
            geofenceService: widget.geofenceService,
            onSignOut: _refreshSession,
            currentThemeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            notificationsEnabled: widget.notificationsEnabled,
            onNotificationEnabledChanged: widget.onNotificationEnabledChanged,
          );
        }

        return LoginScreen(
          authRepository: widget.authRepository,
          onAuthSuccess: _refreshSession,
        );
      },
    );
  }
}
