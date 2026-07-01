import 'package:flutter/material.dart';
import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/core/config/env.dart';
import 'package:urbancare_frontend/core/services/auth_service.dart';
import 'package:urbancare_frontend/core/services/complaint_service.dart';
import 'package:urbancare_frontend/core/services/firebase_service.dart';
import 'package:urbancare_frontend/core/services/geofence_service.dart';
import 'package:urbancare_frontend/core/services/location_service.dart';
import 'package:urbancare_frontend/core/utils/token_storage.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/screens/auth/login_screen.dart';
import 'package:urbancare_frontend/screens/home/home_screen.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeFirebaseInit();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: Env.apiBaseUrl, tokenStorage: tokenStorage);

  final authService = AuthService(apiClient);
  final complaintService = ComplaintService(apiClient);
  final firebaseService = FirebaseService();
  final locationService = LocationService();

  final authRepository = AuthRepository(
    authService: authService,
    tokenStorage: tokenStorage,
  );

  final complaintRepository = ComplaintRepository(
    complaintService: complaintService,
    firebaseService: firebaseService,
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
      authRepository: authRepository,
      complaintRepository: complaintRepository,
      geofenceService: geofenceService,
    ),
  );
}

Future<void> _safeFirebaseInit() async {
  try {
    await FirebaseService.initialize();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class UrbanCareApp extends StatelessWidget {
  const UrbanCareApp({
    super.key,
    required this.authRepository,
    required this.complaintRepository,
    required this.geofenceService,
  });

  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanCare',
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        authRepository: authRepository,
        complaintRepository: complaintRepository,
        geofenceService: geofenceService,
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
  });

  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;

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
          return HomeScreen(
            authRepository: widget.authRepository,
            complaintRepository: widget.complaintRepository,
            geofenceService: widget.geofenceService,
            onSignOut: _refreshSession,
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
