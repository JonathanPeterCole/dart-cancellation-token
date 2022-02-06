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
  final Completer<R> completer = Completer<R>();

  bool isolateRunning = false;
  Flow? flow;
  Isolate? isolate;
  ReceivePort? resultPort;
  ReceivePort? exitPort;
  ReceivePort? errorPort;

  /// Gets a future that completes with the result.
  Future<R> get result => completer.future;

  /// Spawns the isolate and attaches to the cancellation token.
  Future<void> startIsolate() async {
    // Attach to the cancellation token before spawning the isolate
    if (!maybeAttach(cancellationToken)) return;
    // Prepare the ReceivePorts and adds the start to the timeline
    flow = Flow.begin();
    Timeline.startSync('$debugLabel: start', flow: flow);
    resultPort = ReceivePort();
    errorPort = ReceivePort();
    exitPort = ReceivePort();
    Timeline.finishSync();
    // Spawn the isolate
    isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
      _spawn,
      _IsolateConfiguration<Q, FutureOr<R>>(
        callback,
        message,
        resultPort!.sendPort,
        debugLabel,
        flow!.id,
      ),
      errorsAreFatal: true,
      onExit: exitPort!.sendPort,
      onError: errorPort!.sendPort,
    );
    isolateRunning = true;
    // Kill the isolate immediately if the token was cancelled whilst the
    // isolate was spawning
    if (cancellationToken?.isCancelled ?? false) return killIsolate();
    // Listen to the ports
    resultPort!.listen(onResult);
    errorPort!.listen(onError);
    exitPort!.listen(onExit);
  }

  /// Handles the result from the isolate.
  void onResult(dynamic resultData) {
    if (!completer.isCompleted) completer.complete(resultData as R);
  }

  /// Handles errors from the isolate.
  void onError(dynamic errorData) {
    assert(errorData is List<dynamic>);
    if (errorData is List<dynamic>) {
      assert(errorData.length == 2);
      final Exception exception = Exception(errorData[0]);
      final StackTrace stack = StackTrace.fromString(errorData[1] as String);
      if (completer.isCompleted) {
        Zone.current.handleUncaughtError(exception, stack);
      } else {
        completer.completeError(exception, stack);
      }
    }
  }

  /// Handles the isolate exiting and cleans up.
  void onExit(dynamic exitData) {
    if (!completer.isCompleted) {
      completer
          .completeError(Exception('Isolate exited without result or error.'));
    }
    isolateRunning = false;
    cancellationToken?.detach(this);
    closePorts();
  }

  /// Kills the isolate early and closes the ReceivePorts.
  void killIsolate() {
    if (!isolateRunning) return;
    isolate?.kill(priority: 0);
    isolateRunning = false;
    closePorts();
  }

  /// Closes the ReceivePorts and adds end to the timeline.
  void closePorts() {
    if (flow != null) {
      Timeline.startSync('$debugLabel: end', flow: Flow.end(flow!.id));
    }
    resultPort?.close();
    exitPort?.close();
    errorPort?.close();
    Timeline.finishSync();
  }

  /// Completes early and kills the isolate.
  @override
  void onCancel(Exception cancelException) {
    if (!completer.isCompleted) completer.completeError(cancelException);
    if (isolateRunning) killIsolate();
  }
}

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

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(
    _IsolateConfiguration<Q, FutureOr<R>> configuration) async {
  final R result = await Timeline.timeSync(
    configuration.debugLabel,
    () async {
      final FutureOr<R> applicationResult = await configuration.apply();
      return await applicationResult;
    },
    flow: Flow.step(configuration.flowId),
  );
  Timeline.timeSync(
    '${configuration.debugLabel}: exiting and returning a result',
    () {},
    flow: Flow.step(configuration.flowId),
  );
  Isolate.exit(configuration.resultPort, result);
}
