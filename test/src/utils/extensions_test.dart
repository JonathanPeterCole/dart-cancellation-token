import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  group('CancellableFutureExtension', () {
    group('asCancellable()', () {
      test('completes with normal value if not cancelled', () {
        final CancellationToken token = CancellationToken();
        final Future<String> testFuture = Future<String>.value('Test value');

        expect(
          testFuture.asCancellable(token),
          completion(equals('Test value')),
        );
      });

      test('completes with normal exception if not cancelled', () {
        final CancellationToken token = CancellationToken();
        final Future<String> testFuture =
            Future<String>.error(_TestException());

        expect(
          testFuture.asCancellable(token),
          throwsA(isA<_TestException>()),
        );
      });

      test('completes with CancelledException if cancelled before attach', () {
        final CancellationToken token = CancellationToken()..cancel();
        final Future<String> testFuture = Future<String>.value('Test value');

        expect(
          testFuture.asCancellable(token),
          throwsA(isA<CancelledException>()),
        );
      });

      test('completes with CancelledException if cancelled after attach', () {
        final CancellationToken token = CancellationToken();
        final Completer<String> completer = Completer<String>();
        final Future<String> cancellableFuture =
            completer.future.asCancellable(token);

        expect(cancellableFuture, throwsA(isA<CancelledException>()));

        token.cancel();
      });

      test('detaches from the cancellation token after completing with a value',
          () async {
        final CancellationToken token = CancellationToken();
        final Future<String> testFuture = Future<String>.value('Test value');

        await testFuture.asCancellable(token);

        expect(token.hasCancellables, isFalse);
      });

      test(
          'detaches from the cancellation token after completing with an error',
          () async {
        final CancellationToken token = CancellationToken();
        final Future<String> testFuture =
            Future<String>.error(_TestException());

        try {
          await testFuture.asCancellable(token);
        } catch (e) {
          //
        }

        expect(token.hasCancellables, isFalse);
      });
    });
  });
}

class _TestException implements Exception {}
