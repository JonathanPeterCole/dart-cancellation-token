import 'package:cancellation_token/src/cancellables/cancellable_completer.dart';
import 'package:cancellation_token/src/tokens/cancellation_token.dart';
import 'package:cancellation_token/src/types.dart';

/// Takes a future and creates a new cancellable future.
///
/// For a shortcut to create a cancellable future, use [CancellableFutureExtension.asCancellable].
class CancellableFuture<T> {
  CancellableFuture(
    Future<T> future,
    CancellationToken cancellationToken, {
    OnCancelCallback? onCancel,
  })  : _internalFuture = future,
        _completer = CancellableCompleter(cancellationToken, onCancel: onCancel) {
    _run(future);
  }

  /// The internal future that is being made cancellable.
  final Future<T> _internalFuture;

  /// The completer that handles the cancellation.
  final CancellableCompleter<T> _completer;

  /// Runs the future and handles the result.
  Future<void> _run(Future<T> future) async {
    if (isCancelled) return;
    try {
      final T result = await _internalFuture;
      if (!isCancelled) _completer.complete(result);
    } catch (e, stackTrace) {
      if (!isCancelled) _completer.completeError(e, stackTrace);
    }
  }

  /// The cancellable future.
  ///
  /// If the [CancellationToken] is cancelled, this future will throw the cancellation exception.
  /// Otherwise the future will complete as normal.
  Future<T> get future => _completer.future;

  /// Whether or not the future was cancelled.
  bool get isCancelled => _completer.isCancelled;
}

extension CancellableFutureExtension<T> on Future<T> {
  /// Converts the future to a cancellable future.
  Future<T> asCancellable(
    CancellationToken cancellationToken, {
    OnCancelCallback? onCancel,
  }) {
    return CancellableFuture<T>(this, cancellationToken, onCancel: onCancel).future;
  }
}
