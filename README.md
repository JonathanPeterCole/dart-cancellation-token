# Dart Cancellation Token

A Dart utility package for easy async task cancellation.


## Features

* Cancel futures and clean-up resources (e.g. closing an HttpClient) when a widget is disposed in Flutter.
* Reuse a single CancellationToken for multiple tasks, and cancel them all with a single call to `.cancel()`.
* Cancel isolates with cancellableCompute.
* Create your own cancellables that use CancellationTokens with the Cancellable mixin.


## Cancellation Tokens

### CancellationToken

The standard CancellationToken for manually cancelling tasks. When `.cancel()` is called, all cancellables using the token will be cancelled. By default, async tasks cancelled with a CancellationToken will throw a CancelledException. You can pass a custom exception using `.cancel(CustomException())` to change this.

### TimeoutCancellationToken

To cancel tasks after a certain amount of time, you can use a TimeoutCancellationToken. By default, async tasks will be cancelled with a TimeoutException when the timeout duration ends. You can pass a custom exception by using the `timeoutException` parameter. 

When a TimeoutCancellationToken is created, the timer will begin immediately. To only start the timer when the token is attached to a task, set the `lazyStart` parameter to true.

### MergedCancellationToken

To combine multiple tokens together, you can use a MergedCancellationToken. To create one, use the `MergedCancellationToken()` constructor, or use the `.merge()` shortcut method on an existing token.

Note that when using a MergedCancellationToken, the cancellation exception isn't guaranteed to be from the token that was cancelled first. If no cancellable operations were running when the tokens were cancelled, the exception from the first token in the list will be used. When using the `.merge()` shortcut, this is the token on which you called `.merge()`.


## Usage

### Cancellable Future

The CancellableFuture class provides cancellable versions for many of Dart's Future constructors, including:
* `Future()` ➡️ `CancellableFuture.from()`
* `Future.microtask()` ➡️ `CancellableFuture.microtask()`
* `Future.sync()` ➡️ `CancellableFuture.sync()`
* `Future.value()` ➡️ `CancellableFuture.value()`
* `Future.delayed()` ➡️ `CancellableFuture.delayed()`

To make existing futures cancellable, you can also use the `.asCancellable()` extension.

```dart
CancellationToken cancellationToken = CancellationToken();

@override
void initState() {
  super.initState();
  loadData();
}

@override
void dispose() {
  // All futures using this token will be cancelled when this widget is disposed
  cancellationToken.cancel();
  super.dispose();
}

Future<void> loadData() async {
  try {
    // The CancellationToken can be used for multiple tasks
    someDataA = await getDataA().asCancellable(cancellationToken);
    someDataB = await getDataB().asCancellable(cancellationToken);
    setState(() {
      // ...
    });
  } on CancelledException {
    // Ignore cancellations
  } catch (e, stackTrace) {
    setState(() => error = true);
  }
}
```

### Cancellable Completer

The CancellableCompleter class can be used in place of a standard Completer to make it cancellable. This completer implements the base Completer class, so it works as a drop-in replacement.

```dart
CancellableCompleter<String> completer = CancellableCompleter<String>(
  cancellationtoken, 
  onCancel: () {
    // The optional onCancel callback can be used to clean up resources when the 
    // token is cancelled
  }
);

// Complete with either the result or an error as usual, these will only have an 
// effect if the completer hasn't already been cancelled
completer.complete(result);
complete.completeError(e, stackTrace);

// This future will complete with the result or the cancellation exception, 
// whichever is first
return completer.future;
```

### Cancellable Isolate

If you need to run an intensive synchronous task, like parsing a large JSON API response, you can use an isolate to avoid blocking the UI thread. With `CancellableIsolate.run()`, you can run a computation in an isolate and kill the isolate early using a CancellationToken. This function is based on Dart's `Isolate.run()` method.

When cancelled, the isolate will be killed immediately to free up resources. If your callback function performs I/O operations such as file writes, these may not complete.

