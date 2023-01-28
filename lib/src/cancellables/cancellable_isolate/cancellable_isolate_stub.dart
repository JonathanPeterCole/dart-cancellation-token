import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';

/// Implemented in `cancellable_isolate_io.dart` and
/// `cancellable_isolate_web.dart`.
Future<R> runImpl<R>(
  FutureOr<R> Function() computation,
  CancellationToken? cancellationToken, {
  String? debugName,
}) =>
    throw UnsupportedError('Cannot call run without dart:html or dart:io.');
