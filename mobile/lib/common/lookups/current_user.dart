import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/access_token_holder.dart';

/// Who is signed in, read from the access token's claims (sub = user id,
/// email, roles). Display/convenience only — the server re-checks every
/// permission, so nothing here is trusted for authorization.
@immutable
class CurrentUser {
  const CurrentUser({required this.id, this.email, this.roles = const []});
  final int id;
  final String? email;
  final List<String> roles;
}

final currentUserProvider = Provider<CurrentUser?>((ref) {
  final token = ref.watch(accessTokenProvider);
  if (token == null) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    final id = int.tryParse(payload['sub']?.toString() ?? '');
    if (id == null) return null;
    final roles = payload['roles'];
    return CurrentUser(
      id: id,
      email: payload['email'] as String?,
      roles: roles is List ? roles.map((r) => r.toString()).toList() : const [],
    );
  } on FormatException {
    return null;
  }
});
