import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Document 12.4: the short-lived access token is held in memory only — never
/// written to disk (only the refresh token is, in secure storage). Exposed as
/// a provider so both the Dio auth interceptor and AuthController share one
/// source of truth without the network layer depending on the auth feature.
final accessTokenProvider = StateProvider<String?>((ref) => null);
