import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/trip_model.dart';

class TripService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'trips';
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Future<void> fetchTrips(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('collaborators', arrayContains: userId)
          .orderBy('startDate')
          .get();

      _trips = snapshot.docs
          .map((doc) => Trip.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching trips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection(_collectionPath).add(trip.toMap());
      _trips.add(trip.copyWith(id: docRef.id));
    } catch (e) {
      debugPrint('Error adding trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collectionPath).doc(tripId).delete();
      _trips.removeWhere((trip) => trip.id == tripId);
    } catch (e) {
      debugPrint('Error deleting trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collectionPath).doc(updatedTrip.id).update(updatedTrip.toMap());
      int index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
      if (index != -1) _trips[index] = updatedTrip;
    } catch (e) {
      debugPrint('Error updating trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
