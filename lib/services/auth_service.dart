import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/user_type.dart';
import 'storage_service.dart';

class AuthService {
  static final Uuid _uuid = Uuid();

  // Register a new user
  static Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
    String? photoUrl,
    String? nbiClearance,
    List<String>? skills,
    String? experience,
    String? address,
    String? companyName,
  }) async {
    // Check if user already exists
    final exists = await StorageService.userExists(email);
    if (exists) {
      throw Exception('A user with this email already exists');
    }

    // Create new user
    final user = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      phone: phone,
      password: password, // In a real app, this would be hashed
      userType: userType,
      photoUrl: photoUrl,
      nbiClearance: nbiClearance,
      skills: skills,
      experience: experience,
      address: address,
      companyName: companyName,
    );

    // Save user to storage
    await StorageService.addUser(user);

    return user;
  }

  // Login user
  static Future<User> login(String email, String password) async {
    final user = await StorageService.findUserByCredentials(email, password);

    if (user == null) {
      throw Exception('Invalid email or password');
    }

    // Set as current user
    await StorageService.setCurrentUser(user.id);

    return user;
  }

  // Logout user
  static Future<void> logout() async {
    await StorageService.setCurrentUser('');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await StorageService.getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    return StorageService.getCurrentUser();
  }

  // Update user profile
  static Future<User> updateProfile(User updatedUser) async {
    await StorageService.updateUser(updatedUser);
    return updatedUser;
  }

  // Update NBI clearance
  static Future<User> updateNBIClearance(
    String userId,
    String nbiClearance,
  ) async {
    // Get current user
    final users = await StorageService.getUsers();
    final userIndex = users.indexWhere((user) => user.id == userId);

    if (userIndex < 0) {
      throw Exception('User not found');
    }

    // Update user
    final updatedUser = users[userIndex].copyWith(nbiClearance: nbiClearance);
    users[userIndex] = updatedUser;

    // Save users
    await StorageService.saveUsers(users);

    return updatedUser;
  }
}
