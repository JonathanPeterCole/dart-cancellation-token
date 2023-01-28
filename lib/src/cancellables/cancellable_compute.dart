import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// A cancellable implementation of Flutter's `compute()` method.
///
/// Runs [callback] in a new isolate and returns the result. When
/// cancelled, the isolate is killed.
///
/// Calls [CancellableIsolate.run] internally.
Future<R> cancellableCompute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
  CancellationToken? cancellationToken, {
  String? debugLabel,
}) {
  const bool releaseMode = bool.fromEnvironment('dart.vm.product');
  debugLabel ??= releaseMode ? 'cancellableCompute' : callback.toString();
  return CancellableIsolate.run<R>(
    () => callback(message),
    cancellationToken,
    debugName: debugLabel,
  );
}
