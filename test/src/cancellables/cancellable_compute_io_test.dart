@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completes with normal result if not cancelled', () {
    final CancellationToken token = CancellationToken();

    expect(
      cancellableCompute(_successIsolateTest, 'Test string', token),
      completion(equals('Test string')),
    );
  });

  test('completes with normal result if cancellation token is null', () {
    expect(
      cancellableCompute(_successIsolateTest, 'Test string', null),
      completion(equals('Test string')),
    );
  });

  test('completes with exception if not cancelled and isolate callback throws',
      () async {
    final CancellationToken token = CancellationToken();
    final Exception testException = _TestException();

    expect(
      cancellableCompute(_errorIsolateTest, testException, token),
      throwsA(isA<Exception>()),
    );
  });

  test(
      'completes with exception if cancellation token is null and isolate '
      'callback throws', () async {
    final Exception testException = _TestException();

    expect(
      cancellableCompute(_errorIsolateTest, testException, null),
      throwsA(isA<Exception>()),
    );
  });

  test('detaches from the cancellation token after completing with a value',
      () async {
    final CancellationToken token = CancellationToken();

    await cancellableCompute(_successIsolateTest, 'Test string', null);

    expect(token.hasCancellables, isFalse);
  });

  test('detaches from the cancellation token after completing with an error',
      () async {
    final CancellationToken token = CancellationToken();
    final Exception testException = _TestException();

    try {
      await cancellableCompute(_errorIsolateTest, testException, null);
    } catch (e) {
      //
    }

    expect(token.hasCancellables, isFalse);
  });

  group('completes with a CancelledException', () {
    test('when cancelled before attaching', () {
      final CancellationToken token = CancellationToken()..cancel();

      expect(
        cancellableCompute(_successIsolateTest, 'Test string', token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('when cancelled after attaching', () {
      final CancellationToken token = CancellationToken();
      final Future<String> result =
          cancellableCompute(_infiniteLoopIsolateTest, 'Test string', token);

      expect(result, throwsA(isA<CancelledException>()));

      token.cancel();
    });
  });
}

String _successIsolateTest(String input) {
  sleep(Duration(milliseconds: 100));
  return input;
}

String _errorIsolateTest(Exception input) {
  sleep(Duration(milliseconds: 100));
  throw input;
}

String _infiniteLoopIsolateTest(String input) {
  while (true) {
    sleep(Duration(milliseconds: 100));
  }
}

class _TestException implements Exception {}
