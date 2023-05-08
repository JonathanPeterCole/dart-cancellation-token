import 'package:cancellation_token/src/cancellables/cancellable.dart';
import 'package:cancellation_token/src/exceptions/cancelled_exception.dart';
import 'package:cancellation_token/src/tokens/merged_cancellation_token.dart';
import 'package:meta/meta.dart';

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
  /// The exception given when this token was cancelled, or null if the token
  /// hasn't been cancelled yet.
  Exception? _cancelledException;

  /// The internal collection of [Cancellable] operations currently listening to
  /// this token.
  final List<Cancellable> _attachedCancellables = [];

  /// Whether or not the token has been cancelled.
  bool get isCancelled => _cancelledException != null;

  /// The exception given when the token was cancelled.
  ///
  /// Returns null if the token hasn't been cancelled yet.
  Exception? get exception => _cancelledException;

  /// Whether or not the token has any attached cancellables.
  ///
  /// This is useful when testing a custom Cancellable to ensure it detatches
  /// from the token after completing.
  bool get hasCancellables => _attachedCancellables.isNotEmpty;

  /// Merges this [CancellationToken] with another to create a single token
  /// that will be cancelled when either token is cancelled.
  ///
  /// When merging more than two tokens, use [MergedCancellationToken] directly.
  MergedCancellationToken merge(CancellationToken other) =>
      MergedCancellationToken([this, other]);

  /// Cancels all operations using this token.
  ///
  /// By default, the token will be cancelled with a [CancelledException]. To
  /// override this behaviour, pass a custom [exception].
  ///
  /// To include a reason for the cancellation, use [cancelWithReason].
  @mustCallSuper
  void cancel([Exception? exception]) {
    if (isCancelled) return;
    exception ??= const CancelledException();
    _cancelledException = exception;
    for (Cancellable cancellable in _attachedCancellables) {
      cancellable.onCancel(exception);
    }
    _attachedCancellables.clear();
  }

  /// A convenience method for cancelling the token with a [CancelledException]
  /// that includes the reason for cancellation.
  @mustCallSuper
  void cancelWithReason(String? cancellationReason) {
    cancel(CancelledException(cancellationReason: cancellationReason));
  }

  /// Attaches a [Cancellable] to this token.
  ///
  /// Before attaching to a [CancellationToken], you should check if it's
  /// already been cancelled by using [isCancelled].
  @mustCallSuper
  void attachCancellable(Cancellable cancellable) {
    assert(
      !isCancelled,
      'Attampted to attach to a $runtimeType that has already been cancelled.\n'
      'Check isCancelled or use the CancellableMixin\'s maybeAttach() method '
      'to check if the token\'s already been cancelled before attaching to it.',
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
  @mustCallSuper
  void detachCancellable(Cancellable cancellable) {
    // Prevent modifications to the list whilst it's being iterated on by
    // ignoring detach calls if the token's been cancelled
    if (!isCancelled) _attachedCancellables.remove(cancellable);
  }
}
