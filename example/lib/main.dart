import 'dart:io';
import 'dart:math';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:example/types/manually_cancelled_exception.dart';
import 'package:example/types/status.dart';
import 'package:example/types/task.dart';
import 'package:example/widgets/task_status_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cancellation Token',
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({Key? key}) : super(key: key);

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final Map<Task, Status> _tasks = {
    Task.delayedFuture: Status.stopped,
    Task.simultaneousA: Status.stopped,
    Task.simultaneousB: Status.stopped,
    Task.simultaneousC: Status.stopped,
    Task.compute: Status.stopped,
  };
  CancellationToken? _cancellationToken;

  Future<void> _startFutures() async {
    // Cancel any tasks currently running and create a new CancellationToken
    _cancellationToken?.cancel();
    _cancellationToken = CancellationToken();

    // Reset the status of the tasks
    setState(() => _tasks.updateAll((key, value) => Status.stopped));

    // Start the futures inside a try catch to handle cancellation
    try {
      // Existing futures can be made cancellable using the .asCancellable
      setState(() => _tasks[Task.delayedFuture] = Status.running);
      await delayedFuture().asCancellable(_cancellationToken);
      setState(() => _tasks[Task.delayedFuture] = Status.complete);

      // If you need to run multiple futures simultaneously, you can either
      // use `.asCancellable` on `Future.wait` itself, or use for each of
      // futures individually. The latter is a good a approach for situations
      // this, where the result is being handled using `.then`.
      setState(() {
        _tasks[Task.simultaneousA] = Status.running;
        _tasks[Task.simultaneousB] = Status.running;
        _tasks[Task.simultaneousC] = Status.running;
      });
      await Future.wait([
        delayedFuture().asCancellable(_cancellationToken).then((value) =>
            setState(() => _tasks[Task.simultaneousA] = Status.complete)),
        delayedFuture().asCancellable(_cancellationToken).then((value) =>
            setState(() => _tasks[Task.simultaneousB] = Status.complete)),
        delayedFuture().asCancellable(_cancellationToken).then((value) =>
            setState(() => _tasks[Task.simultaneousC] = Status.complete)),
      ]);

      // To run a function in a cancellable isolate, use cancellableCompute in
      // place of the Flutter's compute function
      setState(() => _tasks[Task.compute] = Status.running);
      await cancellableCompute(
        delayedIsolateFunction,
        const Duration(seconds: 2),
        _cancellationToken,
      );
      setState(() => _tasks[Task.compute] = Status.complete);
    } on CancelledException {
      // In some cases, like when cancelling tasks because in a widget's
      // dispose method, you'll want to catch the CancellationException but
      // ignore it. In these cases, you can wrap the code inside your try block
      // with the `ignoreCancellation()` function.
    } on ManuallyCancelledException {
      // If you need to ignore cancellations in some situations but not others
      // in the same try catch, you can pass a custom exception when cancelling
      // and handle it separately.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cancelled')),
      );
      setState(() {
        _tasks.entries
            .where((element) => element.value == Status.running)
            .forEach((element) => _tasks[element.key] = Status.stopped);
      });
    } catch (e) {
      // Other exceptions can still be handled normally
    }
  }

  @override
  void dispose() {
    _cancellationToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancellation Token'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TaskStatusDisplay(
              label: 'Delayed Future status',
              status: _tasks[Task.delayedFuture]!,
            ),
            TaskStatusDisplay(
              label: 'Simultaneous Future A status',
              status: _tasks[Task.simultaneousA]!,
            ),
            TaskStatusDisplay(
              label: 'Simultaneous Future B status',
              status: _tasks[Task.simultaneousB]!,
            ),
            TaskStatusDisplay(
              label: 'Simultaneous Future C status',
              status: _tasks[Task.simultaneousC]!,
            ),
            TaskStatusDisplay(
              label: 'Compute status',
              status: _tasks[Task.compute]!,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _startFutures,
              child: const Text('Run tasks'),
            ),
            ElevatedButton(
              onPressed: () => _cancellationToken?.cancel(
                ManuallyCancelledException(),
              ),
              child: const Text('Cancel running tasks'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple function with a random duration up to 8 seconds.
Future<void> delayedFuture() async {
  final int seconds = Random().nextInt(8);
  await Future.delayed(Duration(seconds: seconds));
}

/// A simple function for testing isolates.
///
/// If you cancel running tasks whilst this isolate is sleeping, the isolate
/// will be killed and you'll only see the 'Isolate started' message in the
/// console.
void delayedIsolateFunction(Duration delay) {
  if (kDebugMode) print('Isolate started - Waiting ${delay.inSeconds} seconds');
  sleep(delay);
  if (kDebugMode) print('Isolate finished');
}
