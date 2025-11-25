import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../features/auth/data/models/user_model.dart';
import '../services/notification_service.dart';

enum TenantStatus { all, active, pending, suspended }

final tenantListProvider = StateNotifierProvider<TenantListNotifier, AsyncValue<List<UserModel>>>((ref) {
  return TenantListNotifier(ref);
});

class TenantListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final Ref ref;
  TenantListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTenants();
  }

  Future<void> fetchTenants() async {
    try {
      // Fetch all users using UserModel
      final allUsers = await AuthRepository.instance.getAllUsers();
      
      if (allUsers.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      
      // Filter users by status (no need for manual mapping)
      final filteredUsers = allUsers.where((user) => 
        ['pending', 'active', 'suspended', 'rejected'].contains(user.status)
      ).toList();
      
      state = AsyncValue.data(filteredUsers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveTenant(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      throw 'Invalid email address provided';
    }

    try {
      // Optimistic update - update UI immediately
      final currentTenants = state.valueOrNull ?? [];
      final updatedTenants = currentTenants.map((tenant) {
        if (tenant.email == email) {
          return UserModel(
            id: tenant.id,
            firstName: tenant.firstName,
            lastName: tenant.lastName,
            email: tenant.email,
            phoneNumber: tenant.phoneNumber,
            profilePicture: tenant.profilePicture,
            propertyName: tenant.propertyName,
            propertyId: tenant.propertyId,
            unitId: tenant.unitId,
            unitType: tenant.unitType,
            moveInDate: tenant.moveInDate,
            leaseEndDate: tenant.leaseEndDate,
            rentAmount: tenant.rentAmount,
            status: 'active', // Update status
            role: tenant.role,
            createdAt: tenant.createdAt,
          );
        }
        return tenant;
      }).toList();
      state = AsyncValue.data(updatedTenants);

      // Perform backend update
      await AuthRepository.instance.approvePendingUser(email);
      
      // Send approval notification to tenant
      try {
        final approvedTenant = updatedTenants.firstWhere((t) => t.email == email);
        if (approvedTenant.id != null) {
          await NotificationService.notifyApplicationStatus(
            userId: approvedTenant.id!,
            isApproved: true,
            rejectionReason: null,
          );
        }
      } catch (e) {
        // Don't fail the approval if notification fails
        print('Failed to send approval notification: $e');
      }
      
      // Refresh from backend to ensure consistency
      await fetchTenants();
    } catch (e) {
      // Revert optimistic update on failure
      await fetchTenants();
      rethrow;
    }
  }

  Future<void> updateTenantStatus(String email, String newStatus, {String? reason}) async {
    if (email.isEmpty || !email.contains('@')) {
      throw 'Invalid email address provided';
    }
    
    if (!['suspended', 'terminated', 'active', 'rejected'].contains(newStatus)) {
      throw 'Invalid status provided';
    }

    try {
      // Optimistic update - update UI immediately
      final currentTenants = state.valueOrNull ?? [];
      final updatedTenants = currentTenants.map((tenant) {
        if (tenant.email == email) {
          return UserModel(
            id: tenant.id,
            firstName: tenant.firstName,
            lastName: tenant.lastName,
            email: tenant.email,
            phoneNumber: tenant.phoneNumber,
            profilePicture: tenant.profilePicture,
            propertyName: tenant.propertyName,
            propertyId: tenant.propertyId,
            unitId: tenant.unitId,
            unitType: tenant.unitType,
            moveInDate: tenant.moveInDate,
            leaseEndDate: tenant.leaseEndDate,
            rentAmount: tenant.rentAmount,
            status: newStatus, // Update status
            role: tenant.role,
            createdAt: tenant.createdAt,
          );
        }
        return tenant;
      }).toList();
      state = AsyncValue.data(updatedTenants);

      // Perform backend update
      await AuthRepository.instance.updateUserStatus(email, newStatus, reason: reason);
      
      // Send notification to tenant about status change
      if (newStatus == 'rejected') {
        try {
          final rejectedTenant = updatedTenants.firstWhere((t) => t.email == email);
          if (rejectedTenant.id != null) {
            await NotificationService.notifyApplicationStatus(
              userId: rejectedTenant.id!,
              isApproved: false,
              rejectionReason: reason,
            );
          }
        } catch (e) {
          // Don't fail the status update if notification fails
          print('Failed to send rejection notification: $e');
        }
      }
      
      // Refresh from backend to ensure consistency
      await fetchTenants();
    } catch (e) {
      // Revert optimistic update on failure
      await fetchTenants();
      rethrow;
    }
  }
}