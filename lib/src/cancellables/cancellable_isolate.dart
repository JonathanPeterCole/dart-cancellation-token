import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'cancellable_isolate/cancellable_isolate_stub.dart'
    if (dart.library.html) 'cancellable_isolate/cancellable_isolate_web.dart'
    if (dart.library.io) 'cancellable_isolate/cancellable_isolate_io.dart';

/// A class for creating cancellable isolates.
class CancellableIsolate {
  /// A cancellable implementation of Dart's `Isolate.run` method.
  ///
  /// Runs [computation] in a new isolate and returns the result. When
  /// cancelled, the isolate is killed.
  ///
  /// When building for web, this uses [CancellableFuture.from] as a fallback
  /// due to isolates not being supported.
  static Future<R> run<R>(
    FutureOr<R> Function() computation,
    CancellationToken? cancellationToken, {
    String? debugName,
  }) =>
      runImpl(computation, cancellationToken, debugName: debugName);
}
