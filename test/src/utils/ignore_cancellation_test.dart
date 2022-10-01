import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completes with normal value if not cancelled', () async {
    final CancellationToken token = CancellationToken();

    bool completed = false;
    await ignoreCancellation(() async {
      await Future.delayed(Duration(seconds: 1)).asCancellable(token);
      completed = true;
    });

    expect(completed, isTrue);
  });

  test('completes with normally if cancelled', () async {
    final CancellationToken token = CancellationToken()..cancel();

    bool completed = false;
    await ignoreCancellation(() async {
      await Future.delayed(Duration(seconds: 1)).asCancellable(token);
      completed = true;
    });

    expect(completed, isFalse);
  });

  test('rethrows other exceptions', () async {
    final CancellationToken token = CancellationToken()
      ..cancel(_TestException());

    Object? caughtException;
    try {
      await ignoreCancellation(() async {
        await Future.delayed(Duration(seconds: 1)).asCancellable(token);
      });
    } catch (e) {
      caughtException = e;
    }

    expect(caughtException, isA<_TestException>());
  });
}

class _TestException implements Exception {}
