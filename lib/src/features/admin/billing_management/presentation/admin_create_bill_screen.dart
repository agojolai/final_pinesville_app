import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../billing/domain/unit_billing_model.dart';
import '../../../billing/presentation/billing_providers.dart';
import '../../../billing/domain/property_billing_model.dart';
import '../../../billing/data/billing_repository.dart';
import '../../../../core/utils/app_logger.dart';

class AdminCreateBillScreen extends ConsumerStatefulWidget {
  const AdminCreateBillScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
  });

  final String propertyId;
  final String propertyName;
  final UnitBillingInfo unit;

  @override
  ConsumerState<AdminCreateBillScreen> createState() => _AdminCreateBillScreenState();
}

class _AdminCreateBillScreenState extends ConsumerState<AdminCreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for input fields
  final _rentController = TextEditingController();
  final _electricityReadingController = TextEditingController();
  final _waterReadingController = TextEditingController();
  final _trashChargeController = TextEditingController();
  final _wifiChargeController = TextEditingController();
  final _parkingChargeController = TextEditingController();
  final _additionalChargesController = TextEditingController();
  final _additionalChargesDescController = TextEditingController();
  final _discountController = TextEditingController();
  final _discountReasonController = TextEditingController();
  
  // Track if fields have been focused (for auto-clear behavior)
  bool _electricityFocused = false;
  bool _waterFocused = false;
  
  // Track if fixed charges have been initialized from property data
  bool _fixedChargesInitialized = false;
  
  // Calculated values
  double _rentAmount = 0.0;
  double _electricityConsumption = 0.0;
  double _waterConsumption = 0.0;
  double _electricityCost = 0.0;
  double _waterCost = 0.0;
  double _trashCharge = 0.0;
  double _wifiCharge = 0.0;
  double _parkingCharge = 0.0;
  double _additionalCharges = 0.0;
  double _discount = 0.0;
  double _totalAmount = 0.0;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    // Set rent default
    _rentController.text = widget.unit.monthlyRent.toStringAsFixed(2);
    _rentAmount = widget.unit.monthlyRent;
    
    // Set previous readings as placeholders (will clear on first focus)
    if (widget.unit.lastElectricityReading != null) {
      _electricityReadingController.text = widget.unit.lastElectricityReading!.reading.toString();
    }
    if (widget.unit.lastWaterReading != null) {
      _waterReadingController.text = widget.unit.lastWaterReading!.reading.toString();
    }
    
    // Note: Trash, WiFi, and Parking will be initialized from property fixedCharges in build()
    
    // Add listeners to recalculate on changes
    _rentController.addListener(_calculateTotal);
    _electricityReadingController.addListener(_calculateTotal);
    _waterReadingController.addListener(_calculateTotal);
    _trashChargeController.addListener(_calculateTotal);
    _wifiChargeController.addListener(_calculateTotal);
    _parkingChargeController.addListener(_calculateTotal);
    _additionalChargesController.addListener(_calculateTotal);
    _discountController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _rentController.dispose();
    _electricityReadingController.dispose();
    _waterReadingController.dispose();
    _trashChargeController.dispose();
    _wifiChargeController.dispose();
    _parkingChargeController.dispose();
    _additionalChargesController.dispose();
    _additionalChargesDescController.dispose();
    _discountController.dispose();
    _discountReasonController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final propertyRatesAsync = ref.read(propertyRatesProvider(widget.propertyId));
    
    propertyRatesAsync.whenData((rates) {
      if (rates == null) return;
      
      setState(() {
        // Parse rent (now editable)
        _rentAmount = double.tryParse(_rentController.text) ?? widget.unit.monthlyRent;
        
        // Calculate electricity
        final currentElecReading = double.tryParse(_electricityReadingController.text) ?? 0.0;
        final lastElecReading = widget.unit.lastElectricityReading?.reading ?? 0.0;
        _electricityConsumption = currentElecReading - lastElecReading;
        _electricityCost = _electricityConsumption * rates.electricityRatePerKwh;
        
        // Calculate water
        final currentWaterReading = double.tryParse(_waterReadingController.text) ?? 0.0;
        final lastWaterReading = widget.unit.lastWaterReading?.reading ?? 0.0;
        _waterConsumption = currentWaterReading - lastWaterReading;
        _waterCost = _waterConsumption * rates.waterRatePerCubicMeter;
        
        // Parse fixed charges
        _trashCharge = double.tryParse(_trashChargeController.text) ?? 0.0;
        _wifiCharge = double.tryParse(_wifiChargeController.text) ?? 0.0;
        _parkingCharge = double.tryParse(_parkingChargeController.text) ?? 0.0;
        _additionalCharges = double.tryParse(_additionalChargesController.text) ?? 0.0;
        _discount = double.tryParse(_discountController.text) ?? 0.0;
        
        // Calculate total (subtract discount)
        _totalAmount = _rentAmount + 
                       _electricityCost + 
                       _waterCost + 
                       _trashCharge + 
                       _wifiCharge + 
                       _parkingCharge + 
                       _additionalCharges - 
                       _discount;
      });
    });
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(billingRepositoryProvider);
      final now = DateTime.now();
      
      final currentElecReading = double.tryParse(_electricityReadingController.text) ?? 0.0;
      final currentWaterReading = double.tryParse(_waterReadingController.text) ?? 0.0;
      
      // Build additional charges map with correct keys for repository
      final Map<String, double> additionalChargesMap = {};
      // Fixed charges use lowercase keys to match repository expectations
      if (_trashCharge > 0) additionalChargesMap['trash'] = _trashCharge;
      if (_wifiCharge > 0) additionalChargesMap['wifi'] = _wifiCharge;
      if (_parkingCharge > 0) additionalChargesMap['parking'] = _parkingCharge;
      // Truly additional charges go under 'other' key
      if (_additionalCharges > 0) {
        additionalChargesMap['other'] = _additionalCharges;
      }
      
      await repository.createBillFromInput(
        propertyId: widget.propertyId,
        unitId: widget.unit.unitId, // FIXED: Use document ID, not unitNumber
        month: now.month,
        year: now.year,
        electricityCurrent: currentElecReading,
        waterCurrent: currentWaterReading,
        additionalCharges: additionalChargesMap,
        additionalChargesDescription: _additionalChargesDescController.text.trim().isEmpty 
            ? null 
            : _additionalChargesDescController.text.trim(),
        rentOverride: _rentAmount != widget.unit.monthlyRent ? _rentAmount : null,
        discount: _discount > 0 ? _discount : null,
        discountReason: _discountReasonController.text.trim().isEmpty 
            ? null 
            : _discountReasonController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyRatesAsync = ref.watch(propertyRatesProvider(widget.propertyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Bill',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: propertyRatesAsync.when(
        data: (rates) {
          if (rates == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.danger,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  SizedBox(height: AppConstants.spacingMD),
                  Text(
                    'Property rates not found',
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          // Initialize fixed charges from property data (only once)
          if (!_fixedChargesInitialized) {
            AppLogger.debug('TRACE UI: Fixed charges not initialized yet, scheduling callback');
            AppLogger.trace('TRACE UI: rates.fixedCharges = ${rates.fixedCharges}');
            AppLogger.trace('TRACE UI: rates.fixedCharges.keys = ${rates.fixedCharges.keys}');
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppLogger.trace('TRACE UI: PostFrameCallback executing');
              if (mounted) {
                AppLogger.debug('TRACE UI: Widget is mounted, proceeding with initialization');
                
                // Set trash charge if available and enabled
                if (rates.fixedCharges.containsKey('trash')) {
                  final trashCharge = rates.fixedCharges['trash']!;
                  AppLogger.trace('TRACE UI: Found trash charge - amount: ${trashCharge.amount}, enabled: ${trashCharge.enabled}');
                  if (trashCharge.enabled) {
                    _trashChargeController.text = trashCharge.amount.toStringAsFixed(2);
                    _trashCharge = trashCharge.amount;
                    AppLogger.debug('TRACE UI: Set trash charge to ${trashCharge.amount}');
                  } else {
                    AppLogger.warning('TRACE UI: Trash charge is disabled');
                  }
                } else {
                  AppLogger.warning('TRACE UI: No trash charge found in fixedCharges');
                }
                
                // Set WiFi charge if available and enabled
                if (rates.fixedCharges.containsKey('wifi')) {
                  final wifiCharge = rates.fixedCharges['wifi']!;
                  AppLogger.trace('TRACE UI: Found wifi charge - amount: ${wifiCharge.amount}, enabled: ${wifiCharge.enabled}');
                  if (wifiCharge.enabled) {
                    _wifiChargeController.text = wifiCharge.amount.toStringAsFixed(2);
                    _wifiCharge = wifiCharge.amount;
                    AppLogger.debug('TRACE UI: Set WiFi charge to ${wifiCharge.amount}');
                  } else {
                    AppLogger.warning('TRACE UI: WiFi charge is disabled');
                  }
                } else {
                  AppLogger.warning('TRACE UI: No wifi charge found in fixedCharges');
                }
                
                // Set parking charge if available and enabled
                if (rates.fixedCharges.containsKey('parking')) {
                  final parkingCharge = rates.fixedCharges['parking']!;
                  AppLogger.trace('TRACE UI: Found parking charge - amount: ${parkingCharge.amount}, enabled: ${parkingCharge.enabled}');
                  if (parkingCharge.enabled) {
                    _parkingChargeController.text = parkingCharge.amount.toStringAsFixed(2);
                    _parkingCharge = parkingCharge.amount;
                    AppLogger.debug('TRACE UI: Set parking charge to ${parkingCharge.amount}');
                  } else {
                    AppLogger.warning('TRACE UI: Parking charge is disabled');
                  }
                } else {
                  AppLogger.warning('TRACE UI: No parking charge found in fixedCharges');
                }
                
                _fixedChargesInitialized = true;
                AppLogger.debug('TRACE UI: Fixed charges initialization complete, calling _calculateTotal()');
                _calculateTotal();
              } else {
                AppLogger.warning('TRACE UI: Widget not mounted, skipping initialization');
              }
            });
          } else {
            AppLogger.info('TRACE UI: Fixed charges already initialized, skipping');
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              children: [
                // Property and Unit Info Header
                _buildInfoHeader(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Rent Input (now editable)
                _buildRentSection(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Rates Info
                _buildRatesInfo(rates),
                SizedBox(height: AppConstants.spacingLG),
                 
                // Previous Readings Section
                _buildPreviousReadingsSection(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Current Readings Input
                _buildCurrentReadingsSection(rates),
                SizedBox(height: AppConstants.spacingLG),
                
                // Fixed Charges
                _buildFixedChargesSection(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Additional Charges
                _buildAdditionalChargesSection(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Discount
                _buildDiscountSection(),
                SizedBox(height: AppConstants.spacingLG),
                
                // Calculation Preview
                _buildCalculationPreview(),
                SizedBox(height: AppConstants.spacingXL),
                
                // Create Bill Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _createBill,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.add_circle),
                  label: Text(_isLoading ? 'Creating...' : 'Create Bill'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.all(AppConstants.spacingMD),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading property rates: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Information',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            _buildInfoRow('Property', widget.propertyName),
            _buildInfoRow('Unit', widget.unit.unitNumber),
            _buildInfoRow('Tenant Name', widget.unit.rental?.tenantName ?? 'N/A'),
            _buildInfoRow('Period', '${DateTime.now().month}/${DateTime.now().year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Rent',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _rentController,
              decoration: InputDecoration(
                labelText: 'Rent Amount',
                prefixIcon: const Icon(Iconsax.home),
                prefixText: '₱ ',
                helperText: 'Default: ₱${widget.unit.monthlyRent.toStringAsFixed(2)} (editable for prorated/adjusted rent)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter rent amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesInfo(PropertyUtilityRates rates) {
    return Card(
      color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Rates',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            _buildInfoRow('Electricity', '₱${rates.electricityRatePerKwh.toStringAsFixed(2)} per kWh'),
            _buildInfoRow('Water', '₱${rates.waterRatePerCubicMeter.toStringAsFixed(2)} per m³'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousReadingsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Meter Readings',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildReadingDisplay(
                    icon: Iconsax.flash,
                    label: 'Electricity',
                    reading: widget.unit.lastElectricityReading?.reading.toString() ?? 'N/A',
                    unit: 'kWh',
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: AppConstants.spacingMD),
                Expanded(
                  child: _buildReadingDisplay(
                    icon: Iconsax.drop,
                    label: 'Water',
                    reading: widget.unit.lastWaterReading?.reading.toString() ?? 'N/A',
                    unit: 'm³',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingDisplay({
    required IconData icon,
    required String label,
    required String reading,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            reading,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentReadingsSection(PropertyUtilityRates rates) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Meter Readings',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _electricityReadingController,
              onTap: () {
                // Clear previous reading on first focus
                if (!_electricityFocused) {
                  _electricityReadingController.clear();
                  _electricityFocused = true;
                }
              },
              decoration: InputDecoration(
                labelText: 'Electricity Reading (kWh)',
                prefixIcon: const Icon(Iconsax.flash),
                suffixText: 'kWh',
                helperText: 'Rate: ₱${rates.electricityRatePerKwh.toStringAsFixed(2)}/kWh',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter electricity reading';
                }
                final reading = double.tryParse(value);
                if (reading == null) {
                  return 'Please enter a valid number';
                }
                final lastReading = widget.unit.lastElectricityReading?.reading ?? 0.0;
                if (reading < lastReading) {
                  return 'Reading cannot be less than previous: $lastReading';
                }
                return null;
              },
            ),
            if (_electricityConsumption > 0) ...[
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'Consumption: ${_electricityConsumption.toStringAsFixed(2)} kWh × ₱${rates.electricityRatePerKwh.toStringAsFixed(2)} = ₱${_electricityCost.toStringAsFixed(2)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _waterReadingController,
              onTap: () {
                // Clear previous reading on first focus
                if (!_waterFocused) {
                  _waterReadingController.clear();
                  _waterFocused = true;
                }
              },
              decoration: InputDecoration(
                labelText: 'Water Reading (m³)',
                prefixIcon: const Icon(Iconsax.drop),
                suffixText: 'm³',
                helperText: 'Rate: ₱${rates.waterRatePerCubicMeter.toStringAsFixed(2)}/m³',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter water reading';
                }
                final reading = double.tryParse(value);
                if (reading == null) {
                  return 'Please enter a valid number';
                }
                final lastReading = widget.unit.lastWaterReading?.reading ?? 0.0;
                if (reading < lastReading) {
                  return 'Reading cannot be less than previous: $lastReading';
                }
                return null;
              },
            ),
            if (_waterConsumption > 0) ...[
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'Consumption: ${_waterConsumption.toStringAsFixed(2)} m³ × ₱${rates.waterRatePerCubicMeter.toStringAsFixed(2)} = ₱${_waterCost.toStringAsFixed(2)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFixedChargesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fixed Charges',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _trashChargeController,
              decoration: const InputDecoration(
                labelText: 'Trash Collection Fee',
                prefixIcon: Icon(Iconsax.trash),
                prefixText: '₱ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _wifiChargeController,
              decoration: const InputDecoration(
                labelText: 'WiFi Fee',
                prefixIcon: Icon(Iconsax.wifi),
                prefixText: '₱ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _parkingChargeController,
              decoration: const InputDecoration(
                labelText: 'Parking Fee',
                prefixIcon: Icon(Iconsax.car),
                prefixText: '₱ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalChargesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Charges',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _additionalChargesController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Iconsax.money),
                prefixText: '₱ ',
                helperText: 'Any other charges (optional)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _additionalChargesDescController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Iconsax.note),
                helperText: 'What is this charge for?',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discount',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount Amount',
                prefixIcon: Icon(Iconsax.tag),
                prefixText: '₱ ',
                helperText: 'Discount to apply (optional)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextFormField(
              controller: _discountReasonController,
              decoration: const InputDecoration(
                labelText: 'Discount Reason',
                prefixIcon: Icon(Iconsax.document_text),
                helperText: 'Why is this discount being applied?',
              ),
              maxLines: 2,
              validator: (value) {
                // Require reason if discount is provided
                if (_discount > 0 && (value == null || value.trim().isEmpty)) {
                  return 'Please provide a reason for the discount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationPreview() {
    return Card(
      color: context.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Summary',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            _buildSummaryRow('Rent', _rentAmount),
            _buildSummaryRow('⚡ Electricity', _electricityCost),
            _buildSummaryRow('💧 Water', _waterCost),
            _buildSummaryRow('🗑️ Trash', _trashCharge),
            _buildSummaryRow('📶 WiFi', _wifiCharge),
            _buildSummaryRow('🅿️ Parking', _parkingCharge),
            if (_additionalCharges > 0)
              _buildSummaryRow('Additional', _additionalCharges),
            if (_discount > 0)
              _buildSummaryRow('Discount', -_discount, isDiscount: true),
            Divider(height: AppConstants.spacingMD * 2),
            _buildSummaryRow(
              'TOTAL',
              _totalAmount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : null,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: (isTotal ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? context.colorScheme.primary : (isDiscount ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}
