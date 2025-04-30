import 'package:crypto_flutter_app/screen/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  // Settings Variables
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  bool _isBiometricLoginEnabled = false;
  double _cryptoUpdateFrequency = 10; // Default 10 seconds
  String _selectedCurrency = 'USD';

  // Preferences
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();

    // Background Animation Setup
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutQuart,
      ),
    );

    // Load saved preferences
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = _prefs.getBool('darkMode') ?? false;
      _isNotificationsEnabled = _prefs.getBool('notifications') ?? true;
      _isBiometricLoginEnabled = _prefs.getBool('biometricLogin') ?? false;
      _cryptoUpdateFrequency = _prefs.getDouble('updateFrequency') ?? 10;
      _selectedCurrency = _prefs.getString('currency') ?? 'USD';
    });
  }

  void _savePreference(String key, dynamic value) {
    if (value is bool) {
      _prefs.setBool(key, value);
    } else if (value is double) {
      _prefs.setDouble(key, value);
    } else if (value is String) {
      _prefs.setString(key, value);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    Color.fromARGB(255, 72, 0, 255), 
                    Color.fromARGB(255, 3, 161, 161), 
                    _backgroundAnimation.value
                  )!,
                  Color.lerp(
                    Color.fromARGB(255, 3, 161, 161), 
                    Color.fromARGB(255, 252, 235, 3), 
                    _backgroundAnimation.value
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Theme Settings
                  _buildSettingsSection(
                    title: 'Appearance',
                    children: [
                      _buildSwitchTile(
                        title: 'Dark Mode',
                        subtitle: 'Switch between light and dark themes',
                        value: _isDarkMode,
                        onChanged: (bool value) {
                          setState(() {
                            _isDarkMode = value;
                            _savePreference('darkMode', value);
                            // TODO: Implement theme switching logic
                          });
                        },
                      ),
                    ],
                  ),

                  // Notification Settings
                  _buildSettingsSection(
                    title: 'Notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Enable Notifications',
                        subtitle: 'Receive price alerts and updates',
                        value: _isNotificationsEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _isNotificationsEnabled = value;
                            _savePreference('notifications', value);
                          });
                        },
                      ),
                    ],
                  ),

                  // Security Settings
                  _buildSettingsSection(
                    title: 'Security',
                    children: [
                      _buildSwitchTile(
                        title: 'Biometric Login',
                        subtitle: 'Use fingerprint or face recognition',
                        value: _isBiometricLoginEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _isBiometricLoginEnabled = value;
                            _savePreference('biometricLogin', value);
                          });
                        },
                      ),
                    ],
                  ),

                  // Crypto Update Frequency
                  _buildSettingsSection(
                    title: 'Crypto Data',
                    children: [
                      _buildSliderTile(
                        title: 'Update Frequency',
                        subtitle: 'How often to refresh crypto prices',
                        value: _cryptoUpdateFrequency,
                        min: 5,
                        max: 60,
                        divisions: 11,
                        onChanged: (double value) {
                          setState(() {
                            _cryptoUpdateFrequency = value;
                            _savePreference('updateFrequency', value);
                          });
                        },
                      ),
                      _buildDropdownTile(
                        title: 'Currency',
                        subtitle: 'Select display currency',
                        value: _selectedCurrency,
                        items: ['USD', 'EUR', 'GBP', 'BTC', 'ETH'],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedCurrency = value;
                              _savePreference('currency', value);
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Account Management
                  _buildSettingsSection(
                    title: 'Account',
                    children: [
                      _buildActionTile(
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        icon: Icons.logout,
                        onTap: () {
                          _showLogoutConfirmation();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Close the dialog first
                Navigator.pop(context);
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
                
                // Perform logout
                await FirebaseAuth.instance.signOut();
                
                // Close loading indicator
                Navigator.pop(context);
                
                // Navigate to landing screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LandingScreen()),
                  (route) => false, // This removes all previous routes
                );
                
                // Alternative navigation if you're not using named routes:
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (context) => LandingScreen()),
                //   (route) => false,
                // );
              } catch (e) {
                // Handle any errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // Reusable Widgets
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.black54),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        '$subtitle (${value.round()} seconds)',
        style: TextStyle(color: Colors.black54),
      ),
      trailing: SizedBox(
        width: 100,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
          activeColor: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.black54),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.black54),
      ),
      trailing: Icon(icon, color: Colors.deepPurple),
      onTap: onTap,
    );
  }
}