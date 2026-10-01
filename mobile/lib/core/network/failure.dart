/// Document 12.7: a sealed-style Failure type every API error maps to, so
/// screens handle one shape instead of parsing Dio exceptions themselves.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Could not reach the server. Check your connection.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const []});
  final List<String> fieldErrors;
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Your session has expired. Please sign in again.']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = "You don't have permission to do that."]);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'This record changed elsewhere. Refresh and try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our end. Please try again.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unexpected error.']);
}
