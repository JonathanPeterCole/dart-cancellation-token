import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  late CancellationToken tokenA;
  late CancellationToken tokenB;
  late MergedCancellationToken mergedToken;

  setUp(() {
    tokenA = CancellationToken();
    tokenB = CancellationToken();
    mergedToken = MergedCancellationToken([tokenA, tokenB]);
  });

  test('cancels all attached cancellables when cancelled', () {
    final Exception testException = Exception('Test exception');

    Exception? cancelledWithA;
    final _TestCancellable testCancellableA = _TestCancellable(
      (exception) => cancelledWithA = exception,
    );
    Exception? cancelledWithB;
    final _TestCancellable testCancellableB = _TestCancellable(
      (exception) => cancelledWithB = exception,
    );

    mergedToken
      ..attach(testCancellableA)
      ..attach(testCancellableB)
      ..cancel(testException);

    expect(cancelledWithA, equals(testException));
    expect(cancelledWithB, equals(testException));
  });

  test('cancels all attached cancellables when a merged token is cancelled',
      () {
    final Exception testException = Exception('Test exception');

    Exception? cancelledWithA;
    final _TestCancellable testCancellableA = _TestCancellable(
      (exception) => cancelledWithA = exception,
    );
    Exception? cancelledWithB;
    final _TestCancellable testCancellableB = _TestCancellable(
      (exception) => cancelledWithB = exception,
    );

    mergedToken
      ..attach(testCancellableA)
      ..attach(testCancellableB);
    tokenA.cancel(testException);

    expect(cancelledWithA, equals(testException));
    expect(cancelledWithB, equals(testException));
  });

  test('attached cancellables are only cancelled once', () {
    int cancelledCount = 0;
    final _TestCancellable testCancellable =
        _TestCancellable((exception) => cancelledCount++);

    mergedToken.attach(testCancellable);
    tokenA.cancel();
    tokenB.cancel();

    expect(cancelledCount, equals(1));
  });

  test('detached cancellables are not cancelled', () {
    bool cancelled = false;
    final _TestCancellable testCancellable =
        _TestCancellable((exception) => cancelled = false);

    mergedToken
      ..attach(testCancellable)
      ..detach(testCancellable);
    tokenA.cancel();

    expect(cancelled, isFalse);
  });

  test('detach calls are ignored for cancelled tokens', () {
    _TestCancellable? testCancellable;
    testCancellable = _TestCancellable(
      (exception) => mergedToken.detach(testCancellable!),
    );

    mergedToken
      ..attach(testCancellable)
      ..cancel();
  });

  group('isCancelled getter', () {
    test('returns true if one of the merged tokens was already cancelled', () {
      tokenA.cancel();
      mergedToken = MergedCancellationToken([tokenA, tokenB]);

      expect(mergedToken.isCancelled, isTrue);
    });

    group('returns true after the token is cancelled', () {
      test('with no attached cancellables', () {
        expect(mergedToken.isCancelled, isFalse);

        mergedToken.cancel();

        expect(mergedToken.isCancelled, isTrue);
      });

      test('with attached cancellables', () {
        final _TestCancellable testCancellable = _TestCancellable((_) {});
        mergedToken.attach(testCancellable);

        expect(mergedToken.isCancelled, isFalse);

        mergedToken.cancel();

        expect(mergedToken.isCancelled, isTrue);
      });
    });

    group('returns true after a merged token is cancelled', () {
      test('with no attached cancellables', () {
        expect(mergedToken.isCancelled, isFalse);

        tokenA.cancel();

        expect(mergedToken.isCancelled, isTrue);
      });

      test('with attached cancellables', () {
        final _TestCancellable testCancellable = _TestCancellable((_) {});
        mergedToken.attach(testCancellable);

        expect(mergedToken.isCancelled, isFalse);

        tokenA.cancel();

        expect(mergedToken.isCancelled, isTrue);
      });
    });
  });

  group('hasCancellables getter', () {
    test('returns false if there all cancellables have detached', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken
        ..attach(testCancellable)
        ..detach(testCancellable);

      expect(mergedToken.hasCancellables, isFalse);
    });

    test('returns false if the token was cancelled', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken
        ..attach(testCancellable)
        ..cancel();

      expect(mergedToken.hasCancellables, isFalse);
    });

    test('returns false if one of the merged tokens was cancelled', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken.attach(testCancellable);
      tokenA.cancel();

      expect(mergedToken.hasCancellables, isFalse);
    });

    test('returns true if there are attached cancellables', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken.attach(testCancellable);

      expect(mergedToken.hasCancellables, isTrue);
    });
  });

  group('exception getter', () {
    test(
        'returns the cancellation exception if one of the merged tokens was '
        'already cancelled', () {
      tokenA.cancel();
      mergedToken = MergedCancellationToken([tokenA, tokenB]);

      expect(mergedToken.exception, isA<CancelledException>());
    });

    group('returns the cancellation exception if the token was cancelled', () {
      test('if no exception was provided', () {
        mergedToken.cancel();

        expect(mergedToken.exception, TypeMatcher<CancelledException>());
      });

      test('if a custom exception was provided', () {
        final Exception testException = Exception('Test exception');

        mergedToken.cancel(testException);

        expect(mergedToken.exception, equals(testException));
      });
    });

    group('returns the cancellation exception if a merged token was cancelled',
        () {
      test('if no exception was provided', () {
        tokenB.cancel();

        expect(mergedToken.exception, TypeMatcher<CancelledException>());
      });

      test('if a custom exception was provided', () {
        final Exception testException = Exception('Test exception');

        tokenB.cancel(testException);

        expect(mergedToken.exception, equals(testException));
      });
    });

    test('returns the same exception instance every time', () {
      mergedToken.cancel();

      expect(mergedToken.exception, equals(mergedToken.exception));
    });
  });

  test('attaches to the merged tokens when a cancellable attaches', () {
    final _TestCancellable testCancellable = _TestCancellable((_) {});

    mergedToken.attach(testCancellable);

    expect(tokenA.hasCancellables, isTrue);
    expect(tokenB.hasCancellables, isTrue);
    expect(mergedToken.hasCancellables, isTrue);
  });

  group('detaches from merged tokens', () {
    test('when all cancellables have detatched', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken
        ..attach(testCancellable)
        ..detach(testCancellable);

      expect(tokenA.hasCancellables, isFalse);
      expect(tokenB.hasCancellables, isFalse);
      expect(mergedToken.hasCancellables, isFalse);
    });

    test('when cancelled', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken
        ..attach(testCancellable)
        ..cancel();

      expect(tokenA.hasCancellables, isFalse);
      expect(tokenB.hasCancellables, isFalse);
      expect(mergedToken.hasCancellables, isFalse);
    });

    test('when one of the merged tokens in cancelled', () {
      final _TestCancellable testCancellable = _TestCancellable((_) {});

      mergedToken.attach(testCancellable);
      tokenA.cancel();

      expect(tokenA.hasCancellables, isFalse);
      expect(tokenB.hasCancellables, isFalse);
      expect(mergedToken.hasCancellables, isFalse);
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
