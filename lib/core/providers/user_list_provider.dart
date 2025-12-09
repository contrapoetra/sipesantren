import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/user_model.dart';
import 'package:sipesantren/firebase_services.dart';

/// Provides a stream of all users in the system.
/// This is intended for admin functionality to manage users.
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final firebaseServices = ref.watch(firebaseServicesProvider);
  return firebaseServices.getUsers();
});