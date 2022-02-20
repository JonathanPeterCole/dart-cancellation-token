import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:meta/meta.dart';

/// A mixin for making a class cancellable using a [CancellationToken].
///
/// This does not handle attaching to and detatching from the token.
///
/// Classes using this mixin should call `maybeAttach(token)` to attach to the
/// token when they're created, and call `token.detatch(this)` on the token once
/// complete to prevent memory leaks.
///
/// Cancellables can have nullable tokens to make them optionally cancellable.
/// In these cases, you can call `maybeAttach(token)` as usual to attach to the
/// token if there is one, and use `token?.detach(this)` to detach when done.
mixin Cancellable {
  /// Attaches to the [CancellationToken] only if it hasn't already been
  /// cancelled. If the token has already been cancelled, onCancel is called
  /// instead.
  ///
  /// Returns `true` if the token is null or hasn't been cancelled yet, so the
  /// async task should continue.
  /// Returns `false` if the token has already been cancelled and the async task
  /// should not continue.
  @protected
  bool maybeAttach(CancellationToken? token) {
    if (token?.isCancelled ?? false) {
      // Schedule the cancellation as a microtask to prevent Futures completing
      // before error handlers are registered
      final StackTrace trace = StackTrace.current;
      scheduleMicrotask(() => onCancel(token!.exception, trace));
      return false;
    } else {
      token?.attach(this);
      return true;
    }
  }

  /// Called when the attached token is cancelled.
  ///
  /// It's not necessary to detach from the token in this method, as
  /// cancellation tokens detach from all cancellables when cancelled.
  void onCancel(Exception cancelException, [StackTrace? trace]);
}
