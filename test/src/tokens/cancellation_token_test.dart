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
      ..attach(testCancellableA)
      ..attach(testCancellableB)
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
      ..attach(testCancellable)
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
      ..attach(testCancellable)
      ..detach(testCancellable)
      ..cancel();

    expect(cancelled, isFalse);
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
      token.attach(testCancellable);

      expect(token.isCancelled, isFalse);

      token.cancel();

      expect(token.isCancelled, isTrue);
    });
  });

  group('exception getter', () {
    group('returns the cancellation exception', () {
      test('if no exception was provided', () {
        final CancellationToken token = CancellationToken()..cancel();

        expect(token.exception, TypeMatcher<CancelledException>());
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
  void onCancel(Exception cancelException) => onCancelCallback(cancelException);
}
