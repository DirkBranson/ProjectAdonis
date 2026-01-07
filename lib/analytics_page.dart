import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// The [WorkoutAnalyticsPage] is a stateful widget that visualizes 
/// fitness progress data fetched from Firebase Firestore.
/// 
/// It uses a [LineChart] to show weight progression over time and
/// allows users to filter the data by specific exercises.
class WorkoutAnalyticsPage extends StatefulWidget {
  const WorkoutAnalyticsPage({super.key});

  @override
  State<WorkoutAnalyticsPage> createState() => _WorkoutAnalyticsPageState();
}

class _WorkoutAnalyticsPageState extends State<WorkoutAnalyticsPage> {
  /// [_selectedFilter] tracks the currently selected exercise.
  /// This is used to filter out data from other exercises so the graph
  /// only compares "like-for-like" data points.
  String _selectedFilter = 'Bench Press';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        // Optional: Adding a soft color to distinguish this screen from the logger
        backgroundColor: Colors.indigo.shade50,
      ),
      body: Column(
        children: [
          // --- SECTION 1: EXERCISE FILTER DROPDOWN ---
          // We wrap this in Padding to ensure it doesn't touch the screen edges.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(
                labelText: "Filter by Exercise",
                border: OutlineInputBorder(), // Adds a clean border around the filter
              ),
              // List of options available in the dropdown
              items: ['Bench Press', 'Squat', 'Muscle Up', 'Dips', 'Pull Ups']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              // When a user selects a new exercise, we update the state
              onChanged: (val) {
                setState(() {
                  _selectedFilter = val!;
                });
              },
            ),
          ),

          // --- SECTION 2: THE REAL-TIME GRAPH ---
          // Expanded ensures the graph takes up all remaining vertical space.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // .snapshots() creates a "live wire" to the 'workouts' collection.
              // We order by timestamp so the line connects dots in the right order.
              stream: FirebaseFirestore.instance
                  .collection('workouts')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                // Scenario A: Still waiting for the first signal from the database
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Scenario B: We have data, now we must transform it for the graph
                List<FlSpot> spots = [];
                
                // We loop through every "Workout Session" document in Firestore
                for (var doc in snapshot.data!.docs) {
                  // Cast the generic document data into a usable Map
                  var data = doc.data() as Map<String, dynamic>;
                  // Extract the list of sets; defaults to an empty list if null
                  List sets = data['sets'] ?? [];
                  
                  // Now we look inside the workout for specific sets matching our filter
                  for (var set in sets) {
                    if (set['exercise'] == _selectedFilter) {
                      // 1. Convert the ISO string back into a Dart DateTime object
                      DateTime date = DateTime.parse(set['time_logged']);
                      // 2. Safely parse the weight string into a double
                      double weight = double.tryParse(set['weight'].toString()) ?? 0;
                      
                      // 3. Map the data: X is the date (as a number), Y is the weight.
                      // We use millisecondsSinceEpoch because graphs only understand numbers.
                      spots.add(FlSpot(
                        date.millisecondsSinceEpoch.toDouble(), 
                        weight
                      ));
                    }
                  }
                }

                // Scenario C: The collection exists, but no sets match the current filter
                if (spots.isEmpty) {
                  return Center(
                    child: Text("No records for $_selectedFilter yet."),
                  );
                }

                // Scenario D: Success! We have points to plot.
                return Padding(
                  padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false, // Straight lines make strength plateaus easier to spot
                          color: Colors.indigo,
                          barWidth: 4,
                          // Shows a small circle on every recorded session
                          dotData: const FlDotData(show: true),
                          // Optional: Adds a subtle blue glow under the line
                          belowBarData: BarAreaData(
                            show: true, 
                            color: Colors.indigo.withOpacity(0.1)
                          ),
                        ),
                      ],
                      // Titles define the labels on the X and Y axis
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30, // Space for the date labels
                            getTitlesWidget: (value, meta) {
                              // We turn the large millisecond number back into a Date
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              // Format it to "Jan 06" so it fits on screen
                              return Text(
                                DateFormat('MMM dd').format(date), 
                                style: const TextStyle(fontSize: 10, color: Colors.grey)
                              );
                            },
                          ),
                        ),
                      ),
                      // Removes the default grid lines for a cleaner "Adonis" look
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
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