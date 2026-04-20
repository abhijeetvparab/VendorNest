import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/vendor_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: const VendorNest(),
    ),
  );
}

class VendorNest extends StatelessWidget {
  const VendorNest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendorNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      routes: {
        '/splash':   (_) => const _SplashScreen(),
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot':   (_) => const ForgotPasswordScreen(),
        '/home':     (_) => const MainShell(),
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;
    if (auth.user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('VendorNest',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
              SizedBox(height: 8),
              Text('Management Platform',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
