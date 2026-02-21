import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class PostErrandScreen extends StatefulWidget {
  const PostErrandScreen({super.key});

  @override
  State<PostErrandScreen> createState() => _PostErrandScreenState();
}

class _PostErrandScreenState extends State<PostErrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _stopOverController = TextEditingController();
  final _altContactController = TextEditingController();
  final _promoController = TextEditingController();

  LocationRate? _selectedLocation;
  ServiceRate? _selectedService;
  final List<PricingAddon> _selectedAddons = [];
  bool _hasStopOver = false;
  bool _isBulky = false;
  PromoCode? _appliedPromo;
  double _totalPrice = 0.0;
  double _currentDebt = 0.0;
  DateTime? _scheduledAt;
  String _paymentType = 'pay_later';
  
  // Default fallback values
  final double _stopOverFee = 150.0;
  final double _bulkyFee = 300.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDebtAndCalculate();
  }

  Future<void> _fetchDebtAndCalculate() async {
    final auth = context.read<AuthService>();
    final user = await auth.getCurrentUserData();
    if (user != null && mounted) {
      setState(() {
        _currentDebt = user.debt;
      });
    }
    _calculatePrice();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _stopOverController.dispose();
    _altContactController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _calculatePrice() {
    double price = _selectedService?.flatRate ?? 0.0;
    if (_selectedLocation != null) {
      price += _selectedLocation!.rate;
    }
    
    for (var addon in _selectedAddons) {
      price += addon.additionalCost;
    }

    if (_hasStopOver) {
      price += _stopOverFee;
    }
    if (_isBulky) {
      price += _bulkyFee;
    }
    if (_appliedPromo != null) {
      price -= _appliedPromo!.discountAmount;
    }
    
    // Add existing debt
    price += _currentDebt;

    setState(() {
      _totalPrice = price < 0 ? 0 : price;
    });
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.isEmpty) return;

    final databaseService = context.read<DatabaseService>();
    final promo = await databaseService.verifyPromoCode(_promoController.text.trim());

    if (mounted) {
      if (promo != null) {
        setState(() {
          _appliedPromo = promo;
        });
        _calculatePrice();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo code "${promo.code}" applied!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired promo code.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitErrand() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service type.')),
        );
       return;
    }
    if (_selectedLocation == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location area.')),
        );
       return;
    }

    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();

    // Anti-Fraud Check
    final allLocations = await db.locationRatesRef.get();
    if (!mounted) return;
    final description = _descriptionController.text.toLowerCase();
    
    String? suspectedLocation;
    for (var doc in allLocations.docs) {
      final loc = doc.data();
      if (loc.id != _selectedLocation!.id && description.contains(loc.area.toLowerCase())) {
        if (loc.rate > _selectedLocation!.rate) {
          suspectedLocation = loc.area;
          break;
        }
      }
    }

    if (suspectedLocation != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Mismatch?', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.background,
          content: Text('Your description mentions "$suspectedLocation", but you selected "${_selectedLocation!.area}". If the location is incorrect, runners may request a surcharge or cancel the errand.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('EDIT')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('PROCEED ANYWAY')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    String? mpesaCode;
    if (_paymentType == 'pay_now') {
      mpesaCode = await _showMpesaDialog();
      if (mpesaCode == null) return;
    }

    setState(() => _isLoading = true);
    final user = await auth.getCurrentUserData();
    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post an errand.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final errandId = await db.postErrandReturnId(
        customerId: user.id,
        title: _titleController.text,
        description: _descriptionController.text,
        pickupLocation: _pickupController.text,
        deliveryLocation: _dropoffController.text,
        stopOverLocation: _hasStopOver ? _stopOverController.text : null,
        alternativeContact: _altContactController.text.isNotEmpty ? _altContactController.text : null,
        hasStopOver: _hasStopOver,
        isBulky: _isBulky,
        promoCodeUsed: _appliedPromo?.code,
        estimatedPrice: _totalPrice,
        scheduledAt: _scheduledAt,
        paymentType: _paymentType,
        mpesaCode: mpesaCode,
      );

      if (_paymentType == 'pay_now' && mpesaCode != null) {
        await db.transactionsRef.add(AppTransaction(
          id: '',
          errandId: errandId,
          userId: user.id,
          mpesaCode: mpesaCode,
          status: 'pending',
          amount: _totalPrice,
          createdAt: DateTime.now(),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_paymentType == 'pay_now' 
              ? 'Errand posted! Admin will verify your M-Pesa code: $mpesaCode shortly.' 
              : 'Errand posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post errand: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showMpesaDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('M-Pesa Payment', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please pay KES ${_totalPrice.toStringAsFixed(2)} to our Till Number: 123456 and enter the 10-character transaction code below.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 10,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'M-Pesa Code', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase()),
            child: const Text('SUBMIT CODE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Post a New Errand')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text(
                  'Errand Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextFormField(
                      controller: _titleController,
                      labelText: 'Errand Title (e.g., Buy Groceries)',
                      icon: Icons.title,
                      validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<ServiceRate>>(
                      stream: db.serviceRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        
                        final rates = snapshot.data!;
                        return DropdownButtonFormField<ServiceRate>(
                          initialValue: _selectedService,
                          decoration: const InputDecoration(
                            labelText: 'Service Type',
                            prefixIcon: Icon(Icons.settings_applications, color: AppTheme.gold),
                          ),
                          dropdownColor: AppTheme.background,
                          style: const TextStyle(color: Colors.white),
                          items: rates.map((rate) {
                            return DropdownMenuItem(
                              value: rate,
                              child: Text('${rate.name} (Ksh ${rate.flatRate})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedService = value;
                            });
                            _calculatePrice();
                          },
                          validator: (value) => value == null ? 'Please select a service' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _descriptionController,
                      labelText: 'Detailed Errand Instructions',
                      hintText: 'Please list items, specific house/unit numbers, contact person names, and any other helpful details...',
                      icon: Icons.list_alt,
                      maxLines: 8,
                      validator: (value) => value!.isEmpty ? 'Please enter detailed instructions' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _altContactController,
                      labelText: 'Alternative Contact Method (Optional)',
                      hintText: 'e.g. Another phone number, WhatsApp, or Signal',
                      icon: Icons.contact_phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add-ons & Extras',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<PricingAddon>>(
                stream: db.pricingAddonsRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final addons = snapshot.data!;
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: addons.map((addon) => CheckboxListTile(
                        title: Text(addon.addonName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text('+ Ksh ${addon.additionalCost}', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                        value: _selectedAddons.contains(addon),
                        activeColor: AppTheme.gold,
                        checkColor: Colors.black,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAddons.add(addon);
                            } else {
                              _selectedAddons.remove(addon);
                            }
                          });
                          _calculatePrice();
                        },
                      )).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Scheduling & Payment',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppTheme.gold),
                      title: Text(
                        _scheduledAt == null 
                          ? 'Schedule for a specific time? (Optional)' 
                          : 'Scheduled for: ${DateFormat.yMMMd().add_jm().format(_scheduledAt!)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.gold),
                        onPressed: _selectDateTime,
                      ),
                      onTap: _selectDateTime,
                    ),
                    const Divider(color: Colors.white10),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Option',
                        prefixIcon: Icon(Icons.payment, color: AppTheme.gold),
                      ),
                      dropdownColor: AppTheme.background,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'pay_later', child: Text('Pay Later (After Completion)')),
                        DropdownMenuItem(value: 'pay_now', child: Text('Pay Now (Priority Errand)')),
                      ],
                      onChanged: (val) => setState(() => _paymentType = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logistics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<List<LocationRate>>(
                      stream: db.locationRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        
                        final rates = snapshot.data!;
                        // Sort by category then area
                        rates.sort((a, b) {
                          int cmp = a.category.compareTo(b.category);
                          if (cmp != 0) return cmp;
                          return a.area.compareTo(b.area);
                        });

                        return DropdownButtonFormField<LocationRate>(
                          initialValue: _selectedLocation,
                          decoration: const InputDecoration(
                            labelText: 'Where is the errand taking place?',
                            prefixIcon: Icon(Icons.map, color: AppTheme.gold),
                          ),
                          dropdownColor: AppTheme.background,
                          style: const TextStyle(color: Colors.white),
                          items: rates.map((rate) {
                            return DropdownMenuItem(
                              value: rate,
                              child: Text('${rate.category} - ${rate.area} (Ksh ${rate.rate})', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value;
                            });
                            _calculatePrice();
                          },
                          validator: (value) => value == null ? 'Please select a location' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _pickupController,
                      labelText: 'Specific Pickup Point',
                      icon: Icons.location_on,
                      validator: (value) => value!.isEmpty ? 'Please enter pickup point' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _dropoffController,
                      labelText: 'Specific Drop-off Point',
                      icon: Icons.flag,
                      validator: (value) => value!.isEmpty ? 'Please enter drop-off point' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Include Stop-over?', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Additional Ksh $_stopOverFee', style: TextStyle(color: AppTheme.gold)),
                      value: _hasStopOver,
                      activeThumbColor: AppTheme.gold,
                      onChanged: (val) {
                        setState(() => _hasStopOver = val);
                        _calculatePrice();
                      },
                    ),
                    if (_hasStopOver)
                      _buildTextFormField(
                        controller: _stopOverController,
                        labelText: 'Stop-over Details',
                        icon: Icons.add_location,
                        validator: (value) => _hasStopOver && value!.isEmpty ? 'Please enter stop-over details' : null,
                      ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Bulky or Heavy Errand?', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Additional Ksh $_bulkyFee', style: TextStyle(color: AppTheme.gold)),
                      value: _isBulky,
                      activeColor: AppTheme.gold,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() => _isBulky = val ?? false);
                        _calculatePrice();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Promo Code',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _promoController,
                        labelText: 'Enter Code',
                        icon: Icons.confirmation_number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: const Text('APPLY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('ESTIMATED TOTAL', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      'Ksh ${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.gold, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    if (_selectedService != null) _buildPriceRow('Base Fee (${_selectedService!.name})', _selectedService!.flatRate),
                    if (_selectedLocation != null) _buildPriceRow('Location Fee (${_selectedLocation!.area})', _selectedLocation!.rate),
                    for (var addon in _selectedAddons) _buildPriceRow(addon.addonName, addon.additionalCost),
                    if (_currentDebt > 0) _buildPriceRow('Outstanding Debt', _currentDebt, color: Colors.redAccent),
                    if (_hasStopOver) _buildPriceRow('Stop-over Fee', _stopOverFee),
                    if (_isBulky) _buildPriceRow('Bulky Item Fee', _bulkyFee),
                    if (_appliedPromo != null) _buildPriceRow('Promo Discount', -_appliedPromo!.discountAmount, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitErrand,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('CONFIRM & POST ERRAND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14)),
          Text('${amount < 0 ? "-" : ""}Ksh ${amount.abs().toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: AppTheme.gold),
        alignLabelWithHint: maxLines > 1,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
    );
  }
}
