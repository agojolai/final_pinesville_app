import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/snackbars/loaders.dart';

class PayRentScreen extends StatefulWidget {
  const PayRentScreen({super.key});

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String selectedPaymentMethod = 'gcash';
  File? proofOfPaymentImage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pay Rent',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Iconsax.arrow_left,
            color: context.colorScheme.onSurface,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: context.paddingHorizontal(AppConstants.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.spacingMD),
                _RentSummaryCard(),
                SizedBox(height: AppConstants.spacingLG),
                _PaymentQRSection(
                  selectedMethod: selectedPaymentMethod,
                  onMethodChanged: (method) => setState(() => selectedPaymentMethod = method),
                ),
                SizedBox(height: AppConstants.spacingLG),
                _ProofOfPaymentSection(
                  proofImage: proofOfPaymentImage,
                  onImageSelected: (image) => setState(() => proofOfPaymentImage = image),
                  isCashPayment: selectedPaymentMethod == 'cash',
                ),
                SizedBox(height: AppConstants.spacingLG),
                _SubmitButton(
                  hasProof: proofOfPaymentImage != null,
                  onSubmit: _submitProofOfPayment,
                ),
                SizedBox(height: AppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitProofOfPayment() {
    if (proofOfPaymentImage != null) {
      HapticFeedback.heavyImpact();
      Loaders.successSnackBar(
        context,
        title: 'Proof of Payment Submitted!',
        message: 'We will verify your payment within 24 hours.',
        duration: 4,
      );
      Navigator.of(context).pop();
    }
  }
}

// Rent Summary Card Widget
class _RentSummaryCard extends StatelessWidget {
  const _RentSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha: 0.92),
            context.colorScheme.primaryContainer,
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Monthly Rent Payment',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
           
          SizedBox(height: AppConstants.spacingLG),
          Text(
            'Amount Due',
            style: context.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Montserrat',
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            '₱25,000.00',
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                SizedBox(width: AppConstants.spacingXS),
                Text(
                  'Due Date: September 5, 2025',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Payment QR Section Widget
class _PaymentQRSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const _PaymentQRSection({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods & QR Codes',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _PaymentMethodCard(
                name: 'GCash',
                imagePath: 'assets/images/icon-gcash.png',
                fallbackIcon: Iconsax.wallet,
                isSelected: selectedMethod == 'gcash',
                onTap: () => onMethodChanged('gcash'),
              ),

              _PaymentMethodCard(
                name: 'BDO',
                imagePath: 'assets/images/icon-bdo.png',
                fallbackIcon: Iconsax.bank,
                isSelected: selectedMethod == 'bdo',
                onTap: () => onMethodChanged('bdo'),
              ),

                //TODO: sa dark theme, gawing puti yung photo
              _PaymentMethodCard(
                name: 'GOTyme',
                imagePath: 'assets/images/icon-gotyme.png',
                fallbackIcon: Iconsax.wallet,
                isSelected: selectedMethod == 'gotyme',
                onTap: () => onMethodChanged('gotyme'),
              ),

              _PaymentMethodCard(
                name: 'Cash',
                imagePath: null, // Keep cash as icon since it's not a bank/service
                fallbackIcon: Iconsax.money,
                isSelected: selectedMethod == 'cash',
                onTap: () => onMethodChanged('cash'),
              ),
            ],
          ),
        ),
        SizedBox(height: AppConstants.spacingLG),
        _QRCodeDisplay(paymentMethod: selectedMethod),
      ],
    );
  }
}

