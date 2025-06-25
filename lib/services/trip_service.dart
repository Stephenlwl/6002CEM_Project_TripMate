import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/trip_model.dart';

class TripService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'trips';

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Future<void> fetchTrips(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('collaborators', arrayContains: userId)
          .get();

      _trips = snapshot.docs
          .map((doc) => Trip.fromMap(doc.id, doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching trips: $e');
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      final docRef = await _firestore.collection(_collectionPath).add(trip.toMap());
      _trips.add(trip.copyWith(id: docRef.id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding trip: $e');
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(_collectionPath).doc(tripId).delete();
      _trips.removeWhere((trip) => trip.id == tripId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting trip: $e');
    }
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    try {
      await _firestore.collection(_collectionPath).doc(updatedTrip.id).update(updatedTrip.toMap());
      int index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
      if (index != -1) _trips[index] = updatedTrip;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating trip: $e');
    }
  }
}
