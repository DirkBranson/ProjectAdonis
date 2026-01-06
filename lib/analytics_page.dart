import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Helps turn numbers back into "Jan 06"

class WorkoutAnalyticsPage extends StatefulWidget {
  const WorkoutAnalyticsPage({super.key});

  @override
  State<WorkoutAnalyticsPage> createState() => _WorkoutAnalyticsPageState();
}

class _WorkoutAnalyticsPageState extends State<WorkoutAnalyticsPage> {
  String _selectedFilter = 'Bench Press'; // Like-for-like filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracking')),
      body: Column(
        children: [
          // 1. Exercise Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(labelText: "Filter by Exercise"),
              items: ['Bench Press', 'Squat', 'Muscle Up', 'Dips', 'Pull Ups']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFilter = val!),
            ),
          ),

          // 2. The Dynamic Graph
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Only fetch data that matches our exercise filter
              stream: FirebaseFirestore.instance
                  .collection('workouts')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<FlSpot> spots = [];
                
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  List sets = data['sets'] ?? [];
                  
                  // Filter the nested sets for our selected exercise
                  for (var set in sets) {
                    if (set['exercise'] == _selectedFilter) {
                      DateTime date = DateTime.parse(set['time_logged']);
                      double weight = double.tryParse(set['weight'].toString()) ?? 0;
                      
                      // Convert Date to a number (milliseconds) for the X-Axis
                      spots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), weight));
                    }
                  }
                }

                if (spots.isEmpty) return const Center(child: Text("No data for this exercise yet."));

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false, // Straight lines show raw progress better
                          color: Colors.indigo,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        // Turn the "millisecond numbers" back into readable dates
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}