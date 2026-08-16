import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';

class FirebaseHistoryScreen extends StatefulWidget {
  const FirebaseHistoryScreen({super.key});

  @override
  State<FirebaseHistoryScreen> createState() =>
      _FirebaseHistoryScreenState();
}

class _FirebaseHistoryScreenState
    extends State<FirebaseHistoryScreen> {
  // ── Filters ──
  int? _selectedNode; // null = all nodes
  String? _selectedStatus; // null = all status
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<int> _nodeOptions = [1, 3];
  final List<String> _statusOptions = [
    'Good',
    'Moderate',
    'Unhealthy for Sensitive Groups',
    'Unhealthy',
    'DANGER',
  ];

  bool get _hasActiveFilters =>
      _selectedNode != null ||
      _selectedStatus != null ||
      _fromDate != null ||
      _toDate != null;

  // ── Build Firestore Query ──
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore
        .instance
        .collection('sensor_logs')
        .orderBy('timestamp', descending: true)
        .limit(200);

    if (_selectedNode != null) {
      query = query.where('node', isEqualTo: _selectedNode);
    }

    if (_selectedStatus != null) {
      query = query.where('prediction',
          isEqualTo: _selectedStatus);
    }

    if (_fromDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(_fromDate!));
    }

    if (_toDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(
              _toDate!.add(const Duration(days: 1))));
    }

    return query;
  }

  Color _predictionColor(AppColors c, String prediction) {
    switch (prediction.toUpperCase()) {
      case 'DANGER':
      case 'UNHEALTHY':
        return c.critical;
      case 'MODERATE':
      case 'UNHEALTHY FOR SENSITIVE GROUPS':
        return c.danger;
      default:
        return c.safe;
    }
  }

  // ── Date Picker ──
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Reset Filters',
              onPressed: () {
                setState(() {
                  _selectedNode = null;
                  _selectedStatus = null;
                  _fromDate = null;
                  _toDate = null;
                });
              },
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Panel ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              children: [
                // Node + Status filter
                Row(
                  children: [
                    Expanded(
                      child:
                          DropdownButtonFormField<int?>(
                        value: _selectedNode,
                        decoration:
                            _inputDecoration(c, 'Node'),
                        dropdownColor: c.surface,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13.5,
                        ),
                        icon: Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          color: c.textMuted,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All Nodes',
                              style: TextStyle(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          ..._nodeOptions.map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text(
                                'Node $n',
                                style: TextStyle(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(
                            () => _selectedNode = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          DropdownButtonFormField<String?>(
                        value: _selectedStatus,
                        decoration:
                            _inputDecoration(c, 'Status'),
                        dropdownColor: c.surface,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13.5,
                        ),
                        icon: Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          color: c.textMuted,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All Status',
                              style: TextStyle(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          ..._statusOptions.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: c.textPrimary,
                                ),
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(
                            () => _selectedStatus = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Date filter
                Row(
                  children: [
                    Expanded(
                      child: _dateButton(
                        c,
                        label: _fromDate == null
                            ? 'From Date'
                            : 'From: ${_fromDate!.day}/${_fromDate!.month}',
                        active: _fromDate != null,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateButton(
                        c,
                        label: _toDate == null
                            ? 'To Date'
                            : 'To: ${_toDate!.day}/${_toDate!.month}',
                        active: _toDate != null,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Data Stream ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: c.accent,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.critical,
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: c.border),
                          ),
                          child: Icon(
                            Icons.cloud_off_rounded,
                            color: c.textMuted,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data found',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting the filters',
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    // ── Analytics Chart ──
                    SliverToBoxAdapter(
                      child: _buildChart(c, docs),
                    ),

                    // ── Stats Summary ──
                    SliverToBoxAdapter(
                      child: _buildStats(c, docs),
                    ),

                    // ── History List ──
                    SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
                          final d = doc.data()
                              as Map<String, dynamic>;
                          return _historyCard(c, d);
                        },
                        childCount: docs.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Danger vs Safe Chart ──
  Widget _buildChart(
      AppColors c, List<QueryDocumentSnapshot> docs) {
    // Count per prediction type
    final counts = <String, int>{};

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final prediction =
          (d['prediction'] as String? ?? 'Unknown');
      counts[prediction] = (counts[prediction] ?? 0) + 1;
    }

    if (counts.isEmpty) return const SizedBox();

    final total = counts.values.fold(0, (a, b) => a + b);

    final sections = counts.entries.map((e) {
      final color = _predictionColor(c, e.key);
      final percentage = (e.value / total * 100);

      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                size: 16,
                color: c.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'AIR QUALITY DISTRIBUTION',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                // Legend
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: counts.entries.map((e) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _predictionColor(
                                  c, e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${e.key} (${e.value})',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Danger Timeline Bar Chart ──
          _buildDangerTimeline(c, docs),
        ],
      ),
    );
  }

  // ── Danger vs Safe Timeline ──
  Widget _buildDangerTimeline(
      AppColors c, List<QueryDocumentSnapshot> docs) {
    // Group by hour — last readings
    final Map<String, Map<String, int>> hourly = {};

    for (final doc in docs.take(50)) {
      final d = doc.data() as Map<String, dynamic>;
      final ts = (d['timestamp'] as Timestamp?)?.toDate();
      if (ts == null) continue;

      final key = '${ts.day}/${ts.month} ${ts.hour}:00';

      hourly.putIfAbsent(
          key, () => {'danger': 0, 'safe': 0});

      final prediction =
          (d['prediction'] as String? ?? '')
              .toUpperCase();

      if (prediction == 'DANGER' ||
          prediction == 'UNHEALTHY' ||
          prediction == 'CRITICAL') {
        hourly[key]!['danger'] =
            (hourly[key]!['danger'] ?? 0) + 1;
      } else {
        hourly[key]!['safe'] =
            (hourly[key]!['safe'] ?? 0) + 1;
      }
    }

    if (hourly.isEmpty) return const SizedBox();

    final keys = hourly.keys.toList();
    final barGroups = keys.asMap().entries.map((e) {
      final danger =
          (hourly[e.value]!['danger'] ?? 0).toDouble();
      final safe =
          (hourly[e.value]!['safe'] ?? 0).toDouble();

      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: safe,
            color: c.safe,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: danger,
            color: c.critical,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 16,
              color: c.accent,
            ),
            const SizedBox(width: 8),
            Text(
              'SAFE VS DANGER TIMELINE',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(c, c.safe, 'Safe'),
            const SizedBox(width: 12),
            _legendDot(c, c.critical, 'Danger'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= keys.length) {
                        return const SizedBox();
                      }
                      final label = keys[i]
                          .split(' ')
                          .last; // just time
                      return Text(
                        label,
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 8,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Summary ──
  Widget _buildStats(
      AppColors c, List<QueryDocumentSnapshot> docs) {
    int dangerCount = 0;
    int safeCount = 0;
    int vibrationCount = 0;

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final prediction =
          (d['prediction'] as String? ?? '')
              .toUpperCase();
      final vibration =
          (d['vibration'] as String? ?? '')
              .toUpperCase();

      if (prediction == 'DANGER' ||
          prediction == 'UNHEALTHY' ||
          prediction == 'CRITICAL') {
        dangerCount++;
      } else {
        safeCount++;
      }

      if (vibration == 'VIBRATING') vibrationCount++;
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(
              c, 'Total', '${docs.length}', c.accent),
          const SizedBox(width: 8),
          _statCard(
              c, 'Danger', '$dangerCount', c.critical),
          const SizedBox(width: 8),
          _statCard(c, 'Safe', '$safeCount', c.safe),
          const SizedBox(width: 8),
          _statCard(c, 'Vibration', '$vibrationCount',
              c.purple),
        ],
      ),
    );
  }

  // ── History Card ──
  Widget _historyCard(
      AppColors c, Map<String, dynamic> d) {
    final prediction =
        d['prediction'] as String? ?? 'Unknown';
    final node = d['node'] as int? ?? 0;
    final ts =
        (d['timestamp'] as Timestamp?)?.toDate();
    final color = _predictionColor(c, prediction);
    final vibration =
        (d['vibration'] as String? ?? 'STABLE')
            .toUpperCase();
    final confidence = d['confidence'] as num?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Node $node',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vibration ==
                        'VIBRATING') ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.vibration_rounded,
                        size: 12,
                        color: c.danger,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  prediction,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (confidence != null)
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Timestamp
          if (ts != null)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ts.day}/${ts.month}',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──
  Widget _statCard(
      AppColors c, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(
    AppColors c, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? c.accent.withOpacity(0.08)
                : c.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? c.accent.withOpacity(0.5)
                  : c.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: active ? c.accent : c.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? c.accent
                        : c.textSecondary,
                    fontSize: 12.5,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(
      AppColors c, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      AppColors c, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textMuted),
      filled: true,
      fillColor: c.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
    );
  }
}
