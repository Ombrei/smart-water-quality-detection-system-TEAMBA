import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../secondapp/dashboard_screen.dart';

class WaterQualityScreen extends StatefulWidget {
  const WaterQualityScreen({super.key});

  @override
  State<WaterQualityScreen> createState() => _WaterQualityScreenState();
}

class _WaterQualityScreenState extends State<WaterQualityScreen> with SingleTickerProviderStateMixin {
  int _selectedSensor = 0;
  bool _isHistorical = false;
  bool _isCalibrating = false;
  late TabController _tabController;

  final List<_SensorDetail> _sensors = [
    _SensorDetail(
      name: 'Turbidity', value: '0.5 NTU', status: 'Excellent', safeRange: '< 1 NTU',
      icon: Icons.water_drop_rounded, 
      color: const Color(0xFF0D47A1), // Deep Ocean Blue
      liveData: [FlSpot(0, 0.5), FlSpot(1, 0.52), FlSpot(2, 0.49), FlSpot(3, 0.55), FlSpot(4, 0.5), FlSpot(5, 0.51)],
      histData: [FlSpot(0, 0.4), FlSpot(1, 0.8), FlSpot(2, 0.5), FlSpot(3, 1.2), FlSpot(4, 0.7), FlSpot(5, 0.5)],
      description: 'Measures water clarity. Low turbidity means cleaner, clearer water.',
    ),
    _SensorDetail(
      name: 'TDS', value: '120 ppm', status: 'Good', safeRange: '< 500 ppm',
      icon: Icons.bar_chart_rounded, 
      color: const Color(0xFF00695C), // Dark Emerald/Teal Green
      liveData: [FlSpot(0, 118), FlSpot(1, 120), FlSpot(2, 122), FlSpot(3, 119), FlSpot(4, 121), FlSpot(5, 120)],
      histData: [FlSpot(0, 100), FlSpot(1, 145), FlSpot(2, 130), FlSpot(3, 160), FlSpot(4, 125), FlSpot(5, 120)],
      description: 'Total Dissolved Solids measures dissolved substances in water.',
    ),
    _SensorDetail(
      name: 'Temperature', value: '18 °C', status: 'Stable', safeRange: '10 – 25 °C',
      icon: Icons.thermostat_rounded, color: Color(0xFFFFB300),
      liveData: [FlSpot(0, 17.8), FlSpot(1, 18.0), FlSpot(2, 18.1), FlSpot(3, 18.0), FlSpot(4, 17.9), FlSpot(5, 18.0)],
      histData: [FlSpot(0, 17), FlSpot(1, 19), FlSpot(2, 18), FlSpot(3, 20), FlSpot(4, 18.5), FlSpot(5, 18)],
      description: 'Water temperature affects chemical reactions and filter efficiency.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sensors.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _selectedSensor = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runCalibration() async {
    setState(() => _isCalibrating = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isCalibrating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 10), Text('Sensors successfully calibrated!')]),
          backgroundColor: AppTheme.statusGood,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensor = _sensors[_selectedSensor];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Water Quality'),
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
      body: Column(
        children: [
          // Sensor tab bar
          Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: _sensors.map((s) => Tab(
                child: Row(
                  children: [Icon(s.icon, size: 16), const SizedBox(width: 6), Text(s.name)],
                ),
              )).toList(),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status card
                  _buildStatusCard(sensor),
                  const SizedBox(height: 14),

                  // Chart card
                  _buildChartCard(sensor),
                  const SizedBox(height: 14),

                  // Toggle
                  _buildToggleCard(),
                  const SizedBox(height: 14),

                  // Info card
                  _buildInfoCard(sensor),
                  const SizedBox(height: 20),

                  // Calibration button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCalibrating ? Colors.grey.shade300 : AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isCalibrating ? null : _runCalibration,
                      icon: _isCalibrating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.tune_rounded, size: 20),
                      label: Text(
                        _isCalibrating ? 'Calibrating...' : 'Run Sensor Calibration',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(_SensorDetail s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [s.color, s.color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: s.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(s.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(s.value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(s.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(height: 6),
              Text('Safe: ${s.safeRange}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(_SensorDetail s) {
    final data = _isHistorical ? s.histData : s.liveData;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.name} Trend',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isHistorical ? Colors.blue : AppTheme.statusGood).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isHistorical ? 'Last 24h' : '● Live',
                  style: TextStyle(
                    color: _isHistorical ? Colors.blue : AppTheme.statusGood,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: s.color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _isHistorical,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 4, color: s.color, strokeWidth: 2, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [s.color.withOpacity(0.15), s.color.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: SwitchListTile(
        title: const Text('Historical View', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        subtitle: Text(_isHistorical ? 'Showing last 24 hours' : 'Showing live data', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: _isHistorical,
        activeColor: AppTheme.primary,
        onChanged: (v) => setState(() => _isHistorical = v),
      ),
    );
  }

  Widget _buildInfoCard(_SensorDetail s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: s.color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(s.description, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5))),
        ],
      ),
    );
  }
}

class _SensorDetail {
  final String name, value, status, safeRange, description;
  final IconData icon;
  final Color color;
  final List<FlSpot> liveData, histData;

  const _SensorDetail({
    required this.name, required this.value, required this.status, required this.safeRange,
    required this.icon, required this.color, required this.liveData, required this.histData,
    required this.description,
  });
}
