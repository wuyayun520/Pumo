import 'package:flutter/material.dart';

class PumoPrivacyScreen extends StatelessWidget {
  const PumoPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support. This may include:\n\n• Personal information (name, email address)\n• Chat messages and AI character interactions\n• Usage data and preferences\n• Device information and technical data',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process your requests and transactions\n• Send you technical notices and support messages\n• Respond to your comments and questions\n• Personalize your experience with AI characters\n• Analyze usage patterns to enhance our services',
            ),
            _buildSection(
              '3. Information Sharing and Disclosure',
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and prevent fraud\n• In connection with a business transfer or acquisition',
            ),
            _buildSection(
              '4. Data Storage and Security',
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. Your data is stored securely using industry-standard encryption and security protocols.',
            ),
            _buildSection(
              '5. AI Character Interactions',
              'Your conversations with AI characters are processed to provide responses and improve the AI experience. These interactions may be used to:\n\n• Generate appropriate responses\n• Improve AI character personalities\n• Enhance the overall chat experience\n• Train and improve our AI models (in anonymized form)',
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this privacy policy. You may request deletion of your data at any time, and we will comply with such requests in accordance with applicable laws.',
            ),
            _buildSection(
              '7. Your Rights and Choices',
              'You have the right to:\n\n• Access your personal information\n• Correct inaccurate data\n• Delete your account and data\n• Opt out of certain data processing\n• Withdraw consent where applicable\n• Data portability',
            ),
            _buildSection(
              '8. Children\'s Privacy',
              'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.',
            ),
            _buildSection(
              '9. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your country of residence. We ensure that such transfers comply with applicable data protection laws and implement appropriate safeguards.',
            ),
            _buildSection(
              '10. Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date. We encourage you to review this privacy policy periodically.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Last updated: December 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE91E63).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@pumo.com\nSupport: support@pumo.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
