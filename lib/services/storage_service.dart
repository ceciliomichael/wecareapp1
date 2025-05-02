import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Save a list of users to SharedPreferences
  static Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = User.encodeUsers(users);
    await prefs.setString(_usersKey, encodedData);
  }

  // Get all users from SharedPreferences
  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString(_usersKey);

    if (usersString == null) {
      return [];
    }

    return User.decodeUsers(usersString);
  }

  // Save current user ID
  static Future<void> setCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      return null;
    }

    final users = await getUsers();
    return users.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('Current user not found'),
    );
  }

  // Add a new user
  static Future<void> addUser(User user) async {
    final users = await getUsers();

    // Check if user with the same email already exists
    final existingUserIndex = users.indexWhere((u) => u.email == user.email);

    if (existingUserIndex >= 0) {
      // Replace existing user
      users[existingUserIndex] = user;
    } else {
      // Add new user
      users.add(user);
    }

    await saveUsers(users);
  }

  // Update an existing user
  static Future<void> updateUser(User updatedUser) async {
    final users = await getUsers();

    final index = users.indexWhere((user) => user.id == updatedUser.id);

    if (index >= 0) {
      users[index] = updatedUser;
      await saveUsers(users);
    } else {
      throw Exception('User not found');
    }
  }

  // Check if a user exists with the given email
  static Future<bool> userExists(String email) async {
    final users = await getUsers();
    return users.any((user) => user.email == email);
  }

  // Find a user by email and password (for login)
  static Future<User?> findUserByCredentials(
    String email,
    String password,
  ) async {
    final users = await getUsers();

    try {
      return users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
