import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/crypto_matrix_animation.dart';

class AuthPage extends StatefulWidget {
  final String? username;
  const AuthPage({super.key, this.username});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool _isSigningUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _isPasswordVisible = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  late AnimationController _formAnimationController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  @override
  void initState() {
    super.initState();

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formAnimationController, curve: Curves.easeInOut),
    );

    _formSlideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _formAnimationController, curve: Curves.easeInOut),
    );

    _formAnimationController.forward();
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    if (_isSigningUp) {
      _formAnimationController.reverse().then((_) {
        setState(() {
          _isSigningUp = false;
        });
        _formAnimationController.forward();
      });
    } else {
      _formAnimationController.reverse().then((_) {
        setState(() {
          _isSigningUp = true;
        });
        _formAnimationController.forward();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String username = '';
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        username = userData['username'] ?? '';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LandingScreen(username: username)),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(username);

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LandingScreen(username: username)),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use by another account.';
          break;
        default:
          errorMessage = 'Signup failed: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      final User user = userCredential.user!;

      final String displayName = user.displayName ?? googleUser.email.split('@')[0];
      final String email = user.email ?? '';

      if (isNewUser) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': displayName,
          'email': email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'signInMethod': 'google',
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LandingScreen(username: displayName)),
      );
    } catch (e) {
      print('Error during Google sign in: $e');

      if (e.toString().contains('People API has not been used')) {
        _showErrorSnackBar('Please try again in a few minutes after enabling the People API in your Google Cloud Console.');
      } else {
        _showErrorSnackBar('Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (_isSigningUp) {
      if (value == null || value.isEmpty) {
        return 'Please enter a username';
      }
      if (value.length < 3) {
        return 'Username must be at least 3 characters long';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Making AppBar transparent and improving text styling
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Remove white background
        elevation: 0, // Remove shadow
        iconTheme: IconThemeData(color: Colors.white), // Set back button color to white
        title: Text(
          'Authentication',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      extendBodyBehindAppBar: true, // Keep this to extend content behind the AppBar
      body: Stack(
        children: [
          // Use CryptoMatrixAnimation as background
          const CryptoMatrixAnimation(duration: Duration(seconds: 9999)),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
                child: FadeTransition(
                  opacity: _formFadeAnimation,
                  child: SlideTransition(
                    position: _formSlideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isSigningUp ? 'Create Account' : 'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black54,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          if (_isSigningUp)
                            TextFormField(
                              controller: _usernameController,
                              validator: _validateUsername,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person, color: Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.15),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
                          SizedBox(height: _isSigningUp ? 16 : 0),

                          TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: Colors.white),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_isSigningUp) {
                                      _signUp();
                                    } else {
                                      _login();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              backgroundColor: Colors.greenAccent.shade400,
                              foregroundColor: Colors.black87,
                              disabledBackgroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.black87)
                                : Text(
                                    _isSigningUp ? 'Sign Up' : 'Login',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ).animate().scale(duration: 300.ms).shake(delay: 300.ms),

                          SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.5), thickness: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.5), thickness: 1),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: FaIcon(FontAwesomeIcons.google, color: Colors.red),
                            label: Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(begin: Offset(0.8, 0.8), duration: 500.ms),

                          SizedBox(height: 24),

                          TextButton(
                            onPressed: _isLoading ? null : _toggleForm,
                            child: Text(
                              _isSigningUp ? 'Already have an account? Login' : 'Don\'t have an account? Sign up',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
