class CancelledException implements Exception {
  const CancelledException({this.cancellationReason});

  final String? cancellationReason;
}
