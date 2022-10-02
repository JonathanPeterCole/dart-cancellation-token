import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// Converts a [FutureOr] to a cancellable [Future].
///
/// This function exists to make the cancellation_token package easier to use,
/// and calls [CancellableFuture.from] internally.
///
/// If [cancellationToken] is already cancelled when this function is called,
/// the computation won't run.
///
/// ### Why isn't there a `.asCancellable()` extension for [FutureOr]?
///
/// When a cancellable is invoked using a [CancellationToken] that's already
/// been cancelled, it's expected to throw the cancellation exception.
///
/// When working with a [FutureOr] value, this behaviour is possible using an
/// `.asCancellable()` extension as synchronous values cannot throw an
/// exception. However, when working with a [FutureOr] callback, the callback
/// must be invoked before the cancellation is applied, leading to unexpected
/// behaviour that can't be caught at build time.
///
/// ```dart
/// // This would throw the callback's CallbackException before cancellation
/// // is applied:
/// final CancellationToken token = CancellationToken()..cancel();
/// FutureOr<String> testCallback() => throw CallbackException();
/// return await testCallback().asCancellable(token);
/// ```
///
/// To reduce the risk of difficult to diagnose errors, this function covers
/// both scenarios with the expected behaviour.
Future<T> cancellableFutureOr<T>(
  FutureOr<T> Function() computation,
  CancellationToken? cancellationToken, {
  OnCancelCallback? onCancel,
}) {
  return CancellableFuture.from(
    computation,
    cancellationToken,
    onCancel: onCancel,
  );
}
