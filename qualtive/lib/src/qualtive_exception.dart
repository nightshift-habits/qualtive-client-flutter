/// Errors thrown by the Qualtive client.
sealed class QualtiveException implements Exception {
  const QualtiveException([this.message, this.cause]);

  final String? message;
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer(runtimeType.toString());
    if (message != null) {
      buffer.write(': $message');
    }
    if (cause != null) {
      buffer.write(' (cause: $cause)');
    }
    return buffer.toString();
  }
}

/// The requested enquiry (or related resource) was not found.
class QualtiveNotFoundException extends QualtiveException {
  const QualtiveNotFoundException([
    super.message = 'Not found',
    super.cause,
  ]);
}

/// A network connection error occurred.
class QualtiveConnectionException extends QualtiveException {
  const QualtiveConnectionException([
    super.message = 'Connection failed',
    super.cause,
  ]);
}

/// The Qualtive API is temporarily unavailable for maintenance.
class QualtiveRemoteMaintenanceException extends QualtiveException {
  const QualtiveRemoteMaintenanceException([
    super.message = 'Remote maintenance',
    super.cause,
  ]);
}

/// An unexpected error occurred.
class QualtiveUnexpectedException extends QualtiveException {
  const QualtiveUnexpectedException([
    super.message = 'Unexpected error',
    super.cause,
  ]);
}
