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
  Future<List<String>> fetchVacantUnits() async {
    try {
      final snapshot = await _db
          .collection('units')
          .where('status', isEqualTo: 'Vacant')
          .get();

      // Extract unit numbers from documents
      List<String> units = snapshot.docs
          .map((doc) => doc['unitNumber'] as String)
          .toList();

      // Sort the unit numbers (lexicographically)
      units.sort();

      return units;
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
  /// for property dropdown0
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
      throw Exception('Error fetching units by property: $e');
    }
  }

  //TODO: update this method 
  /// Update unit status (e.g., from 'vacant' to 'occupied')
  /// Useful when a tenant moves in/out
  Future<void> updateUnitStatus(String unitId, String newStatus) async {
    try {
      await _db
          .collection('units')
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