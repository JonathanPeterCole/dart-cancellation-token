## 1.3.0

* Added `CancellableCompleter.sync` constructor to match Dart's Completer.
* Added `ignoreCancellations()` convenience function for silently catching cancellation exceptions.
* Added example project.
* StackTraces are now included when cancelling (experimental).
* Bugfix: Calling the `.exception` getter on a CancellationToken will no longer create a new CancelledException instance every time.
* Bugfix: Fixed uncaught exceptions.

## 1.2.0

* Added support for nullable CancellationTokens, allowing functions/classes to be made cancellable without breaking existing implementations.

## 1.1.1

* Bugfix: Add missing cancellableCompute export.

## 1.1.0

* Added `cancellableCompute()` for running isolates that can be killed using a CancellationToken.
* Increased minimum Dart SDK to 2.15.0.

## 1.0.0

Initial release