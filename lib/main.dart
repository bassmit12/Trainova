import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for platform optimizations
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'config/app_config.dart';
import 'config/secure_config.dart'; // New secure config
import 'services/config_service.dart';
import 'services/lazy_loading_manager.dart'; // New lazy loading manager
import 'services/cache_service.dart'; // New cache service
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/app_update_screen.dart';
import 'screens/ai_workout_chat_screen.dart';
import 'services/auth_service.dart';
import 'services/workout_session_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/update_notification_widget.dart';
import 'utils/app_colors.dart';
import 'utils/error_handler.dart'; // New error handler
import 'utils/loading_state_manager.dart'; // New loading manager
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/update_provider.dart';
import 'providers/workout_chat_provider.dart';

void main() async {
  // Optimize Flutter binding initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations early to avoid layout shifts
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize critical services only (cache and lazy loading)
  await _initializeCriticalServices();

  // Initialize Supabase (critical for authentication)
  await _initializeSupabase();

  // Initialize the app
  runApp(const MyApp());
}

/// Initialize only critical services needed for app startup
Future<void> _initializeCriticalServices() async {
  try {
    // Initialize cache service first
    await CacheService().initialize();
    
    // Initialize secure configuration with caching
    await SecureConfig.instance.initialize();
    
    // Setup lazy loading for non-critical services
    _setupLazyLoading();
    
  } catch (e) {
    print('Warning: Failed to initialize critical services: $e');
  }
}

/// Setup lazy loading for non-critical services
void _setupLazyLoading() {
  final lazyLoader = LazyLoadingManager();
  
  // Register non-critical services for lazy loading
  lazyLoader.registerService('config_service', () async {
    final configService = ConfigService();
    await configService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Warning: Config service initialization timed out');
      },
    );
  });
  
  lazyLoader.registerService('workout_session_service', () async {
    // This will be initialized when actually needed
    return;
  });
  
  lazyLoader.registerService('cache_cleanup', () async {
    // Clean up expired cache entries
    await CacheService().clearExpired();
  });
}

/// Initialize Supabase with optimizations
Future<void> _initializeSupabase() async {
  print('Initializing Supabase...');
  print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
  print(
    'Supabase Anon Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...',
  );

  try {
    // Check cache for previous successful initialization
    final cache = CacheService();
    final cachedSuccess = cache.get<bool>('cache_supabase_init_success');
    
    if (cachedSuccess == true) {
      // Use cached credentials if available
      print('Using cached Supabase configuration');
    }

    // Initialize Supabase with timeout and retry logic
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: false, // Disable debug in production for better performance
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Supabase initialization timed out');
      },
    );

    // Cache successful initialization
    await cache.store('cache_supabase_init_success', true, duration: const Duration(hours: 24));
    print('Supabase initialized successfully');
    
  } catch (e) {
    // Handle Supabase initialization error
    ErrorHandler.instance.handleError(
      AppError.database(
        'Failed to connect to database',
        technicalDetails: e.toString(),
        userAction:
            'Please check your internet connection and try restarting the app.',
      ),
    );
    print('Supabase initialization failed: $e');
  }
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
        ChangeNotifierProvider(create: (_) => ConfigService()),
        ChangeNotifierProvider(
          create: (_) => LoadingStateManager(),
        ), // New loading manager
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
        ChangeNotifierProvider(create: (_) => WorkoutChatProvider()),
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
              '/ai_workout_creator': (context) => const AIWorkoutChatScreen(),
            },
            debugShowCheckedModeBanner: false,
            // Global error handling
            builder: (context, widget) {
              return widget ?? const SizedBox.shrink();
            },
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
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show loading while checking auth state
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with LoadingStateMixin {
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
    // Initialize non-critical services after UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAfterUI();
    });
  }

  Future<void> _initializeAfterUI() async {
    // Start lazy loading of non-critical services
    LazyLoadingManager().initializeNonCriticalServices();
    
    // Check for updates (non-blocking)
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      await executeWithLoading(
        'update_check',
        () async {
          final updateProvider = Provider.of<UpdateProvider>(
            context,
            listen: false,
          );
          await updateProvider.checkForUpdate();
        },
        loadingMessage: 'Checking for updates...',
        onError: (error) {
          context.handleError(
            AppError.network(
              'Failed to check for updates',
              technicalDetails: error,
              userAction:
                  'This won\'t affect app functionality. Updates will be checked again later.',
            ),
            showToUser: false, // Don't show update check errors to user
          );
        },
      );
    } catch (e) {
      // Error already handled in executeWithLoading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingStateManager>(
      builder: (context, loadingManager, child) {
        return LoadingOverlay(
          loadingState: loadingManager.getLoadingState('update_check'),
          child: Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        );
      },
    );
  }
}
