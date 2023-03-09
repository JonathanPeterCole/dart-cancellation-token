import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:meta/meta.dart';

/// A mixin for making a class cancellable using a [CancellationToken].
///
/// To implement this mixin on a custom cancellable:
/// * Call [maybeAttach] to attach to the token before starting async work.
///   If `false` is returned, the token has already been cancelled and no async
///   operations should be started.
/// * Override [onCancel] to handle cancellation.
/// * Call [detach] after all async operations complete.
///
/// It's good practice to make any token parameters nullable to make
/// cancellation optional.
///
/// ```dart
/// class MyCancellable with Cancellable {
///   MyCancellable(this.cancellationToken) {
///     // Call `maybeAttach()` to only attach if the cancellation token hasn't
///     // already been cancelled
///     if (maybeAttach(this.cancellationToken)) {
///       // Start your async task here
///     }
///   }
///
///   final CancellationToken cancellationToken;
///
///   @override
///   void onCancel(Exception cancelException) {
///     super.onCancel(exception);
///     // Clean up resources here, like closing an HttpClient, and complete
///     // any futures or streams
///   }
///
///   void complete() {
///     // If your async task completes before the token is cancelled,
///     // detatch from the token
///     detach();
///   }
/// }
/// ```
mixin Cancellable {
  CancellationToken? _attachedToken;
  bool _isCancelled = false;

  /// The stack trace at the time this cancellable was created.
  ///
  /// This should be included when throwing on cancellation to make it easier
  /// to identify uncaught cancellations.
  final StackTrace cancellationStackTrace = StackTrace.current;

  /// Whether or not the operation has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Attaches to the [CancellationToken] only if it hasn't already been
  /// cancelled. If the token has already been cancelled, onCancel is called
  /// instead.
  ///
  /// Returns `true` if the token is null or hasn't been cancelled yet, so the
  /// async task should continue.
  /// Returns `false` if the token has already been cancelled and the async task
  /// should not continue.
  @protected
  @mustCallSuper
  bool maybeAttach(CancellationToken? token) {
    _isCancelled = token?.isCancelled ?? false;
    if (isCancelled) {
      // Schedule the cancellation as a microtask to prevent Futures completing
      // before error handlers are registered
      scheduleMicrotask(() => onCancel(token!.exception!));
      return false;
    } else {
      _attachedToken = token;
      _attachedToken?.attachCancellable(this);
      return true;
    }
  }

  /// Detatches from the [CancellationToken]. This should be called after
  /// completing without cancellation.
  @protected
  @mustCallSuper
  void detach() {
    _attachedToken?.detachCancellable(this);
    _attachedToken = null;
  }

  /// Called when the attached token is cancelled.
  ///
  /// It's not necessary to detach from the token in this method, as
  /// cancellation tokens detach from all cancellables automatically when
  /// cancelled.
  @mustCallSuper
  void onCancel(Exception cancelException) {
    _attachedToken = null;
    _isCancelled = true;
  }
}