// Payment Method Card Widget
class _PaymentMethodCard extends StatelessWidget {
  final String name;
  final String? imagePath; // Changed from IconData to String path
  final IconData? fallbackIcon; // Fallback icon if image is not available
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.name,
    this.imagePath,
    this.fallbackIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: AppConstants.spacingSM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: context.radiusLG,
          child: Container(
            width: 100,
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? context.colorScheme.primary 
                    : context.colorScheme.outline.withValues(alpha:0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: context.radiusLG,
              color: isSelected 
                  ? context.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : context.colorScheme.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Show fallback icon if image fails to load
                        return Icon(
                          fallbackIcon ?? Iconsax.wallet,
                          size: 32,
                          color: isSelected 
                              ? context.colorScheme.primary 
                              : context.colorScheme.onSurface.withValues(alpha:0.7),
                        );
                      },
                    ),
                  )
                else
                  Icon(
                    fallbackIcon ?? Iconsax.wallet,
                    size: 32,
                    color: isSelected 
                        ? context.colorScheme.primary 
                        : context.colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                SizedBox(height: AppConstants.spacingXS),
                Text(
                  name,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontFamily: 'Montserrat',
                    color: isSelected 
                        ? context.colorScheme.primary 
                        : context.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// QR Code Display Widget
class _QRCodeDisplay extends StatelessWidget {
  final String paymentMethod;

  const _QRCodeDisplay({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final isCash = paymentMethod == 'cash';
    
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.outline.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCash ? Iconsax.money_send : Iconsax.scan_barcode,
                color: context.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: AppConstants.spacingSM),
              Text(
                isCash ? 'Cash Payment Instructions' : 'Scan QR Code to Pay',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          if (isCash)
            _CashPaymentInstructions(context)
          else
            Center(
              child: _QRCodePlaceholder(context, paymentMethod: paymentMethod),
            ),
          SizedBox(height: AppConstants.spacingMD),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                SizedBox(width: AppConstants.spacingXS),
                Expanded(
                  child: Text(
                    isCash 
                        ? 'Please bring the exact amount and take a photo during handover.'
                        : 'Please send the exact amount and upload your proof of payment below.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _CashPaymentInstructions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.money_4,
            size: 48,
            color: Colors.orange.shade600,
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Cash Payment Process',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            '1. Prepare the exact amount \n2. Chat the admin before handing over the payment\n3. Hand over the payment to staff\n4. Take a photo during the transaction\n5. Upload the photo as proof below',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade700,
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _QRCodePlaceholder(BuildContext context, {required String paymentMethod}) {
    String? qrImagePath = _getQRCodeImagePath(paymentMethod);
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 280,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: context.radiusLG,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: qrImagePath != null
          ? ClipRRect(
              borderRadius: context.radiusLG,
              child: Image.asset(
                qrImagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildQRPlaceholder(context, paymentMethod);
                },
              ),
            )
          : _buildQRPlaceholder(context, paymentMethod),
    );
  }

  Widget _buildQRPlaceholder(BuildContext context, String paymentMethod) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.scan_barcode,
          size: 80,
          color: context.colorScheme.outline.withValues(alpha:0.5),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Text(
          _getPaymentMethodName(paymentMethod),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: context.colorScheme.primary,
          ),
        ),
        Text(
          'QR Code',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha:0.7),
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  String? _getQRCodeImagePath(String method) {
    switch (method) {
      case 'gcash':
        return 'assets/images/gcash.jpg';
      case 'bdo':
        return 'assets/images/bdo.jpg';
      case 'gotyme':
        return 'assets/images/gotyme.JPG';
      default:
        return null; // No QR image available
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'gcash':
        return 'GCash';
      case 'bdo': 
        return 'BDO';
      case 'gotyme':
        return 'GOTyme';
      case 'cash':
        return 'Cash Payment';
      default:
        return 'Payment';
    }
  }
}

// Proof of Payment Section Widget
class _ProofOfPaymentSection extends StatelessWidget {
  final File? proofImage;
  final ValueChanged<File> onImageSelected;
  final bool isCashPayment;

  const _ProofOfPaymentSection({
    required this.proofImage,
    required this.onImageSelected,
    required this.isCashPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCashPayment ? 'Upload Photo of Payment Handover' : 'Upload Proof of Payment',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickImage(context),
            borderRadius: context.radiusLG,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: proofImage != null 
                      ? context.colorScheme.primary 
                      : context.colorScheme.outline.withValues(alpha:0.3),
                  width: 2,
                ),
                borderRadius: context.radiusLG,
                color: proofImage != null 
                    ? context.colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : context.colorScheme.surface,
              ),
              child: proofImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: context.radiusLG,
                          child: Image.file(
                            proofImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha:0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => _pickImage(context),
                              icon: Icon(
                                Iconsax.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.camera,
                          size: 48,
                          color: context.colorScheme.outline.withValues(alpha:0.5),
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        Text(
                          isCashPayment 
                              ? 'Tap to upload photo of you\nhanding over the payment'
                              : 'Tap to upload screenshot\nor photo of your payment',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha:0.7),
                            fontFamily: 'Montserrat',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _pickImage(BuildContext context) async {
    HapticFeedback.lightImpact();
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: AppConstants.spacingLG),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        onImageSelected(File(image.path));
                      }
                    },
                  ),
                ),
                SizedBox(width: AppConstants.spacingMD),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        onImageSelected(File(image.path));
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingLG),
          ],
        ),
      ),
    );
  }
}

// Image Source Button Widget
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: context.radiusLG,
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacingLG),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha:0.3),
            ),
            borderRadius: context.radiusLG,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: context.colorScheme.primary,
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Submit Button Widget
class _SubmitButton extends StatelessWidget {
  final bool hasProof;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.hasProof,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: hasProof 
            ? context.colorScheme.primary 
            : context.colorScheme.outline.withValues(alpha:0.3),
        foregroundColor: Colors.white,
        elevation: hasProof ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusXL,
        ),
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingLG),
        shadowColor: context.colorScheme.primary.withValues(alpha: 0.18),
      ),
      onPressed: hasProof ? onSubmit : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_upload,
            size: 20,
          ),
          SizedBox(width: AppConstants.spacingSM),
          Text(
            hasProof ? 'Submit Proof of Payment' : 'Please upload proof first',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Button Widget

