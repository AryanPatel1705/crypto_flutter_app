import 'package:crypto_flutter_app/screen/auth_page.dart';
import 'package:crypto_flutter_app/screen/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screen/landing_screen.dart';
import 'screen/settings_screen.dart';
import 'package:provider/provider.dart';
import 'provider/settingsprovider.dart';
import 'widgets/crypto_matrix_animation.dart'; // Import the animation widget
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Trading App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Track initialization status
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = "";

  // Initialize Firebase
  void initializeFlutterFire() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: "GOOGLE_API_KEY = dotenv.env['GOOGLE_API_KEY'] ?? '';",
            authDomain: "crypto-trading-62397.firebaseapp.com",
            databaseURL: "https://crypto-trading-62397-default-rtdb.asia-southeast1.firebasedatabase.app",
            projectId: "crypto-trading-62397",
            storageBucket: "crypto-trading-62397.firebasestorage.app",
            messagingSenderId: "171197138817",
            appId: "1:171197138817:web:208b4af0f1e825b6cc4a80",
            measurementId: "G-G60J8ZBPY1",
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print("Firebase initialization error: $e");
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Show error UI if initialization failed
    if (_error) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 20),
                Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'There was an error initializing the app. Please try again later.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    initializeFlutterFire();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show a loading indicator until initialization is complete
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: CryptoMatrixAnimation(
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Once initialized, show the main app content
    return MaterialApp(
      title: 'Crypto Trading App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/landing',
      onGenerateRoute: (settings) {
        // Routes that need to pass arguments
        switch (settings.name) {
          case '/landing':
            return MaterialPageRoute(builder: (_) => LandingScreen());
          case '/auth':
            return MaterialPageRoute(builder: (_) => AuthPage());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfileScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => SettingsScreen());
          default:
            // Handle unknown routes - fallback to landing screen
            return MaterialPageRoute(builder: (_) => LandingScreen());
        }
      },
    );
  }
}
