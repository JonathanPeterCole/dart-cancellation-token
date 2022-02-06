import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'cancellable_compute/cancellable_compute_stub.dart'
    if (dart.library.html) 'cancellable_compute/cancellable_compute_browser.dart'
    if (dart.library.io) 'cancellable_compute/cancellable_compute_io.dart';

/// A cancellable implementation of Flutter's `compute()` method.
///
/// Spawns an isolate and runs a callback on that isolate. When cancelled, the
/// isolate is killed.
///
/// Isolates aren't supported when building for web. As a fallback, a future
/// will be returned that completes with either the cancellation exception or
/// the result of the callback, depending on whether or not the
/// CancellationToken was already cancelled when this function was called.
Future<R> cancellableCompute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
  CancellationToken? cancellationToken, {
  String? debugLabel,
}) =>
    cancellableComputeImpl(callback, message, cancellationToken);
