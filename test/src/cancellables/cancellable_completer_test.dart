import 'package:cancellation_token/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('completes with given normal value if not cancelled', () {
    final CancellationToken token = CancellationToken();
    final CancellableCompleter<String> completer =
        CancellableCompleter<String>(token);

    completer.complete('Test value');

    expect(completer.future, completion(equals('Test value')));
  });

  test('completes with given exception if not cancelled', () {
    final CancellationToken token = CancellationToken();
    final CancellableCompleter<String> completer =
        CancellableCompleter<String>(token);

    completer.completeError(_TestException());

    expect(completer.future, throwsA(isA<_TestException>()));
  });

  group('completes with a CancelledException', () {
    test('when cancelled before attaching', () {
      final CancellationToken token = CancellationToken()..cancel();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      expect(completer.future, throwsA(isA<CancelledException>()));
    });

    test('when cancelled after attaching', () {
      final CancellationToken token = CancellationToken();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      token.cancel();

      expect(completer.future, throwsA(isA<CancelledException>()));
    });
  });

  group('isCancelled', () {
    test('returns true if the completer was cancelled', () {
      final CancellationToken token = CancellationToken()..cancel();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      expect(completer.isCancelled, isTrue);
      expect(completer.future, throwsException);
    });

    test('returns false if the completer was not cancelled', () {
      final CancellationToken token = CancellationToken();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      expect(completer.isCancelled, isFalse);
    });
  });

  group('isCompleted', () {
    test('returns true if completed with a value', () {
      final CancellationToken token = CancellationToken();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      completer.complete('Test value');

      expect(completer.isCompleted, isTrue);
    });

    test('returns true if completed with an error', () {
      final CancellationToken token = CancellationToken();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      completer.completeError(_TestException());

      expect(completer.isCompleted, isTrue);
      expect(completer.future, throwsException);
    });

    test('returns true if the completer was cancelled', () {
      final CancellationToken token = CancellationToken()..cancel();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      expect(completer.isCompleted, isTrue);
      expect(completer.future, throwsException);
    });

    test('returns false if not completed', () {
      final CancellationToken token = CancellationToken();
      final CancellableCompleter<String> completer =
          CancellableCompleter<String>(token);

      expect(completer.isCompleted, isFalse);
    });
  });
}

class _TestException implements Exception {}
