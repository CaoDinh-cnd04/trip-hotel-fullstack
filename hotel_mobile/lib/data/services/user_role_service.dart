import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_mobile/data/models/user_role_model.dart';

class UserRoleService {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Collection reference
  static const String _usersCollection = 'users';

  /// Get default permissions for a role
  List<String> _getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          'user:read',
          'user:write',
          'user:delete',
          'hotel:read',
          'hotel:write',
          'hotel:delete',
          'booking:read',
          'booking:write',
          'booking:delete',
          'system:admin',
        ];
      case UserRole.hotelManager:
        return [
          'hotel:read',
          'hotel:write',
          'booking:read',
          'booking:write',
          'room:read',
          'room:write',
          'promotion:read',
          'promotion:write',
        ];
      case UserRole.user:
        return [
          'booking:read',
          'booking:write',
          'hotel:read',
          'room:read',
        ];
    }
  }

  /// Get current user role
  Future<UserRoleModel?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return UserRoleModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Create user role when first login
  Future<UserRoleModel?> createUserRole({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    UserRole role = UserRole.user,
    String? hotelId,
  }) async {
    try {
      final now = DateTime.now();
      final userRole = UserRoleModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        role: role,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        hotelId: hotelId,
        permissions: _getDefaultPermissions(role),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userRole.toJson());

      print('✅ User role created: ${role.displayName}');
      return userRole;
    } catch (e) {
      print('❌ Error creating user role: $e');
      return null;
    }
  }

  /// Update user role (Admin only)
  Future<bool> updateUserRole({
    required String uid,
    required UserRole newRole,
    String? hotelId,
    List<String>? customPermissions,
  }) async {
    try {
      final updateData = {
        'role': newRole.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'permissions': customPermissions ?? _getDefaultPermissions(newRole),
      };

      if (hotelId != null) {
        updateData['hotelId'] = hotelId;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updateData);

      print('✅ User role updated to: ${newRole.displayName}');
      return true;
    } catch (e) {
      print('❌ Error updating user role: $e');
      return false;
    }
  }

  /// Get all users (Admin only)
  Future<List<UserRoleModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRoleModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  /// Get users by role
  Future<List<UserRoleModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: role.value)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRoleModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting users by role: $e');
      return [];
    }
  }

  /// Check if user has permission
  Future<bool> hasPermission(String permission) async {
    final userRole = await getCurrentUserRole();
    return userRole?.hasPermission(permission) ?? false;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    final userRole = await getCurrentUserRole();
    return userRole?.isAdmin ?? false;
  }

  /// Check if user is hotel manager
  Future<bool> isHotelManager() async {
    final userRole = await getCurrentUserRole();
    return userRole?.isHotelManager ?? false;
  }

  /// Get hotel managers for a specific hotel
  Future<List<UserRoleModel>> getHotelManagers(String hotelId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.hotelManager.value)
          .where('hotelId', isEqualTo: hotelId)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRoleModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting hotel managers: $e');
      return [];
    }
  }

  /// Delete user role
  Future<bool> deleteUserRole(String uid) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .delete();

      print('✅ User role deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting user role: $e');
      return false;
    }
  }

  /// Listen to user role changes
  Stream<UserRoleModel?> watchUserRole(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserRoleModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Listen to all users (Admin only)
  Stream<List<UserRoleModel>> watchAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRoleModel.fromJson(doc.data()))
            .toList());
  }
}
