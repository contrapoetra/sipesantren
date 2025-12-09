import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipesantren/crypt.dart';

class FirebaseServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<bool> createUser(
      String name, String email, String hashedPassword, String role) async {
    final user = <String, dynamic>{
      "name": name,
      "email": email,
      "hashed_password": hashedPassword,
      "role": role,
    };

    bool success = false;
    await db.collection('users').add(user).then((value) {
      debugPrint("User Added");
      success = true;
    }).catchError((error) {
      debugPrint("Error adding user: $error");
    });

    return success;
  }

  Future<bool> getUser(String email, String password) async {
    final user = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .where('hashed_password', isEqualTo: password)
        .get();
    if (user.docs.isNotEmpty) {
      debugPrint("User Found");
      return true;
    } else {
      debugPrint("User Not Found");
      return false;
    }
  }
}
