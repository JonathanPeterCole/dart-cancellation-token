import 'dart:async';
import 'dart:isolate';

import 'package:cancellation_token/cancellation_token.dart';

/// The dart:io implementation of [CancellableIsolate.run].
Future<R> runImpl<R>(
  FutureOr<R> Function() computation,
  CancellationToken? cancellationToken, {
  String? debugName,
}) {
  Isolate? isolate;
  RawReceivePort? resultPort;
  final CancellableCompleter<R> result = CancellableCompleter<R>(
    cancellationToken,
    onCancel: () {
      isolate?.kill();
      resultPort?.close();
      isolate = null;
      resultPort = null;
    },
  );
  // Only attempt to create the receive port and start the isolate if the token
  // hasn't already been cancelled
  if (cancellationToken?.isCancelled != true) {
    // Prepare the receive port to handle the result from the isolate
    resultPort = RawReceivePort()
      ..handler = (response) {
        resultPort?.close();
        resultPort = null;
        isolate = null;
        if (response == null) {
          // onExit handler message, isolate terminated without sending result.
          result.completeError(
            RemoteError("Computation ended without result", ""),
            StackTrace.empty,
          );
          return;
        }
        final List<Object?> list = response as List<Object?>;
        if (list.length == 2) {
          Object? remoteError = list[0];
          Object? remoteStack = list[1];
          if (remoteStack is StackTrace) {
            // Typed error.
            result.completeError(remoteError!, remoteStack);
          } else {
            // onError handler message, uncaught async error.
            // Both values are strings, so calling `toString` is efficient.
            final RemoteError error = RemoteError(
              remoteError.toString(),
              remoteStack.toString(),
            );
            result.completeError(error, error.stackTrace);
          }
        } else {
          assert(list.length == 1);
          result.complete(list[0] as R);
        }
      };
    // Attempt to spawn the isolate
    try {
      Isolate.spawn(
        _RemoteRunner._remoteExecute,
        _RemoteRunner<R>(computation, resultPort!.sendPort),
        onError: resultPort!.sendPort,
        onExit: resultPort!.sendPort,
        errorsAreFatal: true,
        debugName: debugName,
      ).then<void>((spawnedIsolate) {
        isolate = spawnedIsolate;
        // If the token was cancelled whilst starting the isolate, kill it
        if (cancellationToken?.isCancelled == true) {
          isolate?.kill();
          resultPort?.close();
          isolate = null;
          resultPort = null;
        }
      }, onError: (error, stackTrace) {
        // Handle async errors spawning the isolate
        resultPort?.close();
        resultPort = null;
        isolate = null;
        result.completeError(error, stackTrace);
      });
    } on Object catch (error, stackTrace) {
      // Handle sync errors spawning the isolate
      resultPort?.close();
      resultPort = null;
      isolate = null;
      result.completeError(error, stackTrace);
    }
  }
  return result.future;
}

/// Parameter object used by [runImpl].
///
/// The [_remoteExecute] function is run in a new isolate with a
/// [_RemoteRunner] object as argument.
///
/// This code is taken from the
/// [Dart SDK](https://github.com/dart-lang/sdk/blob/2.19.0/sdk/lib/isolate/isolate.dart#L920).
class _RemoteRunner<R> {
  /// User computation to run.
  final FutureOr<R> Function() computation;

  /// Port to send isolate computation result on.
  ///
  /// Only one object is ever sent on this port.
  /// If the value is `null`, it is sent by the isolate's "on-exit" handler
  /// when the isolate terminates without otherwise sending value.
  /// If the value is a list with one element,
  /// then it is the result value of the computation.
  /// Otherwise it is a list with two elements representing an error.
  /// If the error is sent by the isolate's "on-error" uncaught error handler,
  /// then the list contains two strings. This also terminates the isolate.
  /// If sent manually by this class, after capturing the error,
  /// the list contains one non-`null` [Object] and one [StackTrace].
  final SendPort resultPort;

  _RemoteRunner(this.computation, this.resultPort);

  /// Run in a new isolate to get the result of [computation].
  ///
  /// The result is sent back on [resultPort] as a single-element list.
  /// A two-element list sent on the same port is an error result.
  /// When sent by this function, it's always an object and a [StackTrace].
  /// (The same port listens on uncaught errors from the isolate, which
  /// sends two-element lists containing [String]s instead).
  static void _remoteExecute(_RemoteRunner<Object?> runner) {
    runner._run();
  }

  void _run() async {
    R result;
    try {
      final FutureOr<R> potentiallyAsyncResult = computation();
      if (potentiallyAsyncResult is Future<R>) {
        result = await potentiallyAsyncResult;
      } else {
        result = potentiallyAsyncResult;
      }
    } catch (e, s) {
      // If sending fails, the error becomes an uncaught error.
      Isolate.exit(resultPort, _list2(e, s));
    }
    Isolate.exit(resultPort, _list1(result));
  }

  /// Helper function to create a one-element non-growable list.
  static List<Object?> _list1(Object? value) => List.filled(1, value);

  /// Helper function to create a two-element non-growable list.
  static List<Object?> _list2(Object? value1, Object? value2) =>
      List.filled(2, value1)..[1] = value2;
}
