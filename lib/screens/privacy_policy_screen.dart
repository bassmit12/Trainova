import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground;
    final cardBackgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
    final textPrimaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
    final textSecondaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
    final shadowColor =
        themeProvider.isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: cardBackgroundColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondaryLight.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.privacy_tip,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content Sections
            _buildContentCard(
              '1. Information We Collect',
              'Personal Information:\n'
                  '• Name and email address (from Google Sign-In)\n'
                  '• Profile picture and basic account information\n'
                  '• Age, weight, height, and fitness goals\n'
                  '• Workout preferences and experience level\n\n'
                  'Fitness Data:\n'
                  '• Workout history and exercise performance\n'
                  '• Progress tracking and achievement data\n'
                  '• Custom workout plans and routines\n'
                  '• Training notes and personal records\n\n'
                  'Technical Information:\n'
                  '• Device information and operating system\n'
                  '• App usage statistics and feature interactions\n'
                  '• Error logs and performance data\n'
                  '• IP address and general location (if permitted)',
              Icons.info_outline,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '2. How We Use Your Information',
              'We use your information to:\n'
                  '• Provide personalized workout recommendations\n'
                  '• Track your fitness progress and achievements\n'
                  '• Improve our AI algorithms for better suggestions\n'
                  '• Sync your data across multiple devices\n'
                  '• Send you important app updates and notifications\n'
                  '• Provide customer support and technical assistance\n'
                  '• Analyze app usage to improve our services\n'
                  '• Ensure app security and prevent fraud',
              Icons.settings,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '3. Legal Basis for Processing',
              'We process your personal data based on:\n'
                  '• Your consent when creating an account\n'
                  '• Contractual necessity to provide our services\n'
                  '• Legitimate interest in improving our app\n'
                  '• Legal obligations for data retention and security\n\n'
                  'You can withdraw your consent at any time by deleting your account or contacting us directly.',
              Icons.gavel,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '4. Data Sharing and Third Parties',
              'We do not sell your personal information. We may share data with:\n\n'
                  'Service Providers:\n'
                  '• Supabase (for secure data storage and authentication)\n'
                  '• Google (for sign-in services and analytics)\n'
                  '• Cloud infrastructure providers\n\n'
                  'Legal Requirements:\n'
                  '• When required by law or legal process\n'
                  '• To protect our rights and prevent fraud\n'
                  '• In case of business transfer or merger\n\n'
                  'With Your Consent:\n'
                  '• When you choose to share data with fitness trackers\n'
                  '• When you participate in community features\n'
                  '• When you explicitly authorize third-party integrations',
              Icons.share,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '5. Data Storage and Security',
              'Security Measures:\n'
                  '• End-to-end encryption for sensitive data\n'
                  '• Secure HTTPS connections for all data transmission\n'
                  '• Regular security audits and vulnerability assessments\n'
                  '• Access controls and authentication mechanisms\n\n'
                  'Data Storage:\n'
                  '• Data is stored on secure servers provided by Supabase\n'
                  '• Servers are located in secure data centers\n'
                  '• Regular backups are maintained for data recovery\n'
                  '• Data is retained only as long as necessary',
              Icons.security,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '6. Your Privacy Rights',
              'You have the right to:\n'
                  '• Access your personal data and request a copy\n'
                  '• Correct inaccurate or incomplete information\n'
                  '• Delete your account and associated data\n'
                  '• Restrict or object to certain data processing\n'
                  '• Data portability (receive your data in a standard format)\n'
                  '• Withdraw consent for data processing\n\n'
                  'To exercise these rights, contact us at privacy@trainova.app or use the in-app settings.',
              Icons.account_balance,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
              isImportant: true,
            ),

            _buildContentCard(
              '7. Cookies and Tracking',
              'We use minimal tracking technologies:\n'
                  '• Essential cookies for app functionality\n'
                  '• Analytics cookies to understand app usage\n'
                  '• Preference cookies to remember your settings\n\n'
                  'You can control cookie preferences through your device settings. Note that disabling certain cookies may affect app functionality.',
              Icons.cookie,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '8. Children\'s Privacy',
              'Trainova is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you become aware that a child has provided us with personal data, please contact us immediately, and we will take steps to remove such information.',
              Icons.child_care,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
              isWarning: true,
            ),

            _buildContentCard(
              '9. Data Retention',
              'We retain your data for different periods:\n'
                  '• Account information: Until you delete your account\n'
                  '• Workout data: Until you delete your account or specific workouts\n'
                  '• Usage analytics: Up to 2 years for service improvement\n'
                  '• Support communications: Up to 3 years for quality assurance\n\n'
                  'After account deletion, we may retain some data for legal compliance or fraud prevention.',
              Icons.schedule,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '10. Contact Information',
              'For privacy-related questions or concerns, contact us at:\n\n'
                  'Email: privacy@trainova.app\n'
                  'Support: support@trainova.app\n'
                  'Website: www.trainova.app\n\n'
                  'Data Protection Officer (if applicable):\n'
                  'Email: dpo@trainova.app\n\n'
                  'We will respond to your privacy inquiries within 30 days.',
              Icons.contact_support,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            // Privacy commitment card
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We are committed to protecting your privacy and being transparent about our data practices. If you have any questions or concerns, please don\'t hesitate to contact us.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(
    String title,
    String content,
    IconData icon,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor, {
    bool isWarning = false,
    bool isImportant = false,
  }) {
    Color iconColor = AppColors.primary;
    Color backgroundColor = AppColors.primary.withOpacity(0.1);

    if (isWarning) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (isImportant) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: cardBackgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
