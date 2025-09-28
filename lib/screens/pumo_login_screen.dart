import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pumo_auth_service.dart';
import 'pumo_main_screen.dart';
import 'pumo_terms_screen.dart';
import 'pumo_privacy_screen.dart';

class PumoLoginScreen extends StatefulWidget {
  const PumoLoginScreen({super.key});

  @override
  State<PumoLoginScreen> createState() => _PumoLoginScreenState();
}

class _PumoLoginScreenState extends State<PumoLoginScreen> {
  bool _isAgreed = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _enterApp() async {
    if (!_isAgreed) {
      _showSnackBar('Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Login user
        await PumoAuthService.login();
      
      // Simulate loading
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PumoMainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Login failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/resources/pumo_bg_login_nor.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildContent(),
            ),
            const SizedBox(height: 40),
            _buildEnterButton(),
            _buildAgreementSection(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Content can be added here if needed
        ],
      ),
    );
  }

  Widget _buildEnterButton() {
    return Container(
      width: 295,
      height: 52,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/resources/pumo_login_nor.webp'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _isLoading ? null : _enterApp,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Enter Pumo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isAgreed = !_isAgreed;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _isAgreed ? const Color(0xFFE91E63) : Colors.transparent,
                border: Border.all(
                  color: _isAgreed ? const Color(0xFFE91E63) : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isAgreed
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                children: [
                  const TextSpan(text: 'I have read and agree '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PumoTermsScreen(),
                  ),
                );
                      },
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PumoPrivacyScreen(),
                  ),
                );
                      },
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
