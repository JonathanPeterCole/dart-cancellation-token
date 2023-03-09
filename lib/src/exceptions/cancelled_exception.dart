class CancelledException implements Exception {
  const CancelledException({this.cancellationReason});

  /// An optional reason for the cancellation.
  final String? cancellationReason;

  @override
  String toString() {
    String message = 'CancelledException: The operation was cancelled by a '
        'CancellationToken.';
    if (cancellationReason != null) {
      message = '$message (reason: $cancellationReason)';
    }
    return message;
  }
}
