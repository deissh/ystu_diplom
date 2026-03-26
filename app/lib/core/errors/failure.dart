sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