When building for web, this uses `CancellableFuture.from()` as a fallback due to isolates not being supported.
```dart
final ChunkyApiResponse response = await CancellableIsolate.run(
  () {
    final Map<String, dynamic> decodedJson = jsonDecode(json);
    return ChunkyApiResponse.fromJson(decodedJson);
  },
  cancellationToken,
);
```

### Cancellable HTTP

For HTTP requests with cancellation support, check out the [Cancellation Token HTTP](https://pub.dev/packages/cancellation_token_http) package, a fork of the Dart HTTP package with request cancellation. If HTTP request cancellation is all you need, the package can be used standalone, but it's most powerful when paired when other cancellables like `cancellableCompute`.

```dart
/// This function calls an API and parses the response 
Future<ChunkyApiResponse> makeRequest({
  CancellationToken? cancellationToken,
}) async {
  final http.Response response = await http.get(
    Uri.parse('https://example.com/bigjson'),
    cancellationToken: token,
  );
  return await CancellableIsolate.run(
    () {
      final Map<String, dynamic> decodedJson = jsonDecode(response.body);
      return ChunkyApiResponse.fromJson(decodedJson);
    },
    cancellationToken
  );
}
```

### Custom Cancellables

If you don't need to clean up resources, like cancelling a network request, when your operation is cancelled, `CancellableFuture.from()` and `.asCancellable()` should have you covered with no need for a custom cancellable.

* `CancellableFuture.from()` allows you to wrap an async computation to make it cancellable. If the CancellationToken is cancelled before it runs, the computation will never be started.
* The `.asCancellable()` extension allows you to apply cancellation to an existing Future, but the Future will always run, even if the CancellationToken has already been cancelled.

In cases where you *do* want to clean up resources, you can create a custom cancellable:

#### Using CancellableCompleter

In most cases, `CancellableCompleter` will suffice for creating custom cancellables.

* **DO** release resources after cancellation if possible, using the `onCancel` callback. If you can't release resources, consider wrapping your function with `CancellableFuture.from()` instead.
* **DON'T** await any futures before returning the completer's future.
* **DON'T** start any async work if the token was already cancelled.

```dart
Future<String> myCancellable({CancellationToken? cancellationToken}) {
  MyAsyncOperation? myAsyncOperation;
  final CancellableCompleter<R> completer = CancellableCompleter<R>(
    cancellationToken,
    onCancel: () => myAsyncOperation?.cancel(),
  );
  // Only attempt to create the receive port and start the isolate if the token
  // hasn't already been cancelled
  if (cancellationToken?.isCancelled != true) {
    myAsyncOperation = MyAsyncOperation();
    myAsyncOperation.start().then(
      (result) => completer.complete(result),
      onError: (error, stackTrace) => completer.completeError(
        error, 
        stackTrace,
      )
    );
  }
  return completer.future;
}
```

#### Using the Cancellable mixin

For more complex cancellables, you can use the Cancellable mixin.

* **DO** detach from the CancellationToken when your async task completes.
* **DON'T** attach to a CancellationToken that has already been cancelled, instead use the `maybeAttach` method to check if it's already been cancelled and only start your async task if it returns `false.
* **DON'T** cancel the CancellationToken within a Cancellable, as it may be used for other tasks.

```dart
class MyCancellable with Cancellable {
  MyCancellable(this.cancellationToken)
    : _completer = Completer() {
    // Call `maybeAttach()` to only attach if the cancellation token hasn't 
    // already been cancelled
    if (maybeAttach(this.cancellationToken)) {
      // Start your async task here
    }
  }

  final Completer _completer;

  Future<MyReturnType> get future => _completer.future;
  
  void complete() {
    // If your async task completes before the token is cancelled, 
    // detatch from the token and complete any futures with the result
    detach();
    _completer.complete(MyReturnType(...));
  }

  @override
  void onCancel(Exception exception) {
    super.onCancel(exception);
    // Clean up resources here, like closing an HttpClient, and complete 
    // any futures with the cancellation exception and stacktrace
    _completer.completeError(exception, cancellationStackTrace)
    
  }
}
```
