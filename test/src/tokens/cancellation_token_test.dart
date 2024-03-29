import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('cancels all attached cancellables', () {
    final CancellationToken token = CancellationToken();
    final Exception testException = Exception('Test exception');

    Exception? cancelledWithA;
    final _TestCancellable testCancellableA =
        _TestCancellable((exception) => cancelledWithA = exception);
    Exception? cancelledWithB;
    final _TestCancellable testCancellableB =
        _TestCancellable((exception) => cancelledWithB = exception);

    token
      ..attachCancellable(testCancellableA)
      ..attachCancellable(testCancellableB)
      ..cancel(testException);

    expect(cancelledWithA, equals(testException));
    expect(cancelledWithB, equals(testException));
  });

  test('attached cancellables are only cancelled once', () {
    final CancellationToken token = CancellationToken();

    int cancelledCount = 0;
    final _TestCancellable testCancellable =
        _TestCancellable((exception) => cancelledCount++);

    token
      ..attachCancellable(testCancellable)
      ..cancel()
      ..cancel();

    expect(cancelledCount, equals(1));
  });

  test('detached cancellables are not cancelled', () {
    final CancellationToken token = CancellationToken();

    bool cancelled = false;
    final _TestCancellable testCancellable =
        _TestCancellable((exception) => cancelled = false);

    token
      ..attachCancellable(testCancellable)
      ..detachCancellable(testCancellable)
      ..cancel();

    expect(cancelled, isFalse);
  });

  test('detach calls are ignored for cancelled tokens', () {
    final CancellationToken token = CancellationToken();

    _TestCancellable? testCancellable;
    testCancellable = _TestCancellable(
      (exception) => token.detachCancellable(testCancellable!),
    );

    token
      ..attachCancellable(testCancellable)
      ..cancel();
  });

  group('isCancelled getter returns true after being cancelled', () {
    test('with no attached cancellables', () {
      final CancellationToken token = CancellationToken();

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('with attached cancellables', () {
      final CancellationToken token = CancellationToken();
      final _TestCancellable testCancellable = _TestCancellable((_) {});
      token.attachCancellable(testCancellable);

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);
    });
  });

  group('hasCancellables getter', () {
    test('returns false if there all cancellables have detached', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      final CancellationToken token = CancellationToken()
        ..attachCancellable(testCancellable)
        ..detachCancellable(testCancellable);

      expect(token.hasCancellables, isFalse);
    });

    test('returns false if the token was cancelled', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      final CancellationToken token = CancellationToken()
        ..attachCancellable(testCancellable)
        ..cancel();

      expect(token.hasCancellables, isFalse);
    });

    test('returns true if there are attached cancellables', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      final CancellationToken token = CancellationToken()
        ..attachCancellable(testCancellable);

      expect(token.hasCancellables, isTrue);
    });
  });

  group('exception getter', () {
    group('returns the cancellation exception', () {
      test('if no exception was provided', () {
        final CancellationToken token = CancellationToken()..cancel();

        expect(token.exception, isA<CancelledException>());
      });

      test('if a custom exception was provided', () {
        final Exception testException = Exception('Test exception');
        final CancellationToken token = CancellationToken()
          ..cancel(testException);

        expect(token.exception, equals(testException));
      });
    });

    test('returns the same exception instance every time', () {
      final CancellationToken token = CancellationToken()..cancel();

      expect(token.exception, equals(token.exception));
    });
  });
}

/// Test implementation of Cancellable.
class _TestCancellable with Cancellable {
  _TestCancellable(this.onCancelCallback);

  final Function(Exception cancelException) onCancelCallback;

  @override
  void onCancel(Exception cancelException) {
    super.onCancel(cancelException);
    onCancelCallback(cancelException);
  }
}
