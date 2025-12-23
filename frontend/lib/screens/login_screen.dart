import 'package:bstock_app/widgets/ashreef_footer.dart';
import 'package:bstock_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (!result.success) {
          _showErrorSnackBar(result.errorMessage ?? 'Login failed. Please try again.');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    Color backgroundColor;
    IconData icon;
    
    // Determine color and icon based on error type
    if (message.contains('Invalid username or password')) {
      backgroundColor = Colors.red.shade700;
      icon = Icons.person_off;
    } else if (message.contains('Server took too long') || message.contains('timeout')) {
      backgroundColor = Colors.orange.shade700;
      icon = Icons.access_time;
    } else if (message.contains('Unable to connect') || message.contains('internet connection')) {
      backgroundColor = Colors.blue.shade700;
      icon = Icons.wifi_off;
    } else if (message.contains('Server error') || message.contains('contact support')) {
      backgroundColor = Colors.purple.shade700;
      icon = Icons.bug_report;
    } else {
      backgroundColor = Colors.red.shade700;
      icon = Icons.error;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final double screenHeight = mediaQuery.size.height;
    final double logoHeightFactor = isKeyboardVisible ? 0.12 : 0.22;
    final double dynamicLogoHeight =
        (screenHeight * logoHeightFactor).clamp(80.0, 180.0);
    final String logoAsset = isDark
        ? 'assets/brand/bstock_logo_dark_sm.png'
        : 'assets/brand/bstock_logo_light_sm.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Main content - scrollable form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0, // Extra padding for footer space
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      height: dynamicLogoHeight,
                      child: Image.asset(
                        logoAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: isKeyboardVisible ? 16 : 40),
                    Text(
                      'Welcome to BstocK',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your username' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      CustomButton(
                        onPressed: _login,
                        text: 'Login',
                        icon: Icons.login,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Footer - pinned to bottom, hidden when keyboard is visible
          if (!isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: const AshReefFooter(style: FooterStyle.simple),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 