## 1.4.0

* Added new static functions to `CancellableFuture` to make the API more similar to Dart's `Future`:
  * `Future()` ➡️ `CancellableFuture.from()`
  * `Future.microtask()` ➡️ `CancellableFuture.microtask()`
  * `Future.sync()` ➡️ `CancellableFuture.sync()`
  * `Future.delayed()` ➡️ `CancellableFuture.delayed()`
* **Breaking:** The `CancellableFuture` constructor is now private. Calls to this constuctor should be replaced with `.asCancellable()` or `CancellableFuture.value()`:
  ```dart
  // Removed:
  // await CancellableFuture(exampleFuture, cancellationToken).future;

  // Recommended:
  await exampleFuture.asCancellable(cancellationToken);
  ```
* Updated `cancellableCompute` with the latest changes from the Flutter SDK's `compute` function (see [flutter/flutter#99527](https://github.com/flutter/flutter/pull/99527)).

## 1.3.4

* Rename the `onCancel` method's `trace` parameter to `stackTrace`.
* Add Cancellation Token HTTP example to README.

## 1.3.3

* Fix CancellableCompute web implementation.

## 1.3.2

* Added `hasCancellables` to CancellationToken.

## 1.3.1

* Bugfix: Fix exception if a Cancellable calls `cancellationToken.detach(this)` in its `onCancel` method.

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