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

    token.cancel();

    expect(cancellableFuture.future, throwsA(isA<CancelledException>()));
  });

  test('completes with normal exception if cancellation token is null', () {
    final Future<String> testFuture = Future<String>.error(_TestException());
    final CancellableFuture<String> cancellableFuture =
        CancellableFuture(testFuture, null);

    expect(cancellableFuture.future, throwsA(isA<_TestException>()));
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
          testFuture.asCancellable(token), throwsA(isA<CancelledException>()));
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();
      final Future<String> cancellableFuture =
          completer.future.asCancellable(token);

      token.cancel();

      expect(cancellableFuture, throwsA(isA<CancelledException>()));
    });
  });
}

class _TestException implements Exception {}
