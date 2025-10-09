import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/utils/app_logger.dart';

/// Service to seed test data for billing management
class SeedService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  SeedService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  /// Delete all existing seed data and recreate with fresh data including auth accounts
  Future<Map<String, dynamic>> seedAllData() async {
    try {
      // Step 1: Delete all existing data
      await _deleteAllData();
      
      // Step 2: Seed properties and units
      await _seedProperties();
      
      // Step 3: Create Firebase Auth accounts for tenants
      final authResults = await _seedAuthAccounts();
      
      // Step 4: Seed user documents in Firestore
      await _seedTenants(authResults);
      
      return {
        'success': true,
        'message': 'Successfully deleted old data and seeded 2 properties, 6 units, and 6 test tenants with auth accounts',
        'data': {
          'properties': 2,
          'units': 6,
          'tenants': 6,
          'authAccounts': authResults.length,
        },
        'testCredentials': {
          'email': 'john.doe@test.com',
          'password': 'Test123!',
          'note': 'All test accounts use the same password: Test123!',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error seeding data: $e',
      };
    }
  }

  /// Delete all existing seed data (Properties, Units, Users, Bills, Payments)
  Future<void> _deleteAllData() async {
    AppLogger.info('Deleting all existing seed data...');
    
    // Delete all Properties and their Units subcollection
    final properties = await _firestore.collection('Property').get();
    for (var property in properties.docs) {
      // Delete all units in this property
      final units = await _firestore
          .collection('Property')
          .doc(property.id)
          .collection('Units')
          .get();
      
      for (var unit in units.docs) {
        await unit.reference.delete();
      }
      
      // Delete the property
      await property.reference.delete();
    }
    
    // Delete all Users
    final users = await _firestore.collection('Users').get();
    for (var user in users.docs) {
      await user.reference.delete();
    }
    
    // Delete all Bills
    final bills = await _firestore.collection('Bills').get();
    for (var bill in bills.docs) {
      await bill.reference.delete();
    }
    
    // Delete all Payments
    final payments = await _firestore.collection('Payments').get();
    for (var payment in payments.docs) {
      await payment.reference.delete();
    }
    
    AppLogger.info('All existing seed data deleted');
  }

  /// Create Firebase Auth accounts for test tenants
  Future<List<Map<String, String>>> _seedAuthAccounts() async {
    AppLogger.info('Creating Firebase Auth accounts...');
    
    final testPassword = 'Test123!'; // Standard password for all test accounts
    final authResults = <Map<String, String>>[];
    
    final testEmails = [
      'john.doe@test.com',
      'jane.smith@test.com',
      'michael.johnson@test.com',
      'emily.williams@test.com',
      'david.brown@test.com',
      'sarah.davis@test.com',
    ];
    
    for (var email in testEmails) {
      try {
        // Try to create the account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: testPassword,
        );
        
        authResults.add({
          'email': email,
          'uid': userCredential.user!.uid,
          'status': 'created',
        });
        
        print('✅ Created auth account: $email (${userCredential.user!.uid})');
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists, try to get the UID
          try {
            // Sign in to get the UID
            final userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: testPassword,
            );
            
            authResults.add({
              'email': email,
              'uid': userCredential.user!.uid,
              'status': 'existing',
            });
            
            print('ℹ️ Using existing auth account: $email (${userCredential.user!.uid})');
            
            // Sign out after getting UID
            await _auth.signOut();
          } catch (signInError) {
            print('⚠️ Could not access existing account $email: $signInError');
            // Use a placeholder UID - this will be updated when user first logs in
            authResults.add({
              'email': email,
              'uid': 'temp_${email.split('@').first}',
              'status': 'placeholder',
            });
          }
        } else {
          print('⚠️ Error creating auth account $email: ${e.message}');
          // Use a placeholder UID
          authResults.add({
            'email': email,
            'uid': 'temp_${email.split('@').first}',
            'status': 'error',
          });
        }
      }
    }
    
    print('✅ Firebase Auth accounts processed: ${authResults.length}');
    return authResults;
  }

  Future<void> _seedProperties() async {
    final properties = _getPropertiesData();
    
    for (var property in properties) {
      final propertyId = property['propertyId'] as String;
      final propertyData = property['data'] as Map<String, dynamic>;
      final units = property['units'] as List<Map<String, dynamic>>;
      
      // Create Property document
      await _firestore
          .collection('Property')
          .doc(propertyId)
          .set(propertyData);
      
      // Create Units subcollection
      for (var unit in units) {
        final unitNumber = unit['unitNumber'] as String;
        final unitData = Map<String, dynamic>.from(unit['data'] as Map<String, dynamic>);
        
        // Inject propertyId into unit data
        unitData['propertyId'] = propertyId;
        
        await _firestore
            .collection('Property')
            .doc(propertyId)
            .collection('Units')
            .doc(unitNumber)
            .set(unitData);
      }
    }
  }

  Future<void> _seedTenants(List<Map<String, String>> authResults) async {
    print('👥 Creating user documents in Firestore...');
    
    final tenants = _getTenantsData();
    
    for (var i = 0; i < tenants.length; i++) {
      final tenant = tenants[i];
      final tenantEmail = tenant['email'] as String;
      final tenantData = tenant['data'] as Map<String, dynamic>;
      
      // Find matching auth result by email
      final authResult = authResults.firstWhere(
        (result) => result['email'] == tenantEmail,
        orElse: () => {'uid': 'tenant_00${i + 1}', 'email': tenantEmail},
      );
      
      final userId = authResult['uid']!;
      
      // Update account status to 'active' for immediate testing
      if (tenantData['account'] != null) {
        tenantData['account']['status'] = 'active';
        tenantData['account']['approvedAt'] = DateTime.now().toIso8601String();
      }
      
      await _firestore
          .collection('Users')
          .doc(userId) // Use Firebase Auth UID as document ID
          .set(tenantData);
      
      print('✅ Created user document: $tenantEmail ($userId)');
    }
    
    print('✅ All user documents created');
  }

  List<Map<String, dynamic>> _getPropertiesData() {
    return [
      // Pinesville Tower A
      {
        'propertyId': 'property_001',
        'data': {
          'propertyId': 'property_001',
          'name': 'Pinesville Tower A',
          'address': {
            'street': '123 Pinesville Ave',
            'city': 'Pinesville',
            'region': 'NY',
            'zipCode': '12345',
          },
          'details': {
            'type': 'apartment',
            'totalUnits': 150,
            'floors': 15,
            'yearBuilt': 2020,
            'amenities': ['gym', 'pool', 'parking', 'laundry'],
          },
          'utilityRates': {
            'electricity': {
              'ratePerKwh': 12.50,
              'effectiveDate': DateTime.now().toIso8601String(),
              'currency': 'PHP',
            },
            'water': {
              'ratePerCubicMeter': 35.00,
              'effectiveDate': DateTime.now().toIso8601String(),
              'currency': 'PHP',
            },
          },
          'fixedCharges': {
            'trash': {
              'amount': 200.00,
              'enabled': true,
              'description': 'Trash Collection',
            },
            'wifi': {
              'amount': 500.00,
              'enabled': true,
              'description': 'WiFi Service',
            },
          },
          'createdAt': DateTime.now().toIso8601String(),
        },
        'units': [
          _getUnitData('301', 'tenant_001', '2BR', 2, 2, 1200, 15000.00, true, 1000.00, 'P-301', 1250.50, 850.00),
          _getUnitData('302', 'tenant_002', '1BR', 1, 1, 800, 12000.00, false, 0.00, '', 980.25, 620.50),
          _getUnitData('303', 'tenant_003', '3BR', 3, 2, 1500, 20000.00, true, 1500.00, 'P-303', 1450.75, 1020.00),
        ],
      },
      // Pinesville Tower B
      {
        'propertyId': 'property_002',
        'data': {
          'propertyId': 'property_002',
          'name': 'Pinesville Tower B',
          'address': {
            'street': '456 Pinesville Blvd',
            'city': 'Pinesville',
            'region': 'NY',
            'zipCode': '12346',
          },
          'details': {
            'type': 'apartment',
            'totalUnits': 120,
            'floors': 12,
            'yearBuilt': 2021,
            'amenities': ['gym', 'parking', 'rooftop'],
          },
          'utilityRates': {
            'electricity': {
              'ratePerKwh': 13.00,
              'effectiveDate': DateTime.now().toIso8601String(),
              'currency': 'PHP',
            },
            'water': {
              'ratePerCubicMeter': 40.00,
              'effectiveDate': DateTime.now().toIso8601String(),
              'currency': 'PHP',
            },
          },
          'fixedCharges': {
            'trash': {
              'amount': 250.00,
              'enabled': true,
              'description': 'Trash Collection',
            },
            'wifi': {
              'amount': 600.00,
              'enabled': true,
              'description': 'WiFi Service',
            },
          },
          'createdAt': DateTime.now().toIso8601String(),
        },
        'units': [
          _getUnitData('501', 'tenant_004', '2BR', 2, 2, 1300, 16000.00, true, 1200.00, 'P-501', 1320.00, 920.50),
          _getUnitData('502', 'tenant_005', 'studio', 0, 1, 500, 8000.00, false, 0.00, '', 650.00, 420.00),
          _getUnitData('503', 'tenant_006', '1BR', 1, 1, 900, 13000.00, true, 800.00, 'P-503', 1050.50, 710.00),
        ],
      },
    ];
  }

  Map<String, dynamic> _getUnitData(
    String unitNumber,
    String tenantId,
    String type,
    int bedrooms,
    int bathrooms,
    int sqft,
    double rent,
    bool hasParking,
    double parkingFee,
    String parkingSlot,
    double electricityReading,
    double waterReading,
  ) {
    // Return structure that includes both 'unitNumber' for doc ID and 'data' for nested structure
    return {
      'unitNumber': unitNumber,
      'data': {
        'unitId': unitNumber,
        'unitNumber': unitNumber,
        'details': {
          'type': type,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
          'sqft': sqft,
          'floor': int.parse(unitNumber[0]),
          'balcony': bedrooms >= 2,
          'furnished': bedrooms >= 3,
        },
        'lease': {
          'currentTenantId': tenantId,
          'rentAmount': rent,
          'securityDeposit': rent,
          'leaseStartDate': '2024-01-15',
          'leaseEndDate': '2025-01-14',
          'renewalOptions': '6months',
        },
        'rental': {
          'monthlyRent': rent,
          'status': 'occupied',
          'tenantId': tenantId,
        },
        'parking': {
          'hasParking': hasParking,
          'parkingFee': parkingFee,
          'parkingSlot': parkingSlot,
        },
        'lastReadings': {
          'electricity': {
            'reading': electricityReading,
            'readingDate': '2024-09-30T10:00:00Z',
            'meterNumber': 'ELEC-`$unitNumber-001',
          },
          'water': {
            'reading': waterReading,
            'readingDate': '2024-09-30T10:30:00Z',
            'meterNumber': 'WATER-`$unitNumber-001',
          },
        },
        'status': 'occupied',
        'propertyId': 'UNSET',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  List<Map<String, dynamic>> _getTenantsData() {
    return [
      _getTenantData('tenant_001', 'John', 'Doe', 'john.doe@test.com', '+1234567001', 'Pinesville Tower A', 'property_001', '301', '2BR', 15000.00),
      _getTenantData('tenant_002', 'Jane', 'Smith', 'jane.smith@test.com', '+1234567002', 'Pinesville Tower A', 'property_001', '302', '1BR', 12000.00),
      _getTenantData('tenant_003', 'Michael', 'Johnson', 'michael.johnson@test.com', '+1234567003', 'Pinesville Tower A', 'property_001', '303', '3BR', 20000.00),
      _getTenantData('tenant_004', 'Emily', 'Williams', 'emily.williams@test.com', '+1234567004', 'Pinesville Tower B', 'property_002', '501', '2BR', 16000.00),
      _getTenantData('tenant_005', 'David', 'Brown', 'david.brown@test.com', '+1234567005', 'Pinesville Tower B', 'property_002', '502', 'Studio', 8000.00),
      _getTenantData('tenant_006', 'Sarah', 'Davis', 'sarah.davis@test.com', '+1234567006', 'Pinesville Tower B', 'property_002', '503', '1BR', 13000.00),
    ];
  }

  Map<String, dynamic> _getTenantData(
    String id,
    String firstName,
    String lastName,
    String email,
    String phone,
    String propertyName,
    String propertyId,
    String unitId,
    String unitType,
    double rent,
  ) {
    return {
      'id': id,
      'email': email, // Include email at top level for matching with auth results
      'data': {
        'profile': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phone,
          'profilePicture': '',
        },
        'property': {
          'propertyName': propertyName,
          'propertyId': propertyId,
          'unitId': unitId,
          'unitType': unitType,
          'moveInDate': '2024-01-15T00:00:00Z',
          'leaseEndDate': '2025-01-14T00:00:00Z',
          'rentAmount': rent,
        },
        'account': {
          'status': 'pending', // Will be updated to 'active' in _seedTenants
          'role': 'tenant',
          'createdAt': DateTime.now().toIso8601String(),
        },
      },
    };
  }
}
