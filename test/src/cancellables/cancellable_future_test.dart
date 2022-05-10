import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completion order matches Future', () async {
    // Based on a post comparing the behaviours of Future constructors:
    // https://www.reddit.com/r/dartlang/comments/pmdkzh/serious_future_vs_futurevalue_vs_futuresync_vs/

    final List<int> futureResults = [];
    await Future.wait([
      Future(() => 1).then(futureResults.add),
      Future(() => Future(() => 2)).then(futureResults.add),
      Future.value(3).then(futureResults.add),
      Future.value(Future(() => 4)).then(futureResults.add),
      Future.sync(() => 5).then(futureResults.add),
      Future.sync(() => Future.value(6)).then(futureResults.add),
      Future.microtask(() => 7).then(futureResults.add),
      Future.microtask(() => Future.value(8)).then(futureResults.add),
      Future(() => 9).then(futureResults.add),
      Future(() => Future(() => 10)).then(futureResults.add),
    ]);

    final List<int> cancellableResults = [];
    await Future.wait([
      CancellableFuture.from(() => 1, null).then(cancellableResults.add),
      CancellableFuture.from(() => Future(() => 2), null)
          .then(cancellableResults.add),
      CancellableFuture.value(3, null).then(cancellableResults.add),
      CancellableFuture.value(Future(() => 4), null)
          .then(cancellableResults.add),
      CancellableFuture.sync(() => 5, null).then(cancellableResults.add),
      CancellableFuture.sync(() => Future.value(6), null)
          .then(cancellableResults.add),
      CancellableFuture.microtask(() => 7, null).then(cancellableResults.add),
      CancellableFuture.microtask(() => Future.value(8), null)
          .then(cancellableResults.add),
      CancellableFuture.from(() => 9, null).then(cancellableResults.add),
      CancellableFuture.from(() => Future(() => 10), null)
          .then(cancellableResults.add),
    ]);

    expect(cancellableResults, futureResults);
  });

  group('CancellableFuture.from()', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.from(() => Future.value('Test value'), token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal value if cancellation token is null', () {
      expect(
        CancellableFuture.from(() => Future.value('Test value'), null),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.from(() => Future.error(_TestException()), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        CancellableFuture.from(() => Future.value('Test value'), token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('computation is not run if cancelled before attach', () async {
      final CancellationToken token = CancellationToken()..cancel();

      bool callbackRun = false;
      try {
        await CancellableFuture.from(() => callbackRun = true, token);
      } catch (e) {
        //
      }

      expect(callbackRun, isFalse);
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();

      expect(
        CancellableFuture.from(() => completer.future, token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('completes with normal exception if cancellation token is null', () {
      expect(
        CancellableFuture.from(() => Future.error(_TestException()), null),
        throwsA(isA<_TestException>()),
      );
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await CancellableFuture.from(() => Future.value('Test value'), token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await CancellableFuture.from(
          () => Future.error(_TestException()),
          token,
        );
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });

  group('CancellableFuture.microtask()', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.microtask(() => Future.value('Test value'), token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal value if cancellation token is null', () {
      expect(
        CancellableFuture.microtask(() => Future.value('Test value'), null),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.microtask(
            () => Future.error(_TestException()), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        CancellableFuture.microtask(() => Future.value('Test value'), token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('computation is not run if cancelled before attach', () async {
      final CancellationToken token = CancellationToken()..cancel();

      bool callbackRun = false;
      try {
        await CancellableFuture.microtask(() => callbackRun = true, token);
      } catch (e) {
        //
      }

      expect(callbackRun, isFalse);
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();

      expect(
        CancellableFuture.microtask(() => completer.future, token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('completes with normal exception if cancellation token is null', () {
      expect(
        CancellableFuture.microtask(() => Future.error(_TestException()), null),
        throwsA(isA<_TestException>()),
      );
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await CancellableFuture.microtask(
          () => Future.value('Test value'), token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await CancellableFuture.microtask(
          () => Future.error(_TestException()),
          token,
        );
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });

  group('CancellableFuture.sync()', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.sync(() => Future.value('Test value'), token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal value if cancellation token is null', () {
      expect(
        CancellableFuture.sync(() => Future.value('Test value'), null),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.sync(() => Future.error(_TestException()), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        CancellableFuture.sync(() => Future.value('Test value'), token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('computation is not run if cancelled before attach', () async {
      final CancellationToken token = CancellationToken()..cancel();

      bool callbackRun = false;
      try {
        await CancellableFuture.sync(() => callbackRun = true, token);
      } catch (e) {
        //
      }

      expect(callbackRun, isFalse);
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();

      expect(
        CancellableFuture.sync(() => completer.future, token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('completes with normal exception if cancellation token is null', () {
      expect(
        CancellableFuture.sync(() => Future.error(_TestException()), null),
        throwsA(isA<_TestException>()),
      );
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await CancellableFuture.sync(() => Future.value('Test value'), token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await CancellableFuture.sync(
          () => Future.error(_TestException()),
          token,
        );
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
    });
  });

  group('CancellableFuture.value()', () {
    test('completes with normal value if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.value('Test value', token),
        completion(equals('Test value')),
      );
    });

    test('completes with normal value if cancellation token is null', () {
      expect(
        CancellableFuture.value('Test value', null),
        completion(equals('Test value')),
      );
    });

    test('completes with normal exception if not cancelled', () {
      final CancellationToken token = CancellationToken();
      expect(
        CancellableFuture.value(Future.error(_TestException()), token),
        throwsA(isA<_TestException>()),
      );
    });

    test('completes with CancelledException if cancelled before attach', () {
      final CancellationToken token = CancellationToken()..cancel();
      expect(
        CancellableFuture.value('Test value', token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('completes with CancelledException if cancelled after attach', () {
      final CancellationToken token = CancellationToken();
      final Completer<String> completer = Completer<String>();

      expect(
        CancellableFuture.value(() => completer.future, token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('completes with normal exception if cancellation token is null', () {
      expect(
        CancellableFuture.value(Future.error(_TestException()), null),
        throwsA(isA<_TestException>()),
      );
    });

    test('detaches from the cancellation token after completing with a value',
        () async {
      final CancellationToken token = CancellationToken();
      await CancellableFuture.value(Future.value('Test value'), token);

      expect(token.hasCancellables, isFalse);
    });

    test('detaches from the cancellation token after completing with an error',
        () async {
      final CancellationToken token = CancellationToken();

      try {
        await CancellableFuture.value(Future.error(_TestException()), token);
      } catch (e) {
        //
      }

      expect(token.hasCancellables, isFalse);
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
