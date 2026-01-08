import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitWorkout(List<Map<String, dynamic>> sessionSets) async {
    await _db.collection('workouts').add({
      'date_label': DateTime.now().toString().split(' ')[0],
      'total_sets': sessionSets.length,
      'sets': sessionSets,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logBodyWeight(double weight) async {
    await _db.collection('user_metrics').add({
      'type': 'body_weight',
      'value': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
