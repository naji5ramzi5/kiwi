import 'package:supabase_flutter/supabase_flutter.dart';

enum OpsRole { superAdmin, branchManager, staff, driver, customer, unknown }

extension OpsRoleX on OpsRole {
  String get label {
    switch (this) {
      case OpsRole.superAdmin:
        return 'مدير النظام';
      case OpsRole.branchManager:
        return 'مدير فرع';
      case OpsRole.staff:
        return 'موظف تشغيل';
      case OpsRole.driver:
        return 'مندوب';
      case OpsRole.customer:
        return 'عميل';
      case OpsRole.unknown:
        return 'غير معروف';
    }
  }

  bool get canAccessOperations =>
      this == OpsRole.superAdmin ||
      this == OpsRole.branchManager ||
      this == OpsRole.staff;
}

class AuthState {
  final OpsRole role;
  final Map<String, dynamic>? profile;
  final String? branchId;
  final String? fullName;

  AuthState({
    required this.role,
    this.profile,
    this.branchId,
    this.fullName,
  });

  bool get isSuper => role == OpsRole.superAdmin;
  bool get isBranchRestricted => role == OpsRole.branchManager;
}

class AuthService {
  static final SupabaseClient _sb = Supabase.instance.client;

  static OpsRole _mapRole(String? r) {
    switch (r) {
      case 'super_admin':
      case 'admin':
        return OpsRole.superAdmin;
      case 'branch_manager':
        return OpsRole.branchManager;
      case 'staff':
        return OpsRole.staff;
      case 'driver':
        return OpsRole.driver;
      case 'customer':
        return OpsRole.customer;
      default:
        return OpsRole.unknown;
    }
  }

  static Future<AuthState?> fetchAuthState() async {
    final user = _sb.auth.currentUser;
    if (user == null) return null;
    final profile = await _sb
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    final role = _mapRole(profile?['role']?.toString());
    return AuthState(
      role: role,
      profile: profile,
      branchId: profile?['branch_id']?.toString(),
      fullName: profile?['full_name']?.toString(),
    );
  }

  static Future<void> saveFcmToken(String token) async {
    final user = _sb.auth.currentUser;
    if (user == null) return;
    try {
      await _sb
          .from('profiles')
          .update({'fcm_token': token}).eq('id', user.id);
    } catch (_) {
      // non-critical
    }
  }

  static Future<void> signOut() async {
    await _sb.auth.signOut();
  }
}