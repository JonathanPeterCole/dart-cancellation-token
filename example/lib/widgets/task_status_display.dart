import 'package:example/types/status.dart';
import 'package:flutter/material.dart';

class TaskStatusDisplay extends StatelessWidget {
  const TaskStatusDisplay({
    Key? key,
    required this.label,
    required this.status,
  }) : super(key: key);

  final String label;
  final Status status;

  @override
  Widget build(BuildContext context) {
    final Widget statusWidget;
    switch (status) {
      case Status.stopped:
        statusWidget = const Icon(Icons.cancel_outlined, color: Colors.red);
        break;
      case Status.running:
        statusWidget = const SizedBox.square(
          dimension: 18.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        );
        break;
      case Status.complete:
        statusWidget = const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
        );
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          SizedBox.square(dimension: 24.0, child: Center(child: statusWidget)),
        ],
      ),
    );
  }
}
