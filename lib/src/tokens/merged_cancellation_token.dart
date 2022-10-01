import 'package:cancellation_token/src/cancellables/cancellable.dart';
import 'package:cancellation_token/src/exceptions/cancelled_exception.dart';
import 'package:cancellation_token/src/tokens/cancellation_token.dart';
import 'package:collection/collection.dart';

/// Merges multiple cancellation tokens into a single token.
///
/// Note that when using a [MergedCancellationToken], the cancellation exception
/// thrown isn't guaranteed to be the exception of the token that was cancelled
/// first.
class MergedCancellationToken with Cancellable implements CancellationToken {
  MergedCancellationToken(List<CancellationToken> tokens) : _tokens = tokens {
    _updateCancellationStatus();
  }

  final List<CancellationToken> _tokens;
  final List<Cancellable> _attachedCancellables = [];
  bool _isCancelled = false;
  Exception? _exception;

  @override
  bool get hasCancellables => _attachedCancellables.isNotEmpty;

  /// Whether or not any of the merged tokens have been cancelled.
  @override
  bool get isCancelled {
    _updateCancellationStatus();
    return _isCancelled;
  }

  /// The exception given when one of the merged tokens was cancelled.
  ///
  /// On debug builds this will throw an exception if the token hasn't been
  /// called yet. On release builds a fallback [CancelledException] will be
  /// returned to prevent unexpected exceptions.
  ///
  /// If the [MergedCancellationToken] wasn't attached to any cancellables at
  /// the time of cancellation, this will return the exception of the first
  /// cancelled token in the list of merged tokens. Otherwise, the exception
  /// from the merged token that was cancelled first will be used.
  @override
  Exception get exception {
    _updateCancellationStatus();
    assert(
      isCancelled,
      'Attempted to get the cancellation exception of a $runtimeType that '
      'hasn\'t been cancelled yet.',
    );
    return _exception ?? CancelledException();
  }

  /// Merges this [CancellationToken] with another to create a single token
  /// that will be cancelled when either token is cancelled.
  ///
  /// When merging more than two tokens, use [MergedCancellationToken] directly.
  @override
  MergedCancellationToken merge(CancellationToken other) =>
      MergedCancellationToken([this, other]);

  /// Cancels the token.
  ///
  /// This does not affect the merged tokens.
  @override
  void cancel([Exception exception = const CancelledException()]) {
    if (_isCancelled) return;
    onCancel(exception);
  }

  /// Attaches a [Cancellable] to this token.
  ///
  /// If this token isn't attached to any other cancellables, it will also
  /// attach itself to the merged tokens.
  @override
  void attach(Cancellable cancellable) {
    _updateCancellationStatus();
    assert(
      !isCancelled,
      'Attampted to attach to a $runtimeType that has already been cancelled.\n'
      'Before calling attach() you should check isCancelled.',
    );
    if (!isCancelled) {
      if (_attachedCancellables.isEmpty) {
        for (final CancellationToken token in _tokens) {
          token.attach(this);
        }
      }
      if (!_attachedCancellables.contains(cancellable)) {
        _attachedCancellables.add(cancellable);
      }
    }
  }

  /// Detaches a [Cancellable] from this token.
  ///
  /// If this token has no remaining attached cancellables after detaching,
  /// it will also detach itself from the merged tokens.
  @override
  void detach(Cancellable cancellable) {
    if (!isCancelled) _attachedCancellables.remove(cancellable);
    if (_attachedCancellables.isEmpty) {
      for (final CancellationToken token in _tokens) {
        token.detach(this);
      }
    }
  }

  /// Handles the cancellation of a merged token that this token is currently
  /// attached to.
  ///
  /// Notifies all attached cancellables of the cancellation and detaches from
  /// the merged tokens.
  @override
  void onCancel(Exception cancelException, [StackTrace? stackTrace]) {
    _isCancelled = true;
    _exception = cancelException;
    for (Cancellable cancellable in _attachedCancellables) {
      cancellable.onCancel(exception);
    }
    _attachedCancellables.clear();
    for (final CancellationToken token in _tokens) {
      token.detach(this);
    }
  }

  /// Checks if the cancellation status has changed for any of the merged
  /// tokens.
  void _updateCancellationStatus() {
    if (_isCancelled) return;
    final CancellationToken? cancelledToken =
        _tokens.firstWhereOrNull((token) => token.isCancelled);
    if (cancelledToken != null) {
      _isCancelled = true;
      _exception = cancelledToken.exception;
    }
  }
}