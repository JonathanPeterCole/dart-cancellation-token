import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

extension CancellableFutureExtension<T> on Future<T> {
  /// Converts the [Future] to a cancellable [Future].
  ///
  /// See also:
  ///
  ///    * [cancellableFutureOr], which provides similar functionality for
  ///      [FutureOr].
  Future<T> asCancellable(
    CancellationToken? cancellationToken, {
    OnCancelCallback? onCancel,
  }) =>
      CancellableFuture.value(this, cancellationToken, onCancel: onCancel);
}
