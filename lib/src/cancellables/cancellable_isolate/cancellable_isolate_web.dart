import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// The dart:html implementation of [CancellableIsolate.run].
Future<R> runImpl<R>(
  FutureOr<R> Function() computation,
  CancellationToken? cancellationToken, {
  String? debugName,
}) =>
    CancellableFuture.from(computation, cancellationToken);
