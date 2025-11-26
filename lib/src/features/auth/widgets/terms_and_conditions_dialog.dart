import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  final VoidCallback onAccept;

  const TermsAndConditionsDialog({
    super.key,
    required this.onAccept,
  });

  @override
  State<TermsAndConditionsDialog> createState() => _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppConstants.spacingLG),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusLG),
                  topRight: Radius.circular(AppConstants.radiusLG),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.document_text_1,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(AppConstants.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prominent notice about written contract
                    Container(
                      padding: EdgeInsets.all(AppConstants.spacingMD),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        border: Border.all(
                          color: context.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Iconsax.document_1,
                                color: context.colorScheme.primary,
                                size: 24,
                              ),
                              SizedBox(width: AppConstants.spacingSM),
                              Expanded(
                                child: Text(
                                  'Important Notice',
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppConstants.spacingSM),
                          Text(
                            'Your account creation and use of this application is governed by the written Lease Agreement signed between you and Pinesville Management. The signed lease contract serves as the primary legal document for your tenancy. These digital terms and conditions supplement the written contract and govern your use of the Pinesville mobile application.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingLG),
                    
                    _buildSection(
                      title: 'Introduction',
                      content: 
                          'Welcome to Pinesville Property Management System. By creating an account and using our mobile application, you acknowledge that:\n\n'
                          '• You have read and signed the written Lease Agreement with Pinesville Management\n'
                          '• These app Terms and Conditions work in conjunction with your signed lease contract\n'
                          '• In case of any conflict, the terms of the written Lease Agreement shall prevail\n\n'
                          'This agreement is between you (the "Tenant") and Pinesville Management (the "Admin"). By registering, you confirm that you have the legal capacity to enter into this agreement.',
                    ),
                    
                    _buildSection(
                      title: '1. Account Registration and Lease Agreement',
                      content:
                          '1.1 Account creation requires that you have executed a written Lease Agreement with Pinesville Management. Your registration must match the information in your signed lease contract.\n\n'
                          '1.2 You must provide accurate, complete, and current information during registration that corresponds to your lease agreement.\n\n'
                          '1.3 Your account is personal and non-transferable. You are responsible for maintaining the confidentiality of your login credentials.\n\n'
                          '1.4 All registrations are subject to admin verification against existing lease agreements. We reserve the right to reject any application that does not match our records.\n\n'
                    
                    ),

                    _buildSection(
                      title: '2. Rent and Payment Terms',
                      content:
                          '2.1 Monthly rent and utility charges are calculated based on your unit assignment and actual consumption.\n\n'
                          '2.2 Bills are generated monthly and must be paid within 7 days of the bill creation date.\n\n'
                          '2.3 Late payments will incur a fee of 150.00 per week after the due date.\n\n'
                          '2.4 Payment proof must be submitted through the app and verified by admin before being applied to your bill.\n\n'
                          '2.5 Failure to pay for 2 consecutive months may result in eviction proceedings.',
                    ),

                    _buildSection(
                      title: '3. Utility Usage and Billing',
                      content:
                          '3.1 You will be charged for electricity and water based on meter readings.\n\n'
                          '3.2 Fixed charges (trash, WiFi, parking) are applied monthly as applicable to your unit.\n\n'
                          '3.3 Meter readings are taken by management on a monthly basis. You will receive notifications when new bills are available.\n\n'
                          '3.4 Disputes regarding meter readings must be raised within 7 days of bill creation through the support ticket system.',
                    ),

                    _buildSection(
                      title: '4. Property Rules and Conduct (Per Lease Agreement)',
                      content:
                          '4.1 All property rules and conduct requirements are detailed in your written Lease Agreement. You agree to use the property for residential purposes only.\n\n'
                          '4.2 You must maintain the property in good condition and report any damages or maintenance issues promptly through the app.\n\n'
                          '4.3 Subletting or unauthorized occupants are strictly prohibited as per your lease contract.\n\n'
                          '4.4 You must comply with all property rules, regulations, and community guidelines as specified in the Lease Agreement.\n\n'
                          '4.5 Violations of lease terms may result in termination of tenancy as outlined in your written contract.',
                    ),

                    _buildSection(
                      title: '5. Maintenance and Repairs',
                      content:
                          '5.1 Maintenance requests must be submitted through the app\'s support ticket system.\n\n'
                          '5.2 Emergency repairs will be prioritized and addressed accordingly.\n\n'
                          '5.3 Non-emergency repairs will be scheduled within a reasonable timeframe.\n\n'
                          '5.4 You are responsible for damages caused by negligence or misuse.',
                    ),

                    _buildSection(
                      title: '6. Privacy and Data Protection',
                      content:
                          '6.1 We collect and process your personal information as described in our Privacy Policy below.\n\n'
                          '6.2 Your data is stored securely using Firebase cloud services with industry-standard encryption.\n\n'
                          '6.3 We will never sell your personal information to third parties.\n\n'
                          '6.4 You have the right to request access, correction, or deletion of your personal data.',
                    ),

                    _buildSection(
                      title: '7. App Usage and Notifications',
                      content:
                          '7.1 The Pinesville mobile app is the primary communication channel for billing, announcements, and support.\n\n'
                          '7.2 You agree to receive push notifications regarding bills, payments, maintenance updates, and important announcements.\n\n'
                          '7.3 You are responsible for keeping the app updated and ensuring you receive notifications.\n\n'
                          '7.4 Failure to check notifications does not exempt you from payment or other obligations.',
                    ),

                    _buildSection(
                      title: '8. Termination and Move-Out (Per Lease Agreement)',
                      content:
                          '8.1 Termination notice requirements and procedures are as specified in your written Lease Agreement.\n\n'
                          '8.2 Upon move-out, a final inspection will be conducted to assess any damages as per the lease contract.\n\n'
                          '8.3 Your final bill will include prorated rent, utilities, and any damage charges as outlined in the Lease Agreement.\n\n'
                          '8.4 Security deposit handling follows the terms specified in your signed lease contract.',
                    ),

                    _buildSection(
                      title: '9. Limitation of Liability',
                      content:
                          '9.1 Pinesville Management is not liable for personal injuries, property damage, or loss of belongings except in cases of proven negligence.\n\n'
                          '9.2 We are not responsible for service interruptions (power, water, internet) caused by external providers.\n\n'
                          '9.3 The app is provided "as is" without warranties. We do not guarantee uninterrupted service.',
                    ),

                    _buildSection(
                      title: '10. Amendments',
                      content:
                          '10.1 We reserve the right to modify these terms at any time.\n\n'
                          '10.2 Significant changes will be communicated through the app.\n\n'
                          '10.3 Continued use of the app after changes constitutes acceptance of the new terms.',
                    ),

                    Divider(height: 40),

                    // Privacy Policy
                    Text(
                      'PRIVACY POLICY',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingMD),

                    _buildSection(
                      title: '1. Information We Collect',
                      content:
                          ' Personal Information: Name, email, phone number, move-in date\n'
                          ' Property Information: Assigned unit, property location\n'
                          ' Financial Information: Payment records, billing history, bank details (for payment proof)\n'
                          ' Usage Data: Electricity and water consumption, app usage patterns\n'
                          ' Communication Data: Support tickets, chat messages with admin\n'
                          ' Device Information: FCM token for push notifications, device type',
                    ),

                    _buildSection(
                      title: '2. How We Use Your Information',
                      content:
                          ' To create and manage your tenant account\n'
                          ' To generate monthly bills and process payments\n'
                          ' To send notifications about bills, payments, and announcements\n'
                          ' To provide customer support and respond to inquiries\n'
                          ' To maintain and improve our services\n'
                          ' To ensure property security and enforce lease terms\n'
                          ' To comply with legal obligations',
                    ),

                    _buildSection(
                      title: '3. Data Storage and Security',
                      content:
                          ' All data is stored on Firebase Cloud Firestore with encryption in transit and at rest\n'
                          ' Profile pictures and payment proofs are stored in Firebase Storage with access controls\n'
                          ' We use Firebase Authentication for secure user authentication\n'
                          ' Access to your data is restricted to authorized admin personnel only\n'
                          ' We implement industry-standard security practices to protect your information',
                    ),

                    _buildSection(
                      title: '4. Data Sharing',
                      content:
                          'We do NOT sell your personal information. We only share data:\n\n'
                          ' With utility providers for billing purposes\n'
                          ' With legal authorities if required by law\n'
                          ' With service providers (Firebase/Google) who help us operate the app under strict confidentiality agreements',
                    ),

                    _buildSection(
                      title: '5. Your Rights',
                      content:
                          'You have the right to:\n\n'
                          ' Access your personal data stored in the app\n'
                          ' Request correction of inaccurate information\n'
                          ' Request deletion of your account and data (after settling all dues)\n'
                          ' Opt-out of non-essential notifications\n'
                          ' Download your billing and payment history\n\n'
                          'To exercise these rights, contact us through the app support system.',
                    ),

                    _buildSection(
                      title: '6. Data Retention',
                      content:
                          ' Active tenant data is retained for the duration of your tenancy\n'
                          ' After move-out, your data is retained for 2 years for legal and accounting purposes\n'
                          ' Payment records are retained for 7 years as required by financial regulations\n'
                          ' You may request early deletion after settling all obligations',
                    ),

                    _buildSection(
                      title: '7. Cookies and Tracking',
                      content:
                          ' The mobile app does not use cookies\n'
                          ' We collect anonymous usage analytics to improve app performance\n'
                          ' Push notifications require your device FCM token\n'
                    ),

                    _buildSection(
                      title: '8. Third-Party Services',
                      content:
                          'We use the following third-party services:\n\n'
                          ' Firebase (Google): Authentication, database, storage, cloud functions, messaging\n'
                          ' Payment platforms: For processing rent and utility payments\n\n'
                          'These services have their own privacy policies which we encourage you to review.',
                    ),

                    _buildSection(
                      title: '9. Children\'s Privacy',
                      content:
                          'Our app is not intended for users under 18 years of age. We do not knowingly collect information from minors.',
                    ),

                    _buildSection(
                      title: '10. Contact Us',
                      content:
                          'For questions about these Terms or Privacy Policy, contact us through:\n\n'
                          ' In-app support ticket system\n'
                          ' In-app chat with admin\n'
                          ' Property management office',
                    ),

                    SizedBox(height: AppConstants.spacingMD),
                    
                    Text(
                      'Last Updated: November 26, 2025',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    
                    SizedBox(height: AppConstants.spacingLG),
                    
                    Text(
                      'By clicking "I Agree", you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions and Privacy Policy.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Scroll indicator
            if (!_hasScrolledToBottom)
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppConstants.spacingSM,
                  horizontal: AppConstants.spacingLG,
                ),
                color: context.colorScheme.secondaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.arrow_down_1,
                      size: 16,
                      color: context.colorScheme.onSecondaryContainer,
                    ),
                    SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'Please scroll to the bottom to continue',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(AppConstants.spacingLG),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.radiusLG),
                  bottomRight: Radius.circular(AppConstants.radiusLG),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        ),
                      ),
                      child: Text('Decline'),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMD),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _hasScrolledToBottom
                          ? () {
                              Navigator.of(context).pop();
                              widget.onAccept();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        ),
                      ),
                      child: Text(
                        'I Agree',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
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

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: context.colorScheme.primary,
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            content,
            style: context.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
