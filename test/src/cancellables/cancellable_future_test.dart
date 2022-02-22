import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completes with normal value if not cancelled', () {
    final CancellationToken token = CancellationToken();
    final Future<String> testFuture = Future<String>.value('Test value');
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, token);

    expect(cancellableFuture.future, completion(equals('Test value')));
  });

  test('completes with normal value if cancellation token is null', () {
    final Future<String> testFuture = Future<String>.value('Test value');
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, null);

    expect(cancellableFuture.future, completion(equals('Test value')));
  });

  test('completes with normal exception if not cancelled', () {
    final CancellationToken token = CancellationToken();
    final Future<String> testFuture = Future<String>.error(_TestException());
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, token);

    expect(cancellableFuture.future, throwsA(isA<_TestException>()));
  });

  test('completes with CancelledException if cancelled before attach', () {
    final CancellationToken token = CancellationToken()..cancel();
    final Future<String> testFuture = Future<String>.value('Test value');
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, token);

    expect(cancellableFuture.future, throwsA(isA<CancelledException>()));
  });

  test('completes with CancelledException if cancelled after attach', () {
    final CancellationToken token = CancellationToken();
    final Completer<String> completer = Completer<String>();
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(completer.future, token);

    expect(cancellableFuture.future, throwsA(isA<CancelledException>()));

    token.cancel();
  });

  test('completes with normal exception if cancellation token is null', () {
    final Future<String> testFuture = Future<String>.error(_TestException());
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, null);

    expect(cancellableFuture.future, throwsA(isA<_TestException>()));
  });

  test('detaches from the cancellation token after completing with a value',
      () async {
    final CancellationToken token = CancellationToken();
    final Future<String> testFuture = Future<String>.value('Test value');
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, token);

    await cancellableFuture.future;

    expect(token.hasCancellables, isFalse);
  });

  test('detaches from the cancellation token after completing with an error',
      () async {
    final CancellationToken token = CancellationToken();
    final Future<String> testFuture = Future<String>.error(_TestException());
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, token);

    try {
      await cancellableFuture.future;
    } catch (e) {
      //
    }

    expect(token.hasCancellables, isFalse);
  });

  group('isCancelled', () {
    test('returns true if the completer was cancelled', () {
      final CancellationToken token = CancellationToken()..cancel();
      final Future<String> testFuture = Future<String>.value('Test value');
      final CancellableFuture<String> cancellableFuture =
          CancellableFuture(testFuture, token);

      expect(cancellableFuture.isCancelled, isTrue);
      expect(cancellableFuture.future, throwsException);
    });

    test('returns false if the completer was not cancelled', () {
      final CancellationToken token = CancellationToken();
      final Future<String> testFuture = Future<String>.value('Test value');
      final CancellableFuture<String> cancellableFuture =
          CancellableFuture(testFuture, token);

      expect(cancellableFuture.isCancelled, isFalse);
    });
  });

  group('asCancellable extension', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      final Future<String> testFuture = Future<String>.value('Test value');

      expect(testFuture.asCancellable(token), completion(equals('Test value')));
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      final Future<String> testFuture = Future<String>.error(_TestException());

      expect(testFuture.asCancellable(token), throwsA(isA<_TestException>()));
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

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();
      final Future<String> testFuture = Future<String>.error(_TestException());

      try {
        await testFuture.asCancellable(token);
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });
}

class _TestException implements Exception {}
