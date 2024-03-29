## 2.0.1

* Fixed a `Bad state: Future already completed` exception that could occur when nesting cancellable futures.

## 2.0.0

This release aims to make it easier to implement custom Cancellables and provide more useful information for debugging. 

* Added a `.cancelWithReason()` method to `CancellationToken` for a convenient way to set provide a cancellation reason for debugging.
* `CancelledException` now overrides `.toString()` to give a more useful message for debugging, including the cancellation reason.
* Cancellation stack traces now show the call stack leading up to the operation that was cancelled, rather than the call stack leading up to the token's cancellation. This should make it easier to identify the origin of uncaught cancellation exceptions.
* Added a `.detach()` method to the `Cancellable` mixin. When paired with `.maybeAttach()`, this will detach your cancellable from the token.
* Fixed a bug where the `ignoreCancellation()` wouldn't call `whenComplete` if `onError` threw an exception.
* Fixed a bug where `asCancellable()` could result in uncaught exceptions.

### Breaking changes
These changes are isolated to projects using custom cancellables or cancellation tokens. Other projects are unaffected.

* The `CancellationToken.attach()` and `.detach()` methods have been renamed to `.attachCancellable()` and `.detachCancellable()`.
* The `CancellationToken.exception` getter now returns null if the token hasn't been cancelled yet.
* The `CancellationToken.cancel()` method's `exception` parameter is now nullable, rather than using a default value.
* Removed the `[StackTrace? stackTrace]` parameter from the `Cancellable` mixin's `onCancel` method. Instead, use the new `cancellationStackTrace`, which returns the stack trace at the time the cancellable was created.
* Overridden `Cancellable` mixin methods must now call super.

### To migrate your custom cancellation tokens:

* If you're overriding the `.attach()` and `.detach()` methods, rename them to `.attachCancellable()` and `.detachCancellable()`.
* If you're overriding `.exception`, update it to be nullable and only return an exception if the token's been cancelled.
* If you're overriding `.cancel()`, update it to make the `exception` parameter nullable. If you were previously setting a default value, consider setting this within the method instead:
  ```dart
  @override
  void cancel([Exception? exception]) {
    exception ??= YourCustomDefaultException();
    super.cancel(exception);
  }
  ```

### To migrate your custom cancellables:

* Replace calls to `cancellationToken.attach(this)` with `maybeAttach(cancellationToken)`.
* Replace calls to `cancellationToken.detach(this)` with `detach()`.
* Update `onCancel()` overrides to call `super.onCancel()` and remove the `stackTrace` parameter. To get the stack trace, use `cancellationStackTrace` instead:
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