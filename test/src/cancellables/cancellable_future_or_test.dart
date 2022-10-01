import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  group('synchronous computation', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        cancellableFutureOr(() => 'Test value', token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        cancellableFutureOr(() => throw _TestException(), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        cancellableFutureOr(() => 'Test value', token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await cancellableFutureOr(() => 'Test value', token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await cancellableFutureOr(() => throw _TestException(), token);
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });

  group('async computation', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        cancellableFutureOr(() => Future.value('Test value'), token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        cancellableFutureOr(() => Future.error(_TestException()), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        cancellableFutureOr(() => Future.value('Test value'), token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();

      expect(
        cancellableFutureOr(() => completer.future, token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await cancellableFutureOr(() => Future.value('Test value'), token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await cancellableFutureOr(() => Future.error(_TestException()), token);
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });

  test('computation is not run if cancelled before attach', () async {
    final CancellationToken token = CancellationToken()..cancel();

    bool callbackRun = false;
    try {
      await cancellableFutureOr(() => callbackRun = true, token);
    } catch (e) {
      //
    }

    expect(callbackRun, isFalse);
  });
}

class _TestException implements Exception {}
