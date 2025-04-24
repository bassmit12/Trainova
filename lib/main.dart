import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/app_update_screen.dart';
import 'services/auth_service.dart';
import 'services/workout_session_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/update_notification_widget.dart';
import 'utils/app_colors.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: true,
  );

  // Initialize the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(supabase)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => WorkoutSessionService()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create:
              (_) => UpdateProvider(
                githubOwner: AppConfig.githubOwner,
                githubRepo: AppConfig.githubRepo,
              ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Trainova',
            theme: themeProvider.theme,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/welcome': (context) => const WelcomeScreen(),
              '/main': (context) => const MainScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // First check if user is logged in
    if (!authService.isLoggedIn) {
      return const LoginScreen();
    }

    // If logged in but profile not complete, show welcome screen
    if (!authService.isProfileComplete) {
      return const WelcomeScreen();
    }

    // Otherwise show the main app screen
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Check for updates when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    await updateProvider.checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
