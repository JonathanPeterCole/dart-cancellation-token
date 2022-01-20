import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// Implemented in `cancellable_compute_io.dart` and
/// `cancellable_compute_web.dart`.
Future<R> cancellableComputeImpl<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
  CancellationToken cancellationToken, {
  String? debugLabel,
}) =>
    throw UnsupportedError(
        'Cannot run cancellableCompute without dart:html or dart:io.');
