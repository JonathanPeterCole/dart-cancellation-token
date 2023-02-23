## 2.0.0

This release aims to make it easier to implement custom Cancellables and provide more useful stack traces when cancellations haven't been caught correctly. This includes some breaking changes for projects that use custom cancellables.

* Added a `detach()` method to the `Cancellable` mixin.
* **Breaking:** The  `.attach()` and `.detach()` methods on `CancellationToken` have been renamed to `.attachCancellable()` and `.detachCancellable()`.
* **Breaking:** Overrides for methods in the `Cancellable` mixin must now call super.
* **Breaking:** Removed the `[StackTrace? stackTrace]` parameter from the `Cancellable` mixin's `onCancel` method. Instead, use the new `cancellationStackTrace`, which returns the stack trace at the time the cancellable was created.


### To migrate your custom cancellables:

* Replace calls to `cancellationToken.attach(this)` with `maybeAttach(cancellationToken)`.
* Replace calls to `cancellationToken.detach(this)` with `detach()`.
* Update `onCancel()` overrides to call `super.onCancel()` and replace the `stackTrace` parameter with `cancellationStackTrace`:
  ```dart
  // Old

  @override
  void onCancel(Exception cancelException, [StackTrace? stackTrace]) {
    _internalCompleter.completeError(
      cancelException,
      stackTrace ?? StackTrace.current,
    );
  }

  // New

  @override
  void onCancel(Exception cancelException) {
    super.onCancel(cancelException);
    _internalCompleter.completeError(cancelException, cancellationStackTrace);
  }
  ```

### To migrate your custom cancellation tokens:

* Rename the `.attach()` and `.detach()` methods to `.attachCancellable()` and `.detachCancellable()`.

## 1.6.1

* Include Dart SDK license in license file.

## 1.6.0

* Added `CancellableIsolate.run()`, based on the new [`Isolate.run()` method in Dart 2.19.0](https://medium.com/dartlang/better-isolate-management-with-isolate-run-547ef3d6459b).
* Updated `cancellableCompute` to use `CancellableIsolate.run()` internally.
* Increased minimum Dart SDK to 2.19.0.

## 1.5.0

* Added `MergedCancellationToken` to combine multiple cancellation tokens into one.
* Added `cancellableFutureOr()` to simplify cancellation when working with `FutureOr` types.
* Added `onError`, `whenComplete`, and `whenCompleteOrCancelled` params to `ignoreCancellation()`. This change doesn't impact existing usage.

## 1.4.0

* Added new static functions to `CancellableFuture` to make the API more similar to Dart's `Future`:
  * `Future()` ➡️ `CancellableFuture.from()`
  * `Future.microtask()` ➡️ `CancellableFuture.microtask()`
  * `Future.sync()` ➡️ `CancellableFuture.sync()`
  * `Future.value()` ➡️ `CancellableFuture.value()`
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