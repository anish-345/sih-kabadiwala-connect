sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class InferenceFailure extends Failure {
  const InferenceFailure(super.message);
}

class BhashiniFailure extends Failure {
  const BhashiniFailure(super.message);
}

class QrExpiredFailure extends Failure {
  const QrExpiredFailure([super.message = 'Handover QR expired (>24 hrs)']);
}

class QrInvalidFailure extends Failure {
  const QrInvalidFailure([super.message = 'Invalid cryptographic signature']);
}

class DuplicateFailure extends Failure {
  const DuplicateFailure(this.existingId) : super('Duplicate record exists: $existingId');
  final String existingId;
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
