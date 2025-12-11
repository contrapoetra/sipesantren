import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'firebase_services.dart';
import 'package:sipesantren/core/providers/user_provider.dart';
import 'package:sipesantren/core/providers/weight_config_provider.dart'; // New import

import 'features/auth/presentation/login_page.dart';
import 'package:sipesantren/features/dashboard/presentation/dashboard_page.dart'; // New import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create a ProviderContainer for initial setup
  final container = ProviderContainer();
  // Ensure default weights are initialized before the app starts
  await container.read(initializeWeightConfigProvider.future); // Await the future directly

  await initializeDateFormatting('id_ID', null);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> { // Changed to ConsumerState
  // Removed _isLoading and _isLoggedIn local states

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final auth = ref.read(firebaseServicesProvider);
    final session = await auth.getUserSession();
    if (session['id'] != null) {
      final roleToUse = session['role'] ?? 'Ustadz';
      ref.read(userProvider.notifier).login(
            session['id']!,
            roleToUse,
            session['name'] ?? 'User',
            requestedRole: session['requested_role'],
            requestStatus: session['request_status'],
          );
    }
    ref.read(userProvider.notifier).sessionCheckCompleted(); // Mark session check as complete
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider); // Watch userProvider

    if (userState.isLoadingSession) { // Use the new isLoadingSession flag
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'e-Penilaian Santri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: userState.isLoggedIn ? const DashboardPage() : const LoginPage(), // Navigate to DashboardPage
      debugShowCheckedModeBanner: false,
    );
  }
}