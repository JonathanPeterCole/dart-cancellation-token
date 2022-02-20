import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  test('cancels all attached cancellables on manual cancellation', () {
    final TimeoutCancellationToken token =
        TimeoutCancellationToken(Duration(minutes: 1));
    final Exception testException = Exception('Test exception');

    Exception? cancelledWithA;
    final _TestCancellable testCancellableA =
        _TestCancellable((exception) => cancelledWithA = exception);
    Exception? cancelledWithB;
    final _TestCancellable testCancellableB =
        _TestCancellable((exception) => cancelledWithB = exception);

    token
      ..attach(testCancellableA)
      ..attach(testCancellableB)
      ..cancel(testException);

    expect(cancelledWithA, equals(testException));
    expect(cancelledWithB, equals(testException));
  });

  test('detached cancellables are not cancelled', () {
    final TimeoutCancellationToken token =
        TimeoutCancellationToken(Duration(minutes: 1));

    bool cancelled = false;
    final _TestCancellable testCancellable =
        _TestCancellable((exception) => cancelled = false);

    token
      ..attach(testCancellable)
      ..detach(testCancellable)
      ..cancel();

    expect(cancelled, isFalse);
  });

  group('cancels all attached cancellables after the timeout period', () {
    test('with the default TimeoutException', () {
      fakeAsync((async) {
        final TimeoutCancellationToken token =
            TimeoutCancellationToken(Duration(minutes: 1));

        Exception? cancelledWithA;
        final _TestCancellable testCancellableA =
            _TestCancellable((exception) => cancelledWithA = exception);
        Exception? cancelledWithB;
        final _TestCancellable testCancellableB =
            _TestCancellable((exception) => cancelledWithB = exception);

        token
          ..attach(testCancellableA)
          ..attach(testCancellableB);

        expect(cancelledWithA, isNull);
        expect(cancelledWithB, isNull);

        async.elapse(Duration(minutes: 1));

        expect(cancelledWithA, TypeMatcher<TimeoutException>());
        expect(cancelledWithB, TypeMatcher<TimeoutException>());
      });
    });

    test('with a custom exception', () {
      fakeAsync((async) {
        final Exception testException = Exception('Test exception');
        final TimeoutCancellationToken token = TimeoutCancellationToken(
          Duration(minutes: 1),
          timeoutException: testException,
        );

        Exception? cancelledWithA;
        final _TestCancellable testCancellableA =
            _TestCancellable((exception) => cancelledWithA = exception);
        Exception? cancelledWithB;
        final _TestCancellable testCancellableB =
            _TestCancellable((exception) => cancelledWithB = exception);

        token
          ..attach(testCancellableA)
          ..attach(testCancellableB);

        expect(cancelledWithA, isNull);
        expect(cancelledWithB, isNull);

        async.elapse(Duration(minutes: 1));

        expect(cancelledWithA, equals(testException));
        expect(cancelledWithB, equals(testException));
      });
    });

    test('with a lazy start', () {
      fakeAsync((async) {
        final Exception testException = Exception('Test exception');
        final TimeoutCancellationToken token = TimeoutCancellationToken(
            Duration(minutes: 1),
            timeoutException: testException,
            lazyStart: true);

        async.elapse(Duration(minutes: 1));

        expect(token.isCancelled, isFalse);

        bool cancelled = false;
        final _TestCancellable testCancellable =
            _TestCancellable((exception) => cancelled = true);
        token.attach(testCancellable);

        async.elapse(Duration(minutes: 1));

        expect(token.isCancelled, isTrue);
        expect(cancelled, isTrue);
      });
    });
  });

  group('attached cancellables are only cancelled once', () {
    test('after double manual cancellation', () {
      final TimeoutCancellationToken token =
          TimeoutCancellationToken(Duration(minutes: 1));

      int cancelledCount = 0;
      final _TestCancellable testCancellable =
          _TestCancellable((exception) => cancelledCount++);

      token
        ..attach(testCancellable)
        ..cancel()
        ..cancel();

      expect(cancelledCount, equals(1));
    });

    test('after manual cancellation followed by the timeout', () {
      fakeAsync((async) {
        final TimeoutCancellationToken token =
            TimeoutCancellationToken(Duration(minutes: 1));

        int cancelledCount = 0;
        final _TestCancellable testCancellable =
            _TestCancellable((exception) => cancelledCount++);

        token
          ..attach(testCancellable)
          ..cancel();

        async.elapse(Duration(minutes: 1));

        expect(cancelledCount, equals(1));
      });
    });

    test('after the timeout followed by manual cancellation', () {
      fakeAsync((async) {
        final TimeoutCancellationToken token =
            TimeoutCancellationToken(Duration(minutes: 1));

        int cancelledCount = 0;
        final _TestCancellable testCancellable =
            _TestCancellable((exception) => cancelledCount++);

        token.attach(testCancellable);

        async.elapse(Duration(minutes: 1));

        token.cancel();

        expect(cancelledCount, equals(1));
      });
    });
  });

  group('isCancelled getter returns true after being cancelled', () {
    test('with no attached cancellables', () {
      final TimeoutCancellationToken token =
          TimeoutCancellationToken(Duration(minutes: 1));

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('with attached cancellables', () {
      final TimeoutCancellationToken token =
          TimeoutCancellationToken(Duration(minutes: 1));
      final _TestCancellable testCancellable = _TestCancellable((_) {});
      token.attach(testCancellable);

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);
    });
  });

  group('exception getter returns the cancellation exception', () {
    test('if no exception was provided', () {
      final TimeoutCancellationToken token =
          TimeoutCancellationToken(Duration(minutes: 1))..cancel();

      expect(token.exception, TypeMatcher<CancelledException>());
    });

    test('if a custom exception was provided', () {
      final Exception testException = Exception('Test exception');
      final TimeoutCancellationToken token =
          TimeoutCancellationToken(Duration(minutes: 1))..cancel(testException);

      expect(token.exception, equals(testException));
    });
  });
}

/// Test implementation of Cancellable.
class _TestCancellable with Cancellable {
  _TestCancellable(this.onCancelCallback);

  final Function(Exception cancelException) onCancelCallback;

  @override
  void onCancel(Exception cancelException, [StackTrace? trace]) =>
      onCancelCallback(cancelException);
}
