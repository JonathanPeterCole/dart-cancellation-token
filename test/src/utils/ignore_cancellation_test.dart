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

  test('rethrows operation exceptions if onError is null', () {
    expect(
      ignoreCancellation(() => Future.error(_OperationException())),
      throwsA(isA<_OperationException>()),
    );
  });

  test('rethrows other exceptions if onError is null', () {
    expect(
      ignoreCancellation(() => Future.error(_OperationException())),
      throwsA(isA<_OperationException>()),
    );
  });

  test('doesn\'t rethrow operation exceptions if onError is not null', () {
    expect(
      ignoreCancellation(
        () => Future.error(_OperationException()),
        onError: (e, stackTrace) {},
      ),
      completes,
    );
  });

  test('rethrows onError exceptions', () {
    expect(
      ignoreCancellation(
        () => Future.error(_OperationException()),
        onError: (e, stackTrace) => throw _OnErrorException(),
      ),
      throwsA(isA<_OnErrorException>()),
    );
  });

  group('onError', () {
    test('is called if operation throws an exception', () async {
      Object? exception;
      await ignoreCancellation(
        () => Future.error(_OperationException()),
        onError: (e, stackTrace) => exception = e,
      );

      expect(exception, isNotNull);
    });

    test('is not called if operation throws CancelledExceptions', () async {
      final CancellationToken token = CancellationToken()..cancel();

      Object? exception;
      await ignoreCancellation(
        () => Future.value().asCancellable(token),
        onError: (e, stackTrace) => exception = e,
      );

      expect(exception, isNull);
    });
  });

  group('whenComplete', () {
    test('is called when operation completes successfully', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.value(),
        whenComplete: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when operation throws an exception and onError is null',
        () async {
      bool called = false;
      await expectLater(
        ignoreCancellation(
          () => Future.error(_OperationException()),
          whenComplete: () => called = true,
        ),
        throwsA(isA<_OperationException>()),
      );

      expect(called, isTrue);
    });

    test('is called when operation throws an exception and onError is not null',
        () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.error(_OperationException()),
        onError: (e, stackTrace) {},
        whenComplete: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when onError throws an exception', () async {
      bool called = false;
      await expectLater(
        ignoreCancellation(
          () => Future.error(_OperationException()),
          onError: (e, stackTrace) => throw _OnErrorException(),
          whenComplete: () => called = true,
        ),
        throwsA(isA<_OnErrorException>()),
      );

      expect(called, isTrue);
    });

    test('is not called when operation is cancelled', () async {
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
    test('is called when operation completes successfully', () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.value(),
        whenCompleteOrCancelled: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when operation throws an exception and onError is null',
        () async {
      bool called = false;
      await expectLater(
        ignoreCancellation(
          () => Future.error(_OperationException()),
          whenCompleteOrCancelled: () => called = true,
        ),
        throwsA(isA<_OperationException>()),
      );

      expect(called, isTrue);
    });

    test('is called when operation throws an exception and onError is not null',
        () async {
      bool called = false;
      await ignoreCancellation(
        () => Future.error(_OperationException()),
        onError: (e, stackTrace) {},
        whenCompleteOrCancelled: () => called = true,
      );

      expect(called, isTrue);
    });

    test('is called when onError throws an exception', () async {
      bool called = false;
      await expectLater(
        ignoreCancellation(
          () => Future.error(_OperationException()),
          onError: (e, stackTrace) => throw _OnErrorException(),
          whenCompleteOrCancelled: () => called = true,
        ),
        throwsA(isA<_OnErrorException>()),
      );

      expect(called, isTrue);
    });

    test('is not called when operation is cancelled', () async {
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

class _OperationException implements Exception {}

class _OnErrorException implements Exception {}
