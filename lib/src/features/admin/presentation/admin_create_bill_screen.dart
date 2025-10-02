import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../billing/domain/unit_billing_model.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../billing/domain/property_billing_model.dart';
import '../../billing/data/billing_repository.dart';

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
  final _electricityReadingController = TextEditingController();
  final _waterReadingController = TextEditingController();
  final _trashChargeController = TextEditingController();
  final _wifiChargeController = TextEditingController();
  final _parkingChargeController = TextEditingController();
  final _additionalChargesController = TextEditingController();
  final _additionalChargesDescController = TextEditingController();
  
  // Calculated values
  double _electricityConsumption = 0.0;
  double _waterConsumption = 0.0;
  double _electricityCost = 0.0;
  double _waterCost = 0.0;
  double _trashCharge = 0.0;
  double _wifiCharge = 0.0;
  double _parkingCharge = 0.0;
  double _additionalCharges = 0.0;
  double _totalAmount = 0.0;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    // Set default values from unit info if available
    if (widget.unit.lastElectricityReading != null) {
      _electricityReadingController.text = widget.unit.lastElectricityReading!.reading.toString();
    }
    if (widget.unit.lastWaterReading != null) {
      _waterReadingController.text = widget.unit.lastWaterReading!.reading.toString();
    }
    
    // Add listeners to recalculate on changes
    _electricityReadingController.addListener(_calculateTotal);
    _waterReadingController.addListener(_calculateTotal);
    _trashChargeController.addListener(_calculateTotal);
    _wifiChargeController.addListener(_calculateTotal);
    _parkingChargeController.addListener(_calculateTotal);
    _additionalChargesController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _electricityReadingController.dispose();
    _waterReadingController.dispose();
    _trashChargeController.dispose();
    _wifiChargeController.dispose();
    _parkingChargeController.dispose();
    _additionalChargesController.dispose();
    _additionalChargesDescController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final propertyRatesAsync = ref.read(propertyRatesProvider(widget.propertyId));
    
    propertyRatesAsync.whenData((rates) {
      if (rates == null) return;
      
      setState(() {
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
        
        // Parse other charges
        _trashCharge = double.tryParse(_trashChargeController.text) ?? 0.0;
        _wifiCharge = double.tryParse(_wifiChargeController.text) ?? 0.0;
        _parkingCharge = double.tryParse(_parkingChargeController.text) ?? 0.0;
        _additionalCharges = double.tryParse(_additionalChargesController.text) ?? 0.0;
        
        // Calculate total
        _totalAmount = widget.unit.monthlyRent + 
                       _electricityCost + 
                       _waterCost + 
                       _trashCharge + 
                       _wifiCharge + 
                       _parkingCharge + 
                       _additionalCharges;
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
      
      // Build additional charges map
      final Map<String, double> additionalChargesMap = {};
      if (_trashCharge > 0) additionalChargesMap['Trash Collection'] = _trashCharge;
      if (_wifiCharge > 0) additionalChargesMap['WiFi'] = _wifiCharge;
      if (_parkingCharge > 0) additionalChargesMap['Parking'] = _parkingCharge;
      if (_additionalCharges > 0) {
        final desc = _additionalChargesDescController.text.isEmpty 
            ? 'Additional Charge'
            : _additionalChargesDescController.text;
        additionalChargesMap[desc] = _additionalCharges;
      }
      
      await repository.createBillFromInput(
        propertyId: widget.propertyId,
        unitId: widget.unit.unitNumber,
        month: now.month,
        year: now.year,
        electricityCurrent: currentElecReading,
        waterCurrent: currentWaterReading,
        additionalCharges: additionalChargesMap,
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

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              children: [
                // Property and Unit Info Header
                _buildInfoHeader(),
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
            _buildInfoRow('Tenant ID', widget.unit.tenantId ?? 'N/A'),
            _buildInfoRow('Monthly Rent', '₱${widget.unit.monthlyRent.toStringAsFixed(2)}'),
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
              color: context.colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildRatesInfo(PropertyUtilityRates rates) {
    return Card(
      color: context.colorScheme.primaryContainer.withOpacity(0.3),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.7),
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
              color: context.colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildCalculationPreview() {
    return Card(
      color: context.colorScheme.tertiaryContainer.withOpacity(0.3),
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
            _buildSummaryRow('Rent', widget.unit.monthlyRent),
            _buildSummaryRow('⚡ Electricity', _electricityCost),
            _buildSummaryRow('💧 Water', _waterCost),
            _buildSummaryRow('🗑️ Trash', _trashCharge),
            _buildSummaryRow('📶 WiFi', _wifiCharge),
            _buildSummaryRow('🅿️ Parking', _parkingCharge),
            if (_additionalCharges > 0)
              _buildSummaryRow('Additional', _additionalCharges),
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

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: (isTotal ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? context.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
