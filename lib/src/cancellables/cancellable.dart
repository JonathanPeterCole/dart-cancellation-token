import 'package:cancellation_token/cancellation_token.dart';
import 'package:meta/meta.dart';

/// A mixin for making a class cancellable using a [CancellationToken].
///
/// This does not handle attaching to and detatching from the token.
///
/// Classes using this mixin should call `isCancelled` and `attach(this)` on the token when they're
/// created, and call `detatch(this)` on the token once complete to prevent memory leaks.
mixin Cancellable {
  /// Attaches to the [CancellationToken] only if it hasn't already been cancelled. If the token has
  /// already been cancelled, onCancel is called instead.
  ///
  /// Returns `true` if attached to the token.
  /// Returns `false` if the token has already been cancelled.
  @protected
  bool maybeAttach(CancellationToken token) {
    if (token.isCancelled) {
      onCancel(token.exception);
      return false;
    } else {
      token.attach(this);
      return true;
    }
  }

  /// Called when the attached token is cancelled.
  ///
  /// It's not necessary to detach from the token in this method, as cancellation tokens detach from
  /// all cancellables when cancelled.
  @visibleForOverriding
  void onCancel(Exception cancelException);
}
