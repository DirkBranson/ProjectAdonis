import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../analytics_page.dart';
import '../models/workout_config.dart';

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  final DatabaseService _dbService = DatabaseService();
  final List<Map<String, dynamic>> _currentSessionSets = [];

  final _field1Controller = TextEditingController();
  final _field2Controller = TextEditingController();
  final _field3Controller = TextEditingController();
  final _bodyWeightController = TextEditingController();

  String _selectedCategory = 'Free Weights';
  String _selectedWorkout = 'Bench Press';
  DateTime? _lastSetTimestamp;

  void _clearInputs() {
    _field1Controller.clear();
    _field2Controller.clear();
    _field3Controller.clear();
  }

  void _logSet() {
    final now = DateTime.now();

    if (_field1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the metrics!')),
      );
      return;
    }

    String restTime = "N/A";
    if (_selectedCategory != 'Distance Running') {
      if (_lastSetTimestamp != null) {
        final difference = now.difference(_lastSetTimestamp!);
        restTime = "${difference.inMinutes}m ${difference.inSeconds % 60}s";
      } else {
        restTime = "First Set";
      }
    }

    setState(() {
      _currentSessionSets.add({
        'category': _selectedCategory,
        'workout': _selectedWorkout,
        'val1': _field1Controller.text,
        'val2': _field2Controller.text,
        'val3': _field3Controller.text,
        'rest_time': restTime,
        'time_logged': now.toIso8601String(),
      });
      _lastSetTimestamp = now;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Set logged!'),
        duration: Duration(milliseconds: 700),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _submitWorkout() async {
    if (_currentSessionSets.isEmpty) return;
    await _dbService.submitWorkout(_currentSessionSets);
    setState(() {
      _currentSessionSets.clear();
      _lastSetTimestamp = null;
      _clearInputs(); // Optional: clear inputs after finishing whole session
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session uploaded!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Body Weight"),
        content: TextField(
          controller: _bodyWeightController,
          decoration: const InputDecoration(
            labelText: "Weight (kg)",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              double? weight = double.tryParse(_bodyWeightController.text);
              if (weight != null) {
                await _dbService.logBodyWeight(weight);
                _bodyWeightController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Weight Logged!")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();
    _bodyWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adonis Session Logger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_weight_outlined),
            onPressed: _showWeightDialog,
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutAnalyticsPage(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInputCard(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "SESSION DATA",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: _buildSessionList()),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final config = WorkoutConfig.categories[_selectedCategory]!;
    final List<String> fields = List<String>.from(config['fields']);
    final List<String> workouts = List<String>.from(config['workouts']);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: WorkoutConfig.categoryList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val!;
                    _selectedWorkout = WorkoutConfig.getWorkouts(val)[0];
                    _clearInputs();
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  _selectedCategory,
                ), // Forces dropdown to reset when category changes
                value: _selectedWorkout,
                decoration: const InputDecoration(labelText: "Exercise"),
                items: workouts
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedWorkout = val!;
                    _clearInputs();
                  });
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  for (int i = 0; i < fields.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextField(
                          controller: i == 0
                              ? _field1Controller
                              : (i == 1
                                    ? _field2Controller
                                    : _field3Controller),
                          decoration: InputDecoration(
                            labelText: fields[i],
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
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
                  label: const Text("Log Set"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    return ListView.builder(
      itemCount: _currentSessionSets.length,
      itemBuilder: (context, index) {
        final item = _currentSessionSets[index];
        return ListTile(
          leading: CircleAvatar(child: Text("${index + 1}")),
          title: Text("${item['workout']} (${item['category']})"),
          subtitle: Text("Rest: ${item['rest_time']}"),
          trailing: const Icon(Icons.check, color: Colors.green),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _currentSessionSets.isEmpty ? null : _submitWorkout,
        child: const Text(
          "FINISH & SUBMIT WORKOUT",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
