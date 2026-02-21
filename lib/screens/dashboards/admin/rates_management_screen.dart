import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class RatesManagementScreen extends StatefulWidget {
  const RatesManagementScreen({super.key});

  @override
  State<RatesManagementScreen> createState() => _RatesManagementScreenState();
}

class _RatesManagementScreenState extends State<RatesManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _areaController = TextEditingController();
  final _categoryController = TextEditingController();
  final _rateController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _addonNameController = TextEditingController();
  final _addonFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showLocationDialog({LocationRate? rate}) {
    if (rate != null) {
      _areaController.text = rate.area;
      _categoryController.text = rate.category;
      _rateController.text = rate.rate.toString();
    } else {
      _areaController.clear();
      _categoryController.clear();
      _rateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(rate == null ? 'Add Location' : 'Edit Location', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _areaController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Area (e.g. Buruburu)', labelStyle: TextStyle(color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category (e.g. Jogoo Road)', labelStyle: TextStyle(color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Rate (Ksh)', labelStyle: TextStyle(color: AppTheme.gold)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              final nav = Navigator.of(context);
              final area = _areaController.text.trim();
              final category = _categoryController.text.trim();
              final fee = double.tryParse(_rateController.text) ?? 0.0;

              if (area.isEmpty || category.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                return;
              }

              if (rate == null) {
                await db.addLocationRate(area, category, fee);
              } else {
                await db.updateLocationRate(rate.id, area, category, fee);
              }
              
              if (mounted) {
                nav.pop();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showServiceDialog({ServiceRate? rate}) {
    if (rate != null) {
      _serviceNameController.text = rate.name;
      _serviceFeeController.text = rate.flatRate.toString();
    } else {
      _serviceNameController.clear();
      _serviceFeeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(rate == null ? 'Add Service' : 'Edit Service', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Service Name (e.g. Cleaning)', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serviceFeeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Flat Rate (Ksh)', labelStyle: TextStyle(color: AppTheme.gold)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              final nav = Navigator.of(context);
              final name = _serviceNameController.text;
              final fee = double.tryParse(_serviceFeeController.text) ?? 0.0;

              if (rate == null) {
                await db.serviceRatesRef.add(ServiceRate(id: '', name: name, flatRate: fee));
              } else {
                await db.serviceRatesRef.doc(rate.id).update({'serviceName': name, 'flatRate': fee});
              }
              
              if (mounted) {
                nav.pop();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showAddonDialog({PricingAddon? addon}) {
    if (addon != null) {
      _addonNameController.text = addon.addonName;
      _addonFeeController.text = addon.additionalCost.toString();
    } else {
      _addonNameController.clear();
      _addonFeeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(addon == null ? 'Add Add-on' : 'Edit Add-on', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addonNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Add-on Name (e.g. Gift Wrapping)', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addonFeeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Additional Cost (Ksh)', labelStyle: TextStyle(color: AppTheme.gold)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              final nav = Navigator.of(context);
              final name = _addonNameController.text;
              final fee = double.tryParse(_addonFeeController.text) ?? 0.0;

              if (addon == null) {
                await db.pricingAddonsRef.add(PricingAddon(id: '', addonName: name, additionalCost: fee));
              } else {
                await db.pricingAddonsRef.doc(addon.id).update({'addonName': name, 'additionalCost': fee});
              }
              
              if (mounted) {
                nav.pop();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Locations'),
            Tab(text: 'Services'),
            Tab(text: 'Add-ons'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocationList(),
          _buildServiceList(),
          _buildAddonList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showLocationDialog();
          } else if (_tabController.index == 1) {
            _showServiceDialog();
          } else {
            _showAddonDialog();
          }
        },
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildLocationList() {
    final db = context.read<DatabaseService>();
    return StreamBuilder<List<LocationRate>>(
      stream: db.locationRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final rates = snapshot.data!;
        
        // Group by category
        final grouped = <String, List<LocationRate>>{};
        for (var r in rates) {
          grouped.putIfAbsent(r.category, () => []).add(r);
        }

        final categories = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, catIndex) {
            final category = categories[catIndex];
            final catRates = grouped[category]!..sort((a, b) => a.area.compareTo(b.area));
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...catRates.map((rate) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(4),
                    child: ListTile(
                      title: Text(rate.area, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Rate: Ksh ${rate.rate}', style: const TextStyle(color: Colors.white70)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showLocationDialog(rate: rate)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => db.deleteLocationRate(rate.id)),
                        ],
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildServiceList() {
    final db = context.read<DatabaseService>();
    return StreamBuilder<List<ServiceRate>>(
      stream: db.serviceRatesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final rates = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rates.length,
          itemBuilder: (context, index) {
            final rate = rates[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(rate.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Flat Rate: Ksh ${rate.flatRate}', style: const TextStyle(color: AppTheme.gold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showServiceDialog(rate: rate)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => db.serviceRatesRef.doc(rate.id).delete()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddonList() {
    final db = context.read<DatabaseService>();
    return StreamBuilder<List<PricingAddon>>(
      stream: db.pricingAddonsRef.snapshots().map((s) => s.docs.map((d) => d.data()).where((a) => !a.addonName.startsWith('PROMO-')).toList()), // Exclude PROMO codes which are also in this collection
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final addons = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addons.length,
          itemBuilder: (context, index) {
            final addon = addons[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(addon.addonName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Cost: Ksh ${addon.additionalCost}', style: const TextStyle(color: AppTheme.gold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddonDialog(addon: addon)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => db.pricingAddonsRef.doc(addon.id).delete()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
