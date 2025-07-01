import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/activity_model.dart';
import 'dart:async';

class ActivityService extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _activitySubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Activity> _activities = [];
  List<Activity> get activities => _activities;

  fetchActivities(String tripId, String date) async {
    try {
      _isLoading = true;
      notifyListeners();
      // cancel the previous subscription if it exists
      _activitySubscription?.cancel();

      _activitySubscription = FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('schedule')
          .where('date', isEqualTo: date)
          .orderBy('sortTime')
          .snapshots()
          .listen((snapshot) {
        _activities = snapshot.docs.map((doc) {
          final data = doc.data();

          return Activity(
            id: doc.id,
            name: data['name'] ?? '',
            displayTime: data['displayTime'] ?? '',
            sortTime: data['sortTime'] ?? '',
            address: data['address'] ?? '',
            date: data['date'] ?? '',
            notes: data['notes'] ?? '',
            category: data['category'] ?? '',
            description: data['description'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            latitude: data['latitude'] ?? null,
            longitude: data['longitude'] ?? null,
          );
        }).toList();

        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }


  Future<void> addActivity(String tripId, Activity activity) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('schedule')
          .add(activity.toMap());

    } catch (e) {
      debugPrint('Error adding activity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateActivity(String tripId, Activity updatedActivity) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('schedule')
          .doc(updatedActivity.id)
          .update(updatedActivity.toMap());

      final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
      if (index != -1) _activities[index] = updatedActivity;
    } catch (e) {
      debugPrint('Error updating activity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String tripId, String activityId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('schedule')
          .doc(activityId)
          .delete();

      _activities.removeWhere((a) => a.id == activityId);
    } catch (e) {
      debugPrint('Error deleting activity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
