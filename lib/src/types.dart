import 'dart:async';

/// Callback used for cancellables that accept an onCancel param.
typedef OnCancelCallback = FutureOr<void> Function();

/// Callback for cancellableCompute.
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);
