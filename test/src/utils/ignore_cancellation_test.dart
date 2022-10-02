import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completes with normal value if not cancelled', () async {
    bool completed = false;
    await ignoreCancellation(() async {
      await Future.value();
      completed = true;
    });

    expect(completed, isTrue);
  });

  test('completes normally if cancelled', () async {
    final CancellationToken token = CancellationToken()..cancel();

    bool completed = false;
    await ignoreCancellation(() async {
      await Future.value().asCancellable(token);
      completed = true;
    });

    expect(completed, isFalse);
  });

  group('onError', () {
    test('rethrows other exceptions if onError is null', () {
      expect(
        ignoreCancellation(() => Future.error(_TestException())),
        throwsA(isA<_TestException>()),
      );
    });

    test('doesn\'t rethrow other exceptions if onError is not null', () {
      expect(
        ignoreCancellation(
          () => Future.error(_TestException()),
          onError: (e, stackTrace) {},
        ),
        completes,
      );
    });

    test('doesn\'t call onError for CancelledExceptions', () async {
      final CancellationToken token = CancellationToken()..cancel();

      Object? exception;
      await ignoreCancellation(
        () => Future.value().asCancellable(token),
        onError: (e, stackTrace) => exception = e,
      );

      expect(exception, isNull);
    });

    test('calls onError if other exceptions are thrown', () async {
      Object? exception;
      await ignoreCancellation(
        () => Future.error(_TestException()),
        onError: (e, stackTrace) => exception = e,
      );

      expect(exception, isNotNull);
    });
  });

  group('whenComplete', () {
    test('is called when the operation completes successfully', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.value(),
        whenComplete: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when the operation throws an exception', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.error(_TestException()),
        onError: (e, stackTrace) => {},
        whenComplete: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is not called when the operation is cancelled', () async {
      final CancellationToken token = CancellationToken()..cancel();

      bool called = false;
      await ignoreCancellation(
        () => Future.value().asCancellable(token),
        whenComplete: () => called = true,
      );

      expect(called, isFalse);
    });
  });

  group('whenCompleteOrCancelled', () {
    test('is called when the operation completes successfully', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.value(),
        whenCompleteOrCancelled: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when the operation throws an exception', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.error(_TestException()),
        onError: (e, stackTrace) => {},
        whenCompleteOrCancelled: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is not called when the operation is cancelled', () async {
      final CancellationToken token = CancellationToken()..cancel();

      bool called = false;
      await ignoreCancellation(
        () => Future.value().asCancellable(token),
        whenCompleteOrCancelled: () => called = true,
      );

      expect(called, isTrue);
    });
  });
}

class _TestException implements Exception {}
