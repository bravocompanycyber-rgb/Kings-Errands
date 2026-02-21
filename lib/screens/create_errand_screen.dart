import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/app_models.dart';

class CreateErrandScreen extends StatefulWidget {
  const CreateErrandScreen({super.key});

  @override
  State<CreateErrandScreen> createState() => _CreateErrandScreenState();
}

class _CreateErrandScreenState extends State<CreateErrandScreen> {
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  
  LocationRate? _selectedLocation;
  ServiceRate? _selectedService;
  bool _isLoading = false;

  double get _totalPrice {
    if (_selectedLocation == null || _selectedService == null) return 0.0;
    return _selectedService!.flatRate + _selectedLocation!.rate;
  }

  void _createErrand() async {
    if (_selectedLocation == null || 
        _selectedService == null || 
        _descriptionController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _deliveryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = context.read<User?>();
    final db = context.read<DatabaseService>();

    try {
      await db.postErrand(
        customerId: user?.uid ?? '',
        title: _titleController.text,
        description: _descriptionController.text.trim(),
        pickupLocation: _pickupController.text,
        deliveryLocation: _deliveryController.text,
        estimatedPrice: _totalPrice,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errand created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('CREATE ERRAND')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title (e.g. Buy Groceries)', labelStyle: TextStyle(color: AppTheme.gold)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text('Select Service Type', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<List<ServiceRate>>(
                    stream: db.serviceRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
                    builder: (context, snapshot) {
                      final services = snapshot.data ?? [];
                      return DropdownButtonFormField<ServiceRate>(
                        dropdownColor: AppTheme.background,
                        initialValue: _selectedService,
                        items: services.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (Ksh${s.flatRate})', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setState(() {
                           _selectedService = val;
                        }),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Location Area', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<List<LocationRate>>(
                    stream: db.locationRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
                    builder: (context, snapshot) {
                      final locations = snapshot.data ?? [];
                      // Sort by category then area
                      locations.sort((a, b) {
                        int cmp = a.category.compareTo(b.category);
                        if (cmp != 0) return cmp;
                        return a.area.compareTo(b.area);
                      });

                      return DropdownButtonFormField<LocationRate>(
                        dropdownColor: AppTheme.background,
                        initialValue: _selectedLocation,
                        items: locations.map((l) => DropdownMenuItem(
                          value: l,
                          child: Text('${l.category} - ${l.area} (+Ksh${l.rate})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        )).toList(),
                        onChanged: (val) => setState(() {
                           _selectedLocation = val;
                        }),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(labelText: 'Pickup Point', labelStyle: TextStyle(color: AppTheme.gold)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _deliveryController,
                    decoration: const InputDecoration(labelText: 'Delivery Point', labelStyle: TextStyle(color: AppTheme.gold)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('Detailed Errand Instructions', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Please list items, specific house/unit numbers, contact person names, and any other helpful details...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Cost:', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      Text(
                        'Ksh${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createErrand,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppTheme.gold)
                          : const Text('BROADCAST ERRAND', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
