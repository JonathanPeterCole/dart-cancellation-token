import 'package:meta/meta.dart';

/// A mixin for making a class cancellable using a [CancellationToken].
///
/// This does not handle attaching to and detatching from the token.
///
/// Classes using this mixin should call `isCancelled` and `attach(this)` on the token when they're
/// created, and call `detatch(this)` on the token once complete to prevent memory leaks.
mixin Cancellable {
  /// Called when the attached token is cancelled.
  ///
  /// It's not necessary to detach from the token in this method, as cancellation tokens detach from
  /// all cancellables when cancelled.
  @visibleForOverriding
  void onCancel(Exception cancelException);
}
