import 'dart:async';

import 'package:cancellation_token/src/cancellables/cancellable.dart';
import 'package:cancellation_token/src/tokens/cancellation_token.dart';
import 'package:cancellation_token/src/types.dart';

/// A [Completer] that can be cancelled using a [CancellationToken].
///
/// An optional `onCancel` callback can be provided to clean up resources when
/// the completer is cancelled.
class CancellableCompleter<T> with Cancellable implements Completer<T> {
  CancellableCompleter(
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  })  : _cancellationToken = cancellationToken,
        _onCancelCallback = onCancel,
        _internalCompleter = Completer<T>() {
    maybeAttach(cancellationToken);
  }

  /// Creates a CancellableCompleter that completes synchronously, similar to
  /// `Completer.sync()`.
  ///
  /// To prevent the future completing with an error before error handlers are
  /// registered, this will not complete synchronously if it's created with a
  /// CancellationToken that's already been cancelled.
  CancellableCompleter.sync(
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  })  : _cancellationToken = cancellationToken,
        _onCancelCallback = onCancel,
        _internalCompleter = Completer<T>.sync() {
    maybeAttach(cancellationToken);
  }

  /// The [CancellationToken] that this completer can be cancelled by.
  final CancellationToken? _cancellationToken;

  /// The optional cleanup callback that should be called when cancelled.
  final OnCancelCallback? _onCancelCallback;

  /// The internal completer used to provide the future.
  final Completer<T> _internalCompleter;

  /// Whether or not the completer was cancelled.
  bool get isCancelled => _cancellationToken?.isCancelled ?? false;

  @override
  bool get isCompleted => _internalCompleter.isCompleted;

  @override
  Future<T> get future => _internalCompleter.future;

  @override
  void complete([FutureOr<T>? value]) {
    if (isCancelled) return;
    _cancellationToken?.detach(this);
    _internalCompleter.complete(value);
  }

  @override
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (isCancelled) return;
    _cancellationToken?.detach(this);
    _internalCompleter.completeError(error, stackTrace);
  }

  @override
  void onCancel(Exception cancelException, [StackTrace? stackTrace]) {
    _internalCompleter.completeError(
      cancelException,
      stackTrace ?? StackTrace.current,
    );
    _onCancelCallback?.call();
  }
}
