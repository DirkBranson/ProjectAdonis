import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // This links your generated Firebase keys
import 'analytics_page.dart';

void main() async {
  // 1. Initialize the Flutter engine and Firebase bridge
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdonisApp());
}

class AdonisApp extends StatelessWidget {
  const AdonisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Adonis',
      // We are using a unified theme so the app looks professional
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const WorkoutSessionPage(),
    );
  }
}

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  // --- DATA STORAGE ---
  // This list holds your sets locally in the phone's RAM until you hit "Submit"
  final List<Map<String, dynamic>> _currentSessionSets = [];
  
  // --- CONTROLLERS ---
  // Controllers "read" the text typed into the boxes
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  
  String _selectedExercise = 'Bench Press';
  DateTime? _lastSetTimestamp; // Hidden clock to track your rest periods

  // --- LOGIC: LOGGING A SET LOCALLY ---
  void _logSet() {
    final now = DateTime.now();
    
    // Calculate the difference between this click and the previous one
    String restTime = "First Set";
    if (_lastSetTimestamp != null) {
      final difference = now.difference(_lastSetTimestamp!);
      // Format the duration into a readable string
      restTime = "${difference.inMinutes}m ${difference.inSeconds % 60}s";
    }

    // Check if inputs are empty to avoid saving "ghost" data
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight and reps!')),
      );
      return;
    }

    setState(() {
      // Add a "Set Map" to our local list
      _currentSessionSets.add({
        'exercise': _selectedExercise,
        'weight': _weightController.text,
        'reps': _repsController.text,
        'rest_after_prev': restTime,
        'time_logged': now.toIso8601String(),
      });
      
      // Reset the timer for the next set
      _lastSetTimestamp = now;
    });

    // Clear the input boxes so you don't have to delete the text manually
    _weightController.clear();
    _repsController.clear();
  }

  // --- LOGIC: SUBMITTING TO FIREBASE ---
  void _submitWorkout() async {
    if (_currentSessionSets.isEmpty) return;

    try {
      // This sends the entire session as ONE document to the "workouts" collection
      await FirebaseFirestore.instance.collection('workouts').add({
        'date_label': DateTime.now().toString().split(' ')[0], // e.g., 2024-01-06
        'total_sets': _currentSessionSets.length,
        'sets': _currentSessionSets, // This is our nested list of maps
        'timestamp': FieldValue.serverTimestamp(), // Official Google timestamp
      });

      // Reset the app state for the next workout session
      setState(() {
        _currentSessionSets.clear();
        _lastSetTimestamp = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session uploaded to Guy of Warwick!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Upload failed: $e");
    }
  }

  @override
  void dispose() {
    // Standard cleanup to keep the app fast
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar property of the Scaffold
    appBar: AppBar(
      title: const Text('Adonis Session Logger'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      
      // 'actions' is a list of widgets (buttons) on the right side of the bar
      actions: [
        IconButton(
          icon: const Icon(Icons.show_chart), // The graph icon
          tooltip: 'View Progress Graph',
          onPressed: () {
            // This is the "Magic Link" to your new file
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutAnalyticsPage(),
              ),
            );
          },
        ),
      ],
    ),
      body: Column(
        children: [
          // TOP SECTION: Input Controls
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedExercise,
                      decoration: const InputDecoration(labelText: "Select Exercise"),
                      items: ['Bench Press', 'Squat', 'Muscle Up', 'Dips', 'Pull Ups']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedExercise = val!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logSet, 
                        icon: const Icon(Icons.add), 
                        label: const Text("Log Set Locally"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MIDDLE SECTION: The Live List
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("SESSION DATA (Not yet submitted)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _currentSessionSets.length,
              itemBuilder: (context, index) {
                final item = _currentSessionSets[index];
                return ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text("${item['exercise']} - ${item['weight']}kg x ${item['reps']}"),
                  subtitle: Text("Rest period: ${item['rest_after_prev']}"),
                  trailing: const Icon(Icons.check, color: Colors.green),
                );
              },
            ),
          ),

          // BOTTOM SECTION: The Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _currentSessionSets.isEmpty ? null : _submitWorkout,
              child: const Text("FINISH & SUBMIT WORKOUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}