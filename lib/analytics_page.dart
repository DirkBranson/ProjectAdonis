import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/workout_config.dart';

class WorkoutAnalyticsPage extends StatefulWidget {
  const WorkoutAnalyticsPage({super.key});

  @override
  State<WorkoutAnalyticsPage> createState() => _WorkoutAnalyticsPageState();
}

enum ChartMetric { primary, secondary }

class _WorkoutAnalyticsPageState extends State<WorkoutAnalyticsPage> {
  String _selectedCategory = 'Free Weights';
  String _selectedWorkout = 'Bench Press';
  ChartMetric _selectedMetric = ChartMetric.primary;
  
  double _currentBodyWeight = 70.0; 

  @override
  void initState() {
    super.initState();
    _fetchLatestBodyWeight();
  }

  Future<void> _fetchLatestBodyWeight() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user_metrics')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _currentBodyWeight = double.tryParse(snapshot.docs.first['value'].toString()) ?? 70.0;
      });
    }
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return "0:00";
    int mins = (seconds / 60).floor();
    int secs = (seconds % 60).toInt();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isBodyWeight = _selectedCategory == 'Body Weight';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: ['Body Weight', ...WorkoutConfig.categoryList]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedCategory = val!;
                    if (val != 'Body Weight') {
                      _selectedWorkout = WorkoutConfig.getWorkouts(val)[0];
                    }
                  }),
                ),
                if (!isBodyWeight) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedWorkout,
                    decoration: const InputDecoration(labelText: "Workout", border: OutlineInputBorder()),
                    items: WorkoutConfig.getWorkouts(_selectedCategory)
                        .map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                    onChanged: (val) => setState(() => _selectedWorkout = val!),
                  ),
                ],
              ],
            ),
          ),

          if (_selectedCategory == 'Calisthenics')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(
                "Math based on last Body Weight: ${_currentBodyWeight}kg",
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(isBodyWeight ? 'user_metrics' : 'workouts')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<FlSpot> spots = [];
                double minX = double.maxFinite;
                double maxX = -double.maxFinite;

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['timestamp'] == null) continue;

                  DateTime date = (data['timestamp'] as Timestamp).toDate();
                  double x = date.millisecondsSinceEpoch.toDouble();

                  if (isBodyWeight) {
                    double weight = double.tryParse(data['value'].toString()) ?? 0;
                    if (weight > 0) spots.add(FlSpot(x, weight));
                  } else {
                    List sets = data['sets'] ?? [];
                    for (var set in sets) {
                      if (set['category'] == _selectedCategory && set['workout'] == _selectedWorkout) {
                        double v1 = double.tryParse(set['val1']?.toString() ?? '0') ?? 0;
                        double v2 = double.tryParse(set['val2']?.toString() ?? '0') ?? 0;

                        double yValue = 0;
                        double weightToUse = (_selectedCategory == 'Calisthenics') 
                            ? (v1 + _currentBodyWeight) 
                            : v1;

                        // --- INTEGRATED LOGIC START ---
                        switch (_selectedCategory) {
                          case 'Free Weights':
                          case 'Machines': // Added Machines
                          case 'Calisthenics':
                            yValue = (_selectedMetric == ChartMetric.primary) ? (weightToUse * v2) : weightToUse;
                            break;
                          case 'Sports': // Added Sports
                            yValue = (_selectedMetric == ChartMetric.primary) ? v1 : v2;
                            break;
                          case 'Track':
                          case 'Distance Running':
                          case 'Eccentrics':
                            yValue = (_selectedMetric == ChartMetric.primary) ? v1 : v2;
                            break;
                          case 'Isometrics':
                          case 'Flexibility':
                            yValue = v1;
                            break;
                        }
                        // --- INTEGRATED LOGIC END ---

                        if (yValue > 0) spots.add(FlSpot(x, yValue));
                      }
                    }
                  }
                  if (spots.isNotEmpty) {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                  }
                }

                if (spots.isEmpty) return Center(child: Text("No records for $_selectedWorkout"));
                if (minX == maxX) { maxX += 86400000; minX -= 86400000; }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 30, 10),
                  child: LineChart(
                    LineChartData(
                      minX: minX, maxX: maxX,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: isBodyWeight ? Colors.orange : Colors.indigo,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true, 
                            color: (isBodyWeight ? Colors.orange : Colors.indigo).withOpacity(0.1)
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              // Added Sports and Machines to the "NOT Time" logic
                              bool isTimeMetric = (_selectedCategory == 'Track' && _selectedMetric == ChartMetric.secondary) ||
                                                 (_selectedCategory == 'Isometrics') ||
                                                 (_selectedCategory == 'Flexibility' && _selectedMetric == ChartMetric.primary) ||
                                                 (_selectedCategory == 'Eccentrics' && _selectedMetric == ChartMetric.primary);
                              
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  isTimeMetric ? _formatDuration(value) : value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                          )
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: (maxX - minX) / 4,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (!isBodyWeight)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<ChartMetric>(
                segments: const [
                  ButtonSegment(value: ChartMetric.primary, label: Text('Primary Metric')),
                  ButtonSegment(value: ChartMetric.secondary, label: Text('Secondary Metric')),
                ],
                selected: {_selectedMetric},
                onSelectionChanged: (val) => setState(() => _selectedMetric = val.first),
              ),
            ),
        ],
      ),
    );
  }
}