import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
        title: const Text('Terms of Service'),
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
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primaryLight.withOpacity(0.05),
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
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terms of Service',
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
                      'These Terms of Service govern your use of the Trainova mobile application. By downloading, accessing, or using our app, you agree to be bound by these terms.',
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
              '1. Acceptance of Terms',
              'By creating an account or using Trainova, you confirm that you:\n'
                  '• Are at least 13 years old (or the minimum legal age in your jurisdiction)\n'
                  '• Have the legal capacity to enter into these Terms\n'
                  '• Will comply with all applicable laws and regulations\n'
                  '• Provide accurate and truthful information',
              Icons.check_circle_outline,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '2. Description of Service',
              'Trainova is a fitness application that provides:\n'
                  '• Personalized workout plans and recommendations\n'
                  '• Exercise tracking and progress monitoring\n'
                  '• AI-powered workout suggestions\n'
                  '• Fitness goal setting and achievement tracking\n'
                  '• Community features and workout sharing\n'
                  '• Integration with fitness devices and health platforms',
              Icons.fitness_center,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '3. User Accounts and Responsibilities',
              'Account Creation:\n'
                  '• You must provide accurate, current, and complete information\n'
                  '• You are responsible for maintaining the confidentiality of your account\n'
                  '• You must notify us immediately of any unauthorized use\n'
                  '• One person may not maintain multiple accounts\n\n'
                  'Prohibited Activities:\n'
                  '• Violating any applicable laws or regulations\n'
                  '• Impersonating another person or entity\n'
                  '• Uploading harmful, offensive, or inappropriate content\n'
                  '• Attempting to gain unauthorized access to our systems\n'
                  '• Using the App for commercial purposes without permission',
              Icons.account_circle,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '4. Health and Safety Disclaimer',
              'IMPORTANT HEALTH NOTICE:\n'
                  '• Trainova is not a medical application and should not replace professional medical advice\n'
                  '• Consult with a healthcare provider before starting any new fitness program\n'
                  '• Stop exercising immediately if you experience pain, dizziness, or discomfort\n'
                  '• We are not responsible for any injuries that may occur from using our workout recommendations\n'
                  '• All fitness activities are performed at your own risk\n'
                  '• Users with pre-existing medical conditions should seek medical clearance before use',
              Icons.health_and_safety,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
              isWarning: true,
            ),

            _buildContentCard(
              '5. Privacy and Data Collection',
              'We collect and process your personal information as described in our Privacy Policy, including:\n'
                  '• Profile information (name, age, fitness goals)\n'
                  '• Workout data and progress metrics\n'
                  '• Device and usage information\n'
                  '• Location data (if permitted)\n\n'
                  'By using Trainova, you consent to our data collection and processing practices as outlined in our Privacy Policy.',
              Icons.privacy_tip,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '6. Intellectual Property Rights',
              'Trainova Content:\n'
                  '• All content, including workout plans, exercises, and algorithms, is owned by Trainova\n'
                  '• You may not copy, distribute, or create derivative works without permission\n'
                  '• Our trademarks and logos are protected intellectual property\n\n'
                  'User Content:\n'
                  '• You retain ownership of content you create and share\n'
                  '• You grant us a license to use, display, and distribute your content within the App\n'
                  '• You represent that you have the right to share any content you upload',
              Icons.copyright,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '7. Premium Features and Subscriptions',
              'Free and Premium Tiers:\n'
                  '• Basic features are available to all users at no cost\n'
                  '• Premium features may require a subscription\n'
                  '• Subscription fees are charged according to your chosen plan\n'
                  '• Subscriptions automatically renew unless cancelled\n'
                  '• Refunds are provided according to applicable app store policies',
              Icons.star,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '8. AI and Machine Learning Features',
              'Our App uses artificial intelligence to provide personalized recommendations:\n'
                  '• AI suggestions are based on your data and usage patterns\n'
                  '• Recommendations are not guaranteed to be suitable for all users\n'
                  '• We continuously improve our algorithms but cannot guarantee perfect accuracy\n'
                  '• Always use your judgment when following AI-generated workout plans',
              Icons.smart_toy,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '9. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n'
                  '• Trainova is provided "as is" without warranties of any kind\n'
                  '• We disclaim all warranties, express or implied\n'
                  '• We are not liable for any indirect, incidental, or consequential damages\n'
                  '• Our total liability shall not exceed the amount you paid for the service\n'
                  '• Some jurisdictions do not allow limitation of liability, so these limitations may not apply to you',
              Icons.gavel,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            _buildContentCard(
              '10. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
                  'Email: support@trainova.app\n'
                  'Website: www.trainova.app\n'
                  'Address: [Your Business Address]\n\n'
                  'For technical support, please use the in-app help feature or contact our support team.',
              Icons.contact_support,
              cardBackgroundColor,
              textPrimaryColor,
              textSecondaryColor,
              shadowColor,
            ),

            // Thank you card
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
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
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Thank you for choosing Trainova!',
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
                    'By using our App, you\'re joining a community committed to health, fitness, and personal growth. We\'re here to support your fitness journey every step of the way.',
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
  }) {
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
                        color:
                            isWarning
                                ? Colors.orange.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isWarning ? Colors.orange : AppColors.primary,
                        size: 22,
                      ),
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
