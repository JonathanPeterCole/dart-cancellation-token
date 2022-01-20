import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// The dart:html implementation of cancellableCompute().
Future<R> cancellableComputeImpl<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
  CancellationToken cancellationToken, {
  String? debugLabel,
}) async {
  await null;
  if (cancellationToken.isCancelled) {
    throw cancellationToken.exception;
  } else {
    return callback(message);
  }
}
