class PumoLegalService {
  static const String termsOfServiceTitle = 'Terms of Service';
  static const String privacyPolicyTitle = 'Privacy Policy';
  
  static const String lastUpdatedDate = 'December 2024';
  
  static const String contactEmail = 'privacy@pumo.com';
  static const String supportEmail = 'support@pumo.com';
  
  // Terms of Service sections
  static const List<Map<String, String>> termsSections = [
    {
      'title': '1. Acceptance of Terms',
      'content': 'By accessing and using the Pumo application, you accept and agree to be bound by the terms and provision of this agreement.'
    },
    {
      'title': '2. Use License',
      'content': 'Permission is granted to temporarily download one copy of the Pumo application for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to reverse engineer any software contained in the application\n• Remove any copyright or other proprietary notations from the materials'
    },
    {
      'title': '3. Disclaimer',
      'content': 'The materials within the Pumo application are provided on an "as is" basis. Pumo makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.'
    },
    {
      'title': '4. Limitations',
      'content': 'In no event shall Pumo or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on the Pumo application, even if Pumo or a Pumo authorized representative has been notified orally or in writing of the possibility of such damage. Because some jurisdictions do not allow limitations on implied warranties, or limitations of liability for consequential or incidental damages, these limitations may not apply to you.'
    },
    {
      'title': '5. Accuracy of Materials',
      'content': 'The materials appearing in the Pumo application could include technical, typographical, or photographic errors. Pumo does not warrant that any of the materials on its application are accurate, complete, or current. Pumo may make changes to the materials contained on its application at any time without notice. However, Pumo does not make any commitment to update the materials.'
    },
    {
      'title': '6. Links',
      'content': 'Pumo has not reviewed all of the sites linked to the application and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by Pumo of the site. Use of any such linked website is at the user\'s own risk.'
    },
    {
      'title': '7. Modifications',
      'content': 'Pumo may revise these terms of service for its application at any time without notice. By using this application, you are agreeing to be bound by the then current version of these terms of service.'
    },
    {
      'title': '8. Governing Law',
      'content': 'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that state or location.'
    }
  ];
  
  // Privacy Policy sections
  static const List<Map<String, String>> privacySections = [
    {
      'title': '1. Information We Collect',
      'content': 'We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support. This may include:\n\n• Personal information (name, email address)\n• Chat messages and AI character interactions\n• Usage data and preferences\n• Device information and technical data'
    },
    {
      'title': '2. How We Use Your Information',
      'content': 'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process your requests and transactions\n• Send you technical notices and support messages\n• Respond to your comments and questions\n• Personalize your experience with AI characters\n• Analyze usage patterns to enhance our services'
    },
    {
      'title': '3. Information Sharing and Disclosure',
      'content': 'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and prevent fraud\n• In connection with a business transfer or acquisition'
    },
    {
      'title': '4. Data Storage and Security',
      'content': 'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. Your data is stored securely using industry-standard encryption and security protocols.'
    },
    {
      'title': '5. AI Character Interactions',
      'content': 'Your conversations with AI characters are processed to provide responses and improve the AI experience. These interactions may be used to:\n\n• Generate appropriate responses\n• Improve AI character personalities\n• Enhance the overall chat experience\n• Train and improve our AI models (in anonymized form)'
    },
    {
      'title': '6. Data Retention',
      'content': 'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this privacy policy. You may request deletion of your data at any time, and we will comply with such requests in accordance with applicable laws.'
    },
    {
      'title': '7. Your Rights and Choices',
      'content': 'You have the right to:\n\n• Access your personal information\n• Correct inaccurate data\n• Delete your account and data\n• Opt out of certain data processing\n• Withdraw consent where applicable\n• Data portability'
    },
    {
      'title': '8. Children\'s Privacy',
      'content': 'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.'
    },
    {
      'title': '9. International Data Transfers',
      'content': 'Your information may be transferred to and processed in countries other than your country of residence. We ensure that such transfers comply with applicable data protection laws and implement appropriate safeguards.'
    },
    {
      'title': '10. Changes to This Policy',
      'content': 'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last updated" date. We encourage you to review this privacy policy periodically.'
    }
  ];
}
