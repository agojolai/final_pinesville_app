import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id; // Firestore doc ID / Firebase Auth UID

  // Nested profile
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String profilePicture;

  // Nested property
  final String propertyName;
  final String propertyId;
  final String unitId;
  final String unitType;
  final DateTime? moveInDate;
  final DateTime? leaseEndDate;
  final double rentAmount;

  // Nested account
  final String status; // pending, active, suspended, terminated
  final DateTime? createdAt;

  const UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
    required this.propertyName,
    required this.propertyId,
    required this.unitId,
    required this.unitType,
    required this.moveInDate,
    required this.leaseEndDate,
    required this.rentAmount,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
//TODO: clarify where is this used
  static List<String> nameParts(fullName) => fullName.split(" ");

  // Static function to create an empty user model.
  static UserModel empty() => UserModel(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        phoneNumber: "",
        profilePicture: "",
        propertyName: "",
        propertyId: "",
        unitId: "",
        unitType: "",
        moveInDate: null,
        leaseEndDate: null,
        rentAmount: 0.0,
        status: "pending",
        createdAt: null,
      );

 // Convert model to JSON (Firestore format)
  Map<String, dynamic> toJson() {
    return {
      "profile": {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNumber": phoneNumber,
        "profilePicture": profilePicture,
      },
      "property": {
        "propertyName": propertyName,
        "propertyId": propertyId,
        "unitId": unitId,
        "unitType": unitType,
        "moveInDate": moveInDate?.toIso8601String(),
        "leaseEndDate": leaseEndDate?.toIso8601String(),
        "rentAmount": rentAmount,
      },
      "account": {
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
      }
    };
  }


    // Helper function to safely parse date strings
  static DateTime? _parseDate(dynamic date) {
    if (date is String && date.isNotEmpty) {
      return DateTime.tryParse(date);
    }
    if (date is Timestamp) {
      return date.toDate();
    }
    return null;
  }

  // Factory method to create a UserModel from a Firestore snapshot
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserModel.empty();

    final profile = data['profile'] ?? {};
    final property = data['property'] ?? {};
    final account = data['account'] ?? {};

    return UserModel(
      id: document.id,
      firstName: profile['firstName'] ?? "",
      lastName: profile['lastName'] ?? "",
      email: profile['email'] ?? "",
      phoneNumber: profile['phoneNumber'] ?? "",
      profilePicture: profile['profilePicture'] ?? "",
      propertyName: property['propertyName'] ?? "",
      propertyId: property['propertyId'] ?? "",
      unitId: property['unitId'] ?? "",
      unitType: property['unitType'] ?? "",
      moveInDate: _parseDate(property['moveInDate']),
      leaseEndDate: _parseDate(property['leaseEndDate']),
      rentAmount: (property['rentAmount'] ?? 0).toDouble(),
      status: account['status'] ?? "pending",
      createdAt: _parseDate(account['createdAt']),
    );
  }

  }
