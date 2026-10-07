import 'current_user.dart';

/// Which home modules a role can open, mirroring the *_VIEW permissions the
/// backend seeds per role (Doc 5; V2/V7/V11/... migrations). Display-only:
/// it hides tiles that would just end in "You don't have permission" — the
/// server still enforces every permission on every call.
///
/// Expressed as the roles that LACK the module's view permission, because
/// most modules are open to most roles.
const Map<String, Set<String>> _rolesWithoutAccess = {
  'buyers': {'FACTORY_COORDINATOR'},
  'inquiries': {
    'SAMPLING_COORDINATOR', 'PRODUCTION_FOLLOWUP', 'QUALITY_INSPECTOR', 'COMMERCIAL_EXECUTIVE',
    'ACCOUNTS_FINANCE', 'FACTORY_COORDINATOR', 'MANAGEMENT_VIEWER',
  },
  'costing': {
    'SAMPLING_COORDINATOR', 'PRODUCTION_FOLLOWUP', 'QUALITY_INSPECTOR', 'COMMERCIAL_EXECUTIVE', 'FACTORY_COORDINATOR',
  },
  'quotation': {
    'SAMPLING_COORDINATOR', 'PRODUCTION_FOLLOWUP', 'QUALITY_INSPECTOR', 'COMMERCIAL_EXECUTIVE', 'FACTORY_COORDINATOR',
  },
  'production': {'SAMPLING_COORDINATOR'},
  'quality': {'SAMPLING_COORDINATOR'},
  'shipment': {'SAMPLING_COORDINATOR'},
  'documents': {'SAMPLING_COORDINATOR'},
  'financial': {
    'JUNIOR_MERCHANDISER', 'SAMPLING_COORDINATOR', 'PRODUCTION_FOLLOWUP', 'QUALITY_INSPECTOR',
    'COMMERCIAL_EXECUTIVE', 'FACTORY_COORDINATOR',
  },
  'claims': {'SAMPLING_COORDINATOR', 'PRODUCTION_FOLLOWUP', 'QUALITY_INSPECTOR', 'FACTORY_COORDINATOR'},
};

/// True when at least one of the user's roles can view [moduleId]. Unknown
/// users (no token claims) see everything rather than an empty launcher.
bool canOpenModule(CurrentUser? user, String moduleId) {
  final blocked = _rolesWithoutAccess[moduleId];
  if (blocked == null || user == null || user.roles.isEmpty) return true;
  return user.roles.any((role) => !blocked.contains(role));
}

/// Roles seeded with QUOTATION_APPROVE (Doc 10.3 gate); others can still move
/// a quotation through draft/negotiation but never mark it approved.
const Set<String> _quotationApproverRoles = {'SUPER_ADMIN', 'OWNER_MD', 'GENERAL_MANAGER', 'SENIOR_MERCHANDISER'};

bool canApproveQuotations(CurrentUser? user) =>
    user == null || user.roles.isEmpty || user.roles.any(_quotationApproverRoles.contains);
