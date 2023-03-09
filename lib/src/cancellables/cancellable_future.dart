import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// A class for creating cancellable futures.
///
/// For a shortcut to create a cancellable future, use
/// [CancellableFutureExtension.asCancellable].
class CancellableFuture<T> {
  CancellableFuture._(
    FutureOr<T> future,
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  })  : _internalFuture = future,
        _completer = CancellableCompleter.sync(
          cancellationToken,
          onCancel: onCancel,
        ) {
    _run(future);
  }

  /// Creates a cancellable future containing the result of calling
  /// [computation] asynchronously with [Timer.run].
  ///
  /// This is the cancellable equivalent to `Future()`.
  ///
  /// If the [cancellationToken] has already been cancelled when this is called,
  /// the [computation] will not run.
  static Future<T> from<T>(
    FutureOr<T> Function() computation,
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  }) {
    if (cancellationToken?.isCancelled ?? false) {
      return Future<T>.error(cancellationToken!.exception!);
    } else {
      return CancellableFuture<T>._(
        Future(computation),
        cancellationToken,
        onCancel: onCancel,
      ).future;
    }
  }

  /// Creates a cancellable future containing the result of calling
  /// [computation] asynchronously with [scheduleMicrotask].
  ///
  /// This is the cancellable equivalent to `Future.microtask()`.
  ///
  /// If the [cancellationToken] has already been cancelled when this is called,
  /// the [computation] will not run.
  static Future<T> microtask<T>(
    FutureOr<T> Function() computation,
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  }) {
    if (cancellationToken?.isCancelled ?? false) {
      return Future<T>.error(cancellationToken!.exception!);
    } else {
      return CancellableFuture<T>._(
        Future.microtask(computation),
        cancellationToken,
        onCancel: onCancel,
      ).future;
    }
  }

  /// Returns a future containing the result of immediately calling
  /// [computation], unless cancelled.
  ///
  /// This is the cancellable equivalent to `Future.sync()`.
  ///
  /// If the [cancellationToken] has already been cancelled when this is called,
  /// the [computation] will not run.
  static Future<T> sync<T>(
    FutureOr<T> Function() computation,
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  }) {
    if (cancellationToken?.isCancelled ?? false) {
      return Future<T>.error(cancellationToken!.exception!);
    } else {
      return CancellableFuture<T>._(
        Future.sync(computation),
        cancellationToken,
        onCancel: onCancel,
      ).future;
    }
  }

  /// Returns a future that completes with the given value, unless cancelled.
  ///
  /// This is the cancellable equivalent to `Future.value()`.
  static Future<T> value<T>(
    FutureOr<T> value,
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  }) =>
      CancellableFuture<T>._(
        value,
        cancellationToken,
        onCancel: onCancel,
      ).future;

  /// Creates a future that runs its computation after a delay, unless
  /// cancelled.
  ///
  /// This is the cancellable equivalent to `Future.delayed()`.
  ///
  /// If the [cancellationToken] is cancelled during the delay, the
  /// [computation] will not run, and the cancellation exception will be thrown.
  ///
  /// If the [cancellationToken] is cancelled whilst the [computation] is
  /// running, the cancellation exception will be thrown and the result of the
  /// [computation] will be ignored.
  ///
  /// If you want to run the computation after the delay regardless of whether
  /// or not the [cancellationToken] has been cancelled, you should use
  /// `Future.delayed()` with the `.asCancellable()` extension:
  /// ```
  /// await Future.delayed(Duration(seconds: 5), computation)
  ///     .asCancellable(token);
  /// ```
  static Future<T> delayed<T>(
    Duration duration,
    CancellationToken? cancellationToken, [
    FutureOr<T> Function()? computation,
    OnCancelCallback? onCancel,
  ]) =>
      _DelayedCancellableFuture(
        duration,
        cancellationToken,
        computation,
        onCancel,
      ).future;

  /// The internal future that is being made cancellable.
  final FutureOr<T> _internalFuture;

  /// The completer that handles the cancellation.
  final CancellableCompleter<T> _completer;

  /// Whether or not the future was cancelled.
  bool get _isCancelled => _completer.isCancelled;

  /// Runs the future and handles the result.
  Future<void> _run(FutureOr<T> future) async {
    if (_isCancelled) return;
    try {
      final T result = await _internalFuture;
      if (!_isCancelled) _completer.complete(result);
    } catch (e, stackTrace) {
      if (!_isCancelled) _completer.completeError(e, stackTrace);
    }
  }

  /// The cancellable future.
  ///
  /// If the [CancellationToken] is cancelled, this future will throw the
  /// cancellation exception. Otherwise the future will complete as normal.
  Future<T> get future => _completer.future;
}

/// Internal class for creating basic cancellable delayed futures.
class _DelayedCancellableFuture<T> with Cancellable {
  _DelayedCancellableFuture(
    Duration duration,
    CancellationToken? cancellationToken, [
    FutureOr<T> Function()? computation,
    OnCancelCallback? onCancel,
  ])  : assert(
          null is T || computation != null,
          'A computation is required if T is not nullable.',
        ),
        _computation = computation,
        _onCancelCallback = onCancel,
        _internalCompleter = Completer<T>.sync() {
    final bool attached = maybeAttach(cancellationToken);
    if (attached) _timer = Timer(duration, _onTimerEnd);
  }

  /// The delayed computation.
  final FutureOr<T> Function()? _computation;

  /// The optional cleanup callback that will be called when cancelled.
  final OnCancelCallback? _onCancelCallback;

  /// The internal completer used to provide the future.
  final Completer<T> _internalCompleter;

  /// The timer for handling the delay.
  Timer? _timer;

  /// Runs the computation if there is one an passes the result to the
  /// internal completer if the token wasn't cancelled whilst the computation
  /// was running.
  Future<void> _onTimerEnd() async {
    if (_computation == null) {
      _internalCompleter.complete();
    } else {
      try {
        final T result = await _computation!.call();
        if (_internalCompleter.isCompleted) return;
        _internalCompleter.complete(result);
      } catch (e, stackTrace) {
        if (_internalCompleter.isCompleted) return;
        _internalCompleter.completeError(e, stackTrace);
      }
    }
    detach();
  }

  @override
  void onCancel(Exception cancelException) {
    super.onCancel(cancelException);
    _internalCompleter.completeError(cancelException, cancellationStackTrace);
    _onCancelCallback?.call();
    _timer?.cancel();
  }

  /// The result of this delayed cancellable future.
  ///
  /// If the [CancellationToken] is cancelled before the delay and computation
  /// complete, this future will throw the cancellation exception. Otherwise
  /// the future will complete as normal with the result of the computation
  /// or null.
  Future<T> get future => _internalCompleter.future;
}
