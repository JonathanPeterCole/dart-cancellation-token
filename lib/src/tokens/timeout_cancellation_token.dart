import 'dart:async';

import 'package:cancellation_token/src/cancellables/cancellable.dart';
import 'package:cancellation_token/src/tokens/cancellation_token.dart';

/// A [CancellationToken] that automatically cancels after a given duration.
///
/// See also:
///
///  * [CancellationToken], which this class is based on.
class TimeoutCancellationToken extends CancellationToken {
  /// Creates a [TimeoutCancellationToken] with the given timeout duration.
  ///
  /// By default a [TimeoutException] will be used when the timeout ends. To
  /// throw a custom exception, set the [timeoutException] param.
  ///
  /// If [lazyStart] is true, the timer will only start when it's used.
  TimeoutCancellationToken(
    Duration duration, {
    Exception? timeoutException,
    bool lazyStart = false,
  }) {
    _duration = duration;
    _timeoutException = timeoutException;
    if (!lazyStart) _timer = Timer(duration, _onTimerEnd);
  }

  /// The timeout duration.
  late Duration _duration;

  /// The timeout timer.
  Timer? _timer;

  /// The exception that should be thrown when the timeout countdown ends.
  Exception? _timeoutException;

  /// Cancels all operations with this token.
  ///
  /// An optional [exception] can be provided to give a cancellation reason.
  @override
  void cancel([Exception? exception]) {
    _timer?.cancel();
    super.cancel(exception);
  }

  /// Attaches a [Cancellable] to this token.
  ///
  /// Before attaching to a [CancellationToken], you should check if it's
  /// already been cancelled by using [isCancelled].
  @override
  void attachCancellable(Cancellable cancellable) {
    if (!isCancelled && _timer == null) Timer(_duration, _onTimerEnd);
    super.attachCancellable(cancellable);
  }

  /// Cancells the token when the timeout ends.
  void _onTimerEnd() {
    if (!isCancelled) {
      cancel(_timeoutException ??
          TimeoutException(
            'The TimeoutCancellationToken timeout duration ended.',
            _duration,
          ));
    }
  }
}
