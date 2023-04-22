import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// Runs an operation and silently catches cancellations. Other exceptions can
/// be handled using [onError]. If [onError] is null, exceptions will be
/// rethrown.
///
/// If a custom exception is passed when cancelling the CancellationToken, it
/// won't be handled by this function.
///
/// ### Inside a try/catch
///
/// ```dart
/// try {
///   await ignoreCancellation(() async {
///     response = await apiEndpoint().asCancellable(cancellationToken);
///   });
/// } catch (e, stackTrace) {
///   // Other errors will be rethrown
/// }
/// ```
///
/// ### Outside of a try/catch
///
/// ```dart
/// ignoreCancellation(
///   () async {
///     response = await apiEndpoint().asCancellable(cancellationToken);
///   },
///   onError: (e, stackTrace) {
///     // This is the equivalent of a catch block
///   },
///   whenComplete: () {
///     // This is similar to a finally block, but is only called if the
///     // operation wasn't cancelled
///   },
///   whenCompleteOrCancelled: () {
///     // This is the equivalent of a finally block
///   },
/// );
/// ```
Future<void> ignoreCancellation(
  FutureOr<dynamic> Function() operation, {
  FutureOr<void> Function(Object e, StackTrace stackTrace)? onError,
  FutureOr<void> Function()? whenComplete,
  FutureOr<void> Function()? whenCompleteOrCancelled,
}) async {
  try {
    await operation();
    await whenComplete?.call();
  } on CancelledException {
    // Ignore cancellation
  } catch (e, stackTrace) {
    try {
      if (onError != null) {
        await onError.call(e, stackTrace);
      } else {
        rethrow;
      }
    } finally {
      await whenComplete?.call();
    }
  } finally {
    await whenCompleteOrCancelled?.call();
  }
}
