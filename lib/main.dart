import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; 
import 'analytics_page.dart';

/// [main] is the entry point of the entire application.
/// It is marked as 'async' because initializing Firebase requires a 
/// "handshake" with Google's servers before the UI can safely load.
void main() async {
  // 1. Ensures that the Flutter framework is fully "awoken" before Firebase starts.
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Builds the secure bridge between your local code and the 
  // Firebase 'Guy of Warwick' backend project.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const AdonisApp());
}

/// [AdonisApp] sets the "brand identity" of your application.
/// It defines the global Indigo theme and specifies which screen 
/// the user sees first.
class AdonisApp extends StatelessWidget {
  const AdonisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Adonis',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      // The 'home' is the landing page of the app.
      home: const WorkoutSessionPage(),
    );
  }
}

/// [WorkoutSessionPage] is the core "Logger" engine.
/// It is a StatefulWidget because it needs to remember your sets 
/// in real-time as you perform your workout.
class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  // --- DATA STORAGE (Volatile Memory) ---
  // This list acts as a "Waiting Room." Data is stored here temporarily 
  // on your phone's RAM and is NOT yet saved to the internet.
  final List<Map<String, dynamic>> _currentSessionSets = [];
  
  // --- USER INPUT CAPTURE ---
  // These controllers act like "observers" that watch what you type 
  // into the Weight and Reps boxes.
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  
  String _selectedExercise = 'Bench Press';
  
  // A timestamp used to calculate the time elapsed between logging sets.
  DateTime? _lastSetTimestamp; 

  /// [_logSet] validates your input and moves the data from the 
  /// input boxes into the [_currentSessionSets] list.
  void _logSet() {
    final now = DateTime.now();
    
    // Logic to calculate rest periods between sets.
    String restTime = "First Set";
    if (_lastSetTimestamp != null) {
      final difference = now.difference(_lastSetTimestamp!);
      restTime = "${difference.inMinutes}m ${difference.inSeconds % 60}s";
    }

    // Guard Clause: Prevents the user from accidentally logging empty data.
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight and reps!')),
      );
      return;
    }

    // setState() triggers a "Redraw" of the UI so the new set appears in the list.
    setState(() {
      _currentSessionSets.add({
        'exercise': _selectedExercise,
        'weight': _weightController.text,
        'reps': _repsController.text,
        'rest_after_prev': restTime,
        'time_logged': now.toIso8601String(), // Standard format for databases
      });
      
      _lastSetTimestamp = now;
    });

    // Housekeeping: Reset the input boxes for the next set.
    _weightController.clear();
    _repsController.clear();
  }

  /// [_submitWorkout] takes the entire "Waiting Room" list and 
  /// uploads it as a single 'Session' document to Firebase Firestore.
  void _submitWorkout() async {
    if (_currentSessionSets.isEmpty) return;

    try {
      // Accesses the 'workouts' collection in your cloud warehouse.
      await FirebaseFirestore.instance.collection('workouts').add({
        'date_label': DateTime.now().toString().split(' ')[0], 
        'total_sets': _currentSessionSets.length,
        'sets': _currentSessionSets, // Uploads the nested list of sets
        'timestamp': FieldValue.serverTimestamp(), // Official Google server-side time
      });

      // Clear the local state so the app is ready for a new session tomorrow.
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
      // Error handling: Useful for debugging if the internet is down.
      print("Upload failed: $e");
    }
  }

  /// [dispose] is a cleanup method. It prevents "Memory Leaks" by 
  /// killing the controllers when the user leaves this screen.
  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold is the "Chassis" of your app, providing the top bar and body structure.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adonis Session Logger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart), 
            tooltip: 'View Progress Graph',
            onPressed: () {
              // Navigates the user to the analytics file we created.
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
          // --- UI COMPONENT: Input Card ---
          // This card contains the dropdown and text fields for data entry.
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExercise,
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
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)', 
                              border: OutlineInputBorder()
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(
                              labelText: 'Reps', 
                              border: OutlineInputBorder()
                            ),
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

          // --- UI COMPONENT: The "Waiting Room" List ---
          // This section displays what is currently in the phone's RAM.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "SESSION DATA (Not yet submitted)", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
            ),
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

          // --- UI COMPONENT: The Final Submission ---
          // This button triggers the [ _submitWorkout] logic to talk to Firebase.
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              // Button is disabled (null) if no sets have been logged yet.
              onPressed: _currentSessionSets.isEmpty ? null : _submitWorkout,
              child: const Text(
                "FINISH & SUBMIT WORKOUT", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
    );
  }
}