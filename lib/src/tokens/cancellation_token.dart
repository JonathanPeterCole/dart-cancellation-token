import 'package:cancellation_token/src/cancellables/cancellable.dart';
import 'package:cancellation_token/src/exceptions/cancelled_exception.dart';
import 'package:cancellation_token/src/tokens/merged_cancellation_token.dart';

/// A token for controlling the cancellation of [Cancellable] operations.
///
/// A single token can be used for multiple [Cancellable] operations.
///
/// ## Example implementation
///
/// ```dart
/// CancellationToken cancellationToken = CancellationToken();
///
/// @override
/// void initState() {
///   super.initState();
///   loadData();
/// }
///
/// @override
/// void dispose() {
///   cancellationToken.cancel();
///   super.dispose();
/// }
///
/// Future<void> loadData() async {
///   loading = false;
///   try {
///     someDataA = await getDataA(cancellationToken: cancellationToken);
///     someDataB = await getDataB(cancellationToken: cancellationToken);
///     setState(() {});
///   } on CancelledException {
///     // Ignore cancellations
///   } catch (e, stackTrace) {
///     error = true;
///   }
/// }
/// ```
///
/// See also:
///
///  * [MergedCancellationToken], a [CancellationToken] that combines multiple
///    tokens together.
///  * [TimeoutCancellationToken], a [CancellationToken] that automatically
///    cancels after a given duration.
class CancellationToken {
  /// Whether or not this token has been cancelled.
  bool _isCancelled = false;

  /// The exception given when this token was cancelled.
  Exception? _exception;

  /// The internal collection of [Cancellable] operations currently listening to
  /// this token.
  final List<Cancellable> _attachedCancellables = [];

  /// Whether or not the token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Whether or not the token has any attached cancellables.
  ///
  /// This is useful when testing a custom Cancellable to ensure it detatches
  /// from the token after completing.
  bool get hasCancellables => _attachedCancellables.isNotEmpty;

  /// The exception given when the token was cancelled.
  ///
  /// On debug builds this will throw an exception if the token hasn't been
  /// called yet. On release builds a fallback [CancelledException] will be
  /// returned to prevent unexpected exceptions.
  Exception get exception {
    assert(
      isCancelled,
      'Attempted to get the cancellation exception of a $runtimeType that '
      'hasn\'t been cancelled yet.',
    );
    return _exception ??= CancelledException();
  }

  /// Merges this [CancellationToken] with another to create a single token
  /// that will be cancelled when either token is cancelled.
  ///
  /// When merging more than two tokens, use [MergedCancellationToken] directly.
  MergedCancellationToken merge(CancellationToken other) =>
      MergedCancellationToken([this, other]);

  /// Cancels all operations with this token.
  ///
  /// An optional [exception] can be provided to give a cancellation reason.
  void cancel([Exception exception = const CancelledException()]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _exception = exception;
    for (Cancellable cancellable in _attachedCancellables) {
      cancellable.onCancel(exception);
    }
    _attachedCancellables.clear();
  }

  /// Attaches a [Cancellable] to this token.
  ///
  /// Before attaching to a [CancellationToken], you should check if it's
  /// already been cancelled by using [isCancelled].
  void attach(Cancellable cancellable) {
    assert(
      !isCancelled,
      'Attampted to attach to a $runtimeType that has already been cancelled.\n'
      'Before calling attach() you should check isCancelled.',
    );
    if (!isCancelled && !_attachedCancellables.contains(cancellable)) {
      _attachedCancellables.add(cancellable);
    }
  }

  /// Detaches a [Cancellable] from this token.
  ///
  /// This should be called when a [Cancellable] completes to prevent memory
  /// leaks. You should not call this inside a Cancellable's `onCancel` method,
  /// as attached Cancellables are detached automatically when a token is
  /// cancelled.
  void detach(Cancellable cancellable) {
    // Prevent modifications to the list whilst it's being iterated on by
    // ignoring detach calls if the token's been cancelled
    if (!isCancelled) _attachedCancellables.remove(cancellable);
  }
}
