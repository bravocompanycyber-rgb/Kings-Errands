import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Help & About')),
      body: FutureBuilder<AppUser?>(
        future: auth.getCurrentUserData(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final role = userSnapshot.data?.role ?? 'customer';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutSection(context),
                const SizedBox(height: 32),
                Text('Frequently Asked Questions', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                StreamBuilder<List<FAQ>>(
                  stream: db.streamFAQs(role),
                  builder: (context, faqSnapshot) {
                    if (!faqSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final faqs = faqSnapshot.data!;
                    if (faqs.isEmpty) return const Text('No FAQs available for your role.', style: TextStyle(color: Colors.white54));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        final faq = faqs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(8),
                            child: ExpansionTile(
                              title: Text(faq.question, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(faq.answer, style: const TextStyle(color: Colors.white70)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildHolidaysSection(context),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Kings Errands™. All Rights Reserved.',
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', height: 80),
          const SizedBox(height: 16),
          const Text(
            'Kings Errands™',
            style: TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Empowering Kenyan efficiency through reliable errand services. We bridge the gap between your needs and the best runners in the kingdom.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaysSection(BuildContext context) {
    // Current Nairobi Time
    final nowUtc = DateTime.now().toUtc();
    final nairobiTime = nowUtc.add(const Duration(hours: 3));
    
    final holidays = [
      {'name': 'New Year\'s Day', 'date': 'Jan 1'},
      {'name': 'Good Friday', 'date': 'Varies'},
      {'name': 'Easter Monday', 'date': 'Varies'},
      {'name': 'Eid al-Fitr', 'date': 'Varies'},
      {'name': 'Labour Day', 'date': 'May 1'},
      {'name': 'Madaraka Day', 'date': 'Jun 1'},
      {'name': 'Utamaduni Day', 'date': 'Oct 10'},
      {'name': 'Mashujaa Day', 'date': 'Oct 20'},
      {'name': 'Jamhuri Day', 'date': 'Dec 12'},
      {'name': 'Christmas Day', 'date': 'Dec 25'},
      {'name': 'Boxing Day', 'date': 'Dec 26'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kenyan Operating Hours', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Current Nairobi Time: ${nairobiTime.hour}:${nairobiTime.minute.toString().padLeft(2, '0')} (UTC+3)', style: const TextStyle(color: AppTheme.gold)),
        const SizedBox(height: 16),
        const Text('National Holidays (Service may be limited):', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: holidays.map((h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text('${h['name']} (${h['date']})', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          )).toList(),
        ),
      ],
    );
  }
}
