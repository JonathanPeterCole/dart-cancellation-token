import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:meta/meta.dart';

const bool _releaseMode = bool.fromEnvironment('dart.vm.product');

/// The dart:io implementation of cancellableCompute().
Future<R> cancellableComputeImpl<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
  CancellationToken? cancellationToken, {
  String? debugLabel,
}) =>
    _CancellableCompute(
      callback,
      message,
      cancellationToken,
      debugLabel: debugLabel,
    ).result;

/// Supporting class of [cancellableCompute].
///
/// Handles the lifecycle and cancellation of the isolate.
class _CancellableCompute<Q, R> with Cancellable {
  _CancellableCompute(
    this.callback,
    this.message,
    this.cancellationToken, {
    String? debugLabel,
  }) : debugLabel = debugLabel ??
            (_releaseMode ? 'cancellableCompute' : callback.toString()) {
    startIsolate();
  }

  final CancellationToken? cancellationToken;
  final ComputeCallback<Q, R> callback;
  final Q message;
  final String debugLabel;
  final Completer<R> completer = Completer<R>.sync();

  Flow? flow;
  Isolate? isolate;
  RawReceivePort? port;

  /// Gets a future that completes with the result.
  Future<R> get result => completer.future;

  /// Spawns the isolate and attaches to the cancellation token.
  Future<void> startIsolate() async {
    // Attach to the cancellation token before spawning the isolate
    if (!maybeAttach(cancellationToken)) return;
    // Prepare the ReceivePort and add the start to the timeline
    flow = Flow.begin();
    Timeline.startSync('$debugLabel: start', flow: flow);
    port = RawReceivePort();
    Timeline.finishSync();
    // Set the port message handler
    port!.handler = onPortMessage;
    // Spawn the isolate
    try {
      isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
        _spawn,
        _IsolateConfiguration<Q, FutureOr<R>>(
          callback,
          message,
          port!.sendPort,
          debugLabel,
          flow!.id,
        ),
        errorsAreFatal: true,
        onExit: port!.sendPort,
        onError: port!.sendPort,
        debugName: debugLabel,
      );
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }
      closePort();
      return;
    }
    // Kill the isolate immediately if the token was cancelled whilst the
    // isolate was spawning
    if (cancellationToken?.isCancelled ?? false) return killIsolate();
  }

  /// Handles the exit message from the isolate.
  void onPortMessage(dynamic msg) {
    isolate = null;
    closePort();
    if (completer.isCompleted) return;
    // Handle the message
    try {
      // Handle empty messages
      if (msg == null) {
        throw RemoteError('Isolate exited without result or error.', '');
      }
      // Check that the message has the expected runtime type
      assert(msg is List<dynamic>);
      // Get the message type and check that it's within the expected range
      final int type = msg.length;
      assert(1 <= type && type <= 3);
      // Complete with the result
      switch (type) {
        // success; see _buildSuccessResponse
        case 1:
          return completer.complete(msg[0] as R);
        // native error; see Isolate.addErrorListener
        case 2:
          return completer.completeError(RemoteError(
            msg[0] as String,
            msg[1] as String,
          ));
        // caught error; see _buildErrorResponse
        case 3:
        default:
          assert(type == 3 && msg[2] == null);
          return completer.completeError(
            msg[0] as Object,
            msg[1] as StackTrace,
          );
      }
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
    }
  }

  /// Kills the isolate early and closes the ReceivePorts.
  void killIsolate() {
    isolate?.kill();
    isolate = null;
    closePort();
  }

  /// Closes the ReceivePort and adds end to the timeline.
  void closePort() {
    if (port != null) {
      Timeline.startSync('$debugLabel: end', flow: Flow.end(flow!.id));
      port!.close();
      Timeline.finishSync();
    }
  }

  /// Completes early and kills the isolate.
  @override
  void onCancel(Exception cancelException, [StackTrace? trace]) {
    if (!completer.isCompleted) {
      completer.completeError(cancelException, trace ?? StackTrace.current);
    }
    killIsolate();
  }
}

/// Isolate configuration taken from the Flutter SDK.
@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }
}

/// The spawn point MUST guarantee only one result event is sent through the
/// [SendPort.send] be it directly or indirectly i.e. [Isolate.exit].
///
/// In case an [Error] or [Exception] are thrown AFTER the data
/// is sent, they will NOT be handled or reported by the main [Isolate] because
/// it stops listening after the first event is received.
///
/// Also use the helpers [_buildSuccessResponse] and [_buildErrorResponse] to
/// build the response
Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) async {
  late final List<dynamic> computationResult;

  try {
    computationResult =
        _buildSuccessResponse(await configuration.applyAndTime());
  } catch (e, s) {
    computationResult = _buildErrorResponse(e, s);
  }

  Isolate.exit(configuration.resultPort, computationResult);
}

/// Wrap in [List] to ensure our expectations in the main [Isolate] are met.
///
/// We need to wrap a success result in a [List] because the user provided type
/// [R] could also be a [List]. Meaning, a check `result is R` could return true
/// for what was an error event.
List<R> _buildSuccessResponse<R>(R result) {
  return List<R>.filled(1, result);
}

/// Wrap in [List] to ensure our expectations in the main isolate are met.
///
/// We wrap a caught error in a 3 element [List]. Where the last element is
/// always null. We do this so we have a way to know if an error was one we
/// caught or one thrown by the library code.
List<dynamic> _buildErrorResponse(Object error, StackTrace stack) {
  return List<dynamic>.filled(3, null)
    ..[0] = error
    ..[1] = stack;
}
