import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../secondapp/dashboard_screen.dart';

class FilterManagementScreen extends StatefulWidget {
  const FilterManagementScreen({super.key});

  @override
  State<FilterManagementScreen> createState() => _FilterManagementScreenState();
}

class _FilterManagementScreenState extends State<FilterManagementScreen> {
  final List<_FilterItem> _filters = [
    _FilterItem(name: 'Sediment Filter', life: 0.85, icon: Icons.hourglass_bottom_rounded, color: Color(0xFFFFB300), description: 'Removes dirt, rust, and larger particles'),
    _FilterItem(name: 'Carbon Filter', life: 0.90, icon: Icons.layers_rounded, color: Color(0xFF29B6F6), description: 'Removes chlorine, odors, and chemicals'),
    _FilterItem(name: 'Post-Filter', life: 0.92, icon: Icons.verified_user_rounded, color: Color(0xFF4CAF50), description: 'Final polish stage for taste and clarity'),
  ];

  void _simulateUsage() {
    setState(() {
      for (final f in _filters) {
        if (f.life > 0.05) f.life -= 0.05;
      }
    });
  }

  void _handleOrder() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.statusGood.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, color: AppTheme.statusGood, size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Order Confirmed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Your replacement cartridges are on the way.\nWould you like to reset the filter status?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() { for (final f in _filters) f.life = 1.0; });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reset Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallHealth = _filters.fold(0.0, (sum, f) => sum + f.life) / _filters.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Filter Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
         onPressed: () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If there's no history, push them back to the Dashboard instead
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const DashboardScreen())
      );
    }
  },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overall health card
            _buildHealthCard(overallHealth),
            const SizedBox(height: 16),

            // Section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cartridge Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                TextButton.icon(
                  onPressed: _simulateUsage,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                  label: const Text('Simulate', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter cards
            ..._filters.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFilterCard(f),
            )),

            const SizedBox(height: 8),

            // Maintenance tip
            _buildTipCard(),
            const SizedBox(height: 24),

            // Order button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _handleOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.local_shipping_rounded, size: 20),
                label: const Text('Order Replacements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(double health) {
    final color = health > 0.7 ? AppTheme.statusGood : health > 0.4 ? AppTheme.statusWarn : AppTheme.statusDanger;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: health,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('${(health * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Filter Health', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                health > 0.7 ? 'All filters running well' : health > 0.4 ? 'Some filters need attention' : 'Replacement recommended!',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.schedule_rounded, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text('Next check: ~${(health * 30).toInt()} days', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(_FilterItem f) {
    final color = f.life > 0.6 ? f.color : f.life > 0.3 ? AppTheme.statusWarn : AppTheme.statusDanger;
    final monthsLeft = (f.life * 9).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(f.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(f.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(f.life * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                  Text('~$monthsLeft mo left', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              height: 8,
              child: LinearProgressIndicator(
                value: f.life,
                backgroundColor: AppTheme.background,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Replace filters before they reach 20% to maintain optimal water quality.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterItem {
  final String name, description;
  double life;
  final IconData icon;
  final Color color;
  _FilterItem({required this.name, required this.life, required this.icon, required this.color, required this.description});
}
