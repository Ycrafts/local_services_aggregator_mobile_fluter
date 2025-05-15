import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'config/app_config.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage with platform-specific options
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  runApp(MyApp(secureStorage: secureStorage));
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage secureStorage;
  
  const MyApp({Key? key, required this.secureStorage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(secureStorage: secureStorage),
        ),
        Provider<ApiService>(
          create: (_) => ApiService(
            baseUrl: AppConfig.baseUrl,
            secureStorage: secureStorage,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Local Services Aggregator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = context.read<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();
      
      if (!mounted) return;

      if (isAuthenticated) {
        // User is authenticated, navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // User is not authenticated, navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (!mounted) return;
      // In case of error, navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
