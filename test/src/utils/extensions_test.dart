import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  group('CancellableFutureExtension', () {
    group('asCancellable()', () {
      test('completes with normal value if not cancelled', () {
        final CancellationToken token = CancellationToken();

        expect(
          Future<String>.value('Test value').asCancellable(token),
          completion(equals('Test value')),
        );
      });

      test('completes with normal exception if not cancelled', () {
        final CancellationToken token = CancellationToken();

        expect(
          Future<String>.error(_TestException()).asCancellable(token),
          throwsA(isA<_TestException>()),
        );
      });

      test('completes with CancelledException if cancelled before attach', () {
        final CancellationToken token = CancellationToken()..cancel();

        expect(
          Future<String>.error(Exception()).asCancellable(token),
          throwsA(isA<CancelledException>()),
        );
      });

      test('completes with CancelledException if cancelled after attach', () {
        final CancellationToken token = CancellationToken();
        final Completer<String> completer = Completer<String>();

        expect(
          completer.future.asCancellable(token),
          throwsA(isA<CancelledException>()),
        );

        token.cancel();
      });

      test('detaches from the cancellation token after completing with a value',
          () async {
        final CancellationToken token = CancellationToken();

        await expectLater(
          Future<String>.value('Test value').asCancellable(token),
          completes,
        );

        expect(token.hasCancellables, isFalse);
      });

      test(
          'detaches from the cancellation token after completing with an error',
          () async {
        final CancellationToken token = CancellationToken();

        await expectLater(
          Future<String>.error(_TestException()).asCancellable(token),
          throwsA(isA<_TestException>()),
        );

        expect(token.hasCancellables, isFalse);
      });
    });
  });
}

class _TestException implements Exception {}
