import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// A utility class for securely handling passwords.
/// Author: Dimas Atha Putra
///
/// This class provides methods to:
/// - Generate random salts
/// - Hash passwords with SHA-256 and salt
/// - Verify passwords against stored salted hashes
///
/// Example usage:
/// ```dart
/// final salt = PasswordHandler.generateSalt();
/// final hash = PasswordHandler.hashPassword('mySecret123', salt);
/// final hash = PasswordHandler.hashPassword('mySecret123', PasswordHandler.generateSalt());
/// final isValid = PasswordHandler.verifyPassword('mySecret123', hash);
/// ```
class PasswordHandler {
  /// Generates a cryptographically secure random salt string.
  ///
  /// [length] defines the number of random bytes used before encoding (default is 16).
  /// The returned string is Base64 URL-safe encoded.
  ///
  /// Example:
  /// ```dart
  /// final salt = PasswordHandler.generateSalt(); // e.g., "a8K2Xz3QHf..."
  /// ```
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  /// Creates a salted SHA-256 hash of the provided [password].
  ///
  /// The resulting value combines the [salt] and the hash, separated by `':::'`.
  /// This makes it easier to store and retrieve both together later.
  ///
  /// Example stored value format:
  /// ```
  /// {salt}:::{hashed_password}
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final hash = PasswordHandler.hashPassword('password123', salt);
  /// // "a8K2Xz3QHf...:::9e107d9d372bb6826bd81d3542a419d6..."
  /// ```
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password.trim() + salt);
    final digest = sha256.convert(bytes);
    return '$salt:::${digest.toString()}';
  }

  /// Verifies a plain [password] against a previously stored salted hash.
  ///
  /// The stored hash must be in the format `{salt}:::{hashed_password}`.
  /// This method extracts the salt, rehashes the input password using the same salt,
  /// and compares the results securely.
  ///
  /// Returns `true` if the password is valid, otherwise `false`.
  ///
  /// Example:
  /// ```dart
  /// final isValid = PasswordHandler.verifyPassword('password123', storedHash);
  /// ```
  static bool verifyPassword(String password, String storedHash) {
    // Extract salt from the stored hash string
    final salt = storedHash.split(':::')[0];

    // Recreate the hash using the extracted salt
    final hashToVerify = hashPassword(password.trim(), salt);

    // Compare with stored hash
    return hashToVerify == storedHash;
  }
}
