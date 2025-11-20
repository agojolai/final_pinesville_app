import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../exceptions/firebase_exceptions.dart' as custom_firebase;
import '../exceptions/format_exceptions.dart' as custom_format;
import '../exceptions/platform_exceptions.dart' as custom_platform;

class UnitRepository {
  static UnitRepository? _instance;
  static UnitRepository get instance => _instance ??= UnitRepository._();
  
  UnitRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Fetch all vacant units from Firestore
  /// Returns a sorted list of unit numbers that are available for rent
  /// NOTE: This fetches from all properties. Consider filtering by propertyId if needed.
  Future<List<String>> fetchVacantUnits() async {
    try {
      // Get all properties first
      final propertiesSnapshot = await _db.collection('Property').get();
      List<String> allVacantUnits = [];
      
      // Fetch vacant units from each property
      for (var propertyDoc in propertiesSnapshot.docs) {
        final unitsSnapshot = await _db
            .collection('Property')
            .doc(propertyDoc.id)
            .collection('Units')
            .where('status', isEqualTo: 'Vacant')
            .get();
        
        allVacantUnits.addAll(
          unitsSnapshot.docs.map((doc) => doc['unitNumber'] as String)
        );
      }

      // Sort the unit numbers (lexicographically)
      allVacantUnits.sort();

      return allVacantUnits;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching vacant units: $e');
    }
  }

  /// Fetch names of property
  /// for property dropdown
  Future<List<String>> fetchPropertyNames() async {
    try {
      final snapshot = await _db
          .collection('Property')
          .get();

      List<String> properties = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      properties.sort();
      return properties;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching property names: $e');
    }
  }

  /// Fetch properties with IDs (for efficient lookups)
  /// Returns map of propertyName -> propertyId
  Future<Map<String, String>> fetchPropertyMap() async {
    try {
      final snapshot = await _db.collection('Property').get();
      return Map.fromEntries(
        snapshot.docs.map((doc) => MapEntry(doc['name'] as String, doc.id))
      );
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching property map: $e');
    }
  }

  /// Fetch vacant units for a specific property by property name
  /// Returns a sorted list of unit numbers where rental.status = 'vacant'
  Future<List<String>> fetchVacantUnitsByProperty(String propertyName) async {
    try {
      // First, find the property document by name
      final propertySnapshot = await _db
          .collection('Property')
          .where('name', isEqualTo: propertyName)
          .limit(1)
          .get();

      if (propertySnapshot.docs.isEmpty) {
        return [];
      }

      final propertyId = propertySnapshot.docs.first.id;

      // Fetch vacant units from the property's Units subcollection
      final unitsSnapshot = await _db
          .collection('Property')
          .doc(propertyId)
          .collection('Units')
          .where('rental.status', isEqualTo: 'vacant')
          .get();

      List<String> vacantUnits = unitsSnapshot.docs
          .map((doc) => doc['unitNumber'] as String)
          .toList();

      // Sort the unit numbers
      vacantUnits.sort();

      return vacantUnits;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching vacant units by property: $e');
    }
  }

  /// Fetch vacant units by propertyId (optimized - no name lookup needed)
  /// Returns a sorted list of unit numbers where rental.status = 'vacant'
  Future<List<String>> fetchVacantUnitsByPropertyId(String propertyId) async {
    try {
      if (propertyId.isEmpty) return [];

      final unitsSnapshot = await _db
          .collection('Property')
          .doc(propertyId)
          .collection('Units')
          .where('rental.status', isEqualTo: 'vacant')
          .get();

      List<String> vacantUnits = unitsSnapshot.docs
          .map((doc) => doc['unitNumber'] as String)
          .toList();

      vacantUnits.sort();
      return vacantUnits;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching vacant units by property ID: $e');
    }
  }

  /// Update unit status (e.g., from 'vacant' to 'occupied')
  /// Useful when a tenant moves in/out
  /// Requires propertyId to access the correct nested path: Property/{propertyId}/Units/{unitId}
  Future<void> updateUnitStatus(String propertyId, String unitId, String newStatus) async {
    try {
      await _db
          .collection('Property')
          .doc(propertyId)
          .collection('Units')
          .doc(unitId)
          .update({'status': newStatus});
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating unit status: $e');
    }
  }
}