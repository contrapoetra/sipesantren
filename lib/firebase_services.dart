import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/user_model.dart'; // New import
import 'package:sipesantren/crypt.dart'; // New import

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseServicesProvider = Provider((ref) => FirebaseServices(firestore: ref.watch(firestoreProvider)));

class FirebaseServices {
  final FirebaseFirestore db;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  FirebaseServices({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Future<bool> createUser(
      String name, String email, String hashedPassword, String role,
      {String? requestedRole}) async {
    final user = <String, dynamic>{
      "name": name,
      "email": email,
      "hashed_password": hashedPassword,
      "role": role,
      "requested_role": requestedRole,
      "created_at": FieldValue.serverTimestamp(),
    };

    bool success = false;
    try {
      // Check if email already exists
      final query = await db.collection('users').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        debugPrint("Email already exists");
        return false;
      }

      await db.collection('users').add(user);
      debugPrint("User Added");
      success = true;
    } catch (error) {
      debugPrint("Error adding user: $error");
    }

    return success;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final query = await db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        debugPrint("User Not Found");
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();

      final storedHashedPassword = data['hashed_password'] as String;

      // Verify password using PasswordHandler
      if (PasswordHandler.verifyPassword(password, storedHashedPassword)) {
        return {
          'id': doc.id,
          ...data
        };
      } else {
        debugPrint("Invalid Password");
        return null;
      }

    } catch (e) {
      debugPrint("Error login: $e");
      return null;
    }
  }

  // Legacy method for compatibility if needed, but we should upgrade.
  Future<bool> getUser(String email, String password) async {
    final user = await login(email, password);
    return user != null;
  }

  Future<void> saveUserSession(String id, String role, String name) async {
    await _storage.write(key: 'user_id', value: id);
    await _storage.write(key: 'user_role', value: role);
    await _storage.write(key: 'user_name', value: name);
  }

  Future<Map<String, String?>> getUserSession() async {
    debugPrint("FirebaseServices: Attempting to get user session...");
    try {
      String? id = await _storage.read(key: 'user_id');
      String? role = await _storage.read(key: 'user_role');
      String? name = await _storage.read(key: 'user_name');
      debugPrint("FirebaseServices: User session retrieved - ID: $id, Role: $role, Name: $name");
      return {'id': id, 'role': role, 'name': name};
    } catch (e) {
      debugPrint("FirebaseServices: Error getting user session: $e");
      // Return an empty map to ensure the Future completes and allows the app to proceed
      return {'id': null, 'role': null, 'name': null};
    }
  }

  Future<void> logout() async {
    debugPrint("FirebaseServices: Attempting to clear session keys explicitly...");
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_name');

    debugPrint("FirebaseServices: Explicit key deletion completed. Verifying contents...");
    String? id = await _storage.read(key: 'user_id');
    debugPrint("FirebaseServices: After explicit delete, user_id is: $id");
  }

  // Stream all users
  Stream<List<UserModel>> getUsers() {
    return db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get a single user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await db.collection('users').doc(id).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user by ID: $e");
      return null;
    }
  }

  // Update user details (name, email, role)
  Future<bool> updateUser(String userId, String name, String email, String role) async {
    try {
      await db.collection('users').doc(userId).update({
        'name': name,
        'email': email,
        'role': role,
      });
      return true;
    } catch (e) {
      debugPrint("Error updating user: $e");
      return false;
    }
  }

  Future<bool> approveUserRoleRequest(String userId, String newRole) async {
    try {
      await db.collection('users').doc(userId).update({
        'role': newRole,
        'requested_role': null,
      });
      return true;
    } catch (e) {
      debugPrint("Error approving user role request: $e");
      return false;
    }
  }

  Future<bool> rejectUserRoleRequest(String userId) async {
    try {
      await db.collection('users').doc(userId).update({
        'requested_role': null,
      });
      return true;
    } catch (e) {
      debugPrint("Error rejecting user role request: $e");
      return false;
    }
  }

  // Update user password
  Future<bool> updateUserPassword(String userId, String newPassword) async {
    try {
      final salt = PasswordHandler.generateSalt();
      final hashedPassword = PasswordHandler.hashPassword(newPassword, salt);
      await db.collection('users').doc(userId).update({
        'hashed_password': hashedPassword,
      });
      return true;
    } catch (e) {
      debugPrint("Error updating password: $e");
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await db.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting user: $e");
      return false;
    }
  }
}
