import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class FAQManagementScreen extends StatefulWidget {
  const FAQManagementScreen({super.key});

  @override
  State<FAQManagementScreen> createState() => _FAQManagementScreenState();
}

class _FAQManagementScreenState extends State<FAQManagementScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String _selectedCategory = 'customer';

  void _showFAQDialog({FAQ? faq}) {
    if (faq != null) {
      _questionController.text = faq.question;
      _answerController.text = faq.answer;
      _selectedCategory = faq.category;
    } else {
      _questionController.clear();
      _answerController.clear();
      _selectedCategory = 'customer';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(faq == null ? 'Add FAQ' : 'Edit FAQ', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppTheme.background,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Target Category'),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'runner', child: Text('Runner')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Question'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              if (faq == null) {
                await db.addFAQ(_questionController.text, _answerController.text, _selectedCategory);
              } else {
                await db.updateFAQ(faq.id, _questionController.text, _answerController.text, _selectedCategory);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ saved.')));
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage FAQs')),
      body: StreamBuilder<List<FAQ>>(
        stream: db.faqsRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final faqs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(faq.question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Category: ${faq.category.toUpperCase()}', style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showFAQDialog(faq: faq)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => db.deleteFAQ(faq.id)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFAQDialog(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
