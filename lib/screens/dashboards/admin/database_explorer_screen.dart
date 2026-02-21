import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import 'dart:convert';

class DatabaseExplorerScreen extends StatefulWidget {
  const DatabaseExplorerScreen({super.key});

  @override
  State<DatabaseExplorerScreen> createState() => _DatabaseExplorerScreenState();
}

class _DatabaseExplorerScreenState extends State<DatabaseExplorerScreen> {
  final List<String> _collections = [
    'audit_logs',
    'errands',
    'faq',
    'location_rates',
    'notifications',
    'pricing_addons',
    'reviews',
    'runner_status',
    'service rates',
    'statistics',
    'system_configs',
    'transactions',
    'users',
    'wallets'
  ];

  String? _selectedCollection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_selectedCollection ?? 'Database Explorer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _selectedCollection != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCollection = null),
              )
            : null,
      ),
      body: _selectedCollection == null
          ? _buildCollectionList()
          : _buildDocumentList(_selectedCollection!),
    );
  }

  Widget _buildCollectionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              title: Text(collection, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.gold),
              onTap: () => setState(() => _selectedCollection = collection),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentList(String collectionName) {
    final db = context.read<DatabaseService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.streamCollection(collectionName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No documents found.', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: ListTile(
                  title: Text(doc.id, style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                  subtitle: Text(
                    data.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _editDocument(collectionName, doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteDocument(collectionName, doc.id),
                      ),
                    ],
                  ),
                  onTap: () => _viewDocument(doc.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewDocument(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text('Document: $id', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(data),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _editDocument(String collectionName, String id, Map<String, dynamic> data) {
    final controller = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(data));
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text('Edit: $id', style: const TextStyle(color: AppTheme.gold)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 20,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter valid JSON',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              try {
                final Map<String, dynamic> newData = json.decode(controller.text);
                final db = dialogContext.read<DatabaseService>();
                await db.updateDocument(collectionName, id, newData);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document updated')));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Invalid JSON: $e')));
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(String collectionName, String id) async {
    final db = context.read<DatabaseService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Delete Document?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete $id from $collectionName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await db.deleteDocument(collectionName, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted')));
      }
    }
  }
}
