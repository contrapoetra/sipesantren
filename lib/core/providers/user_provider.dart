import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/firebase_services.dart'; // New import

class UserState {
  final String? userId;
  final String? userRole;
  final String? userName;
  final bool isLoggedIn;
  final bool isLoadingSession; // New field

  UserState({
    this.userId,
    this.userRole,
    this.userName,
    this.isLoggedIn = false,
    this.isLoadingSession = true, // Default to true
  });

  UserState copyWith({
    String? userId,
    String? userRole,
    String? userName,
    bool? isLoggedIn,
    bool? isLoadingSession, // New field
  }) {
    return UserState(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession, // New field
    );
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref); // Pass ref to UserNotifier
});

class UserNotifier extends StateNotifier<UserState> {
  final Ref _ref; // Store ref

  UserNotifier(this._ref) : super(UserState()); // Accept ref in constructor

  void login(String id, String role, String name) {
    state = state.copyWith(
      userId: id,
      userRole: role,
      userName: name,
      isLoggedIn: true,
      isLoadingSession: false,
    );
  }

  Future<void> logout() async { // Make it async
    await _ref.read(firebaseServicesProvider).logout(); // Call FirebaseServices logout
    state = UserState(isLoadingSession: false); // Reset to default state, session check completed
  }

  void sessionCheckCompleted() {
    state = state.copyWith(isLoadingSession: false);
  }
}
