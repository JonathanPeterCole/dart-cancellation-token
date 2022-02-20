import 'package:cancellation_token/cancellation_token.dart';

/// Runs a callback and silently catches cancellations. Other exceptions will be
/// rethrown.
///
/// If a custom exception is passed when cancelling the CancellationToken, it
/// won't be handled by this function.
///
/// ```dart
/// class DetailsPage extends StatefulWidget {
///   const DetailsPage({ Key? key }) : super(key: key);
///
///   @override
///   _DetailsPageState createState() => _DetailsPageState();
/// }
///
/// class _DetailsPageState extends State<DetailsPage> {
///   CancellationToken? cancellationToken;
///
///   Future<void> loadPage() async {
///     cancellationToken?.cancel();
///     cancellationToken = CancellationToken();
///     try {
///       await ignoreCancellation(() async {
///         response = getDetailsFromApi().asCancellable(cancellationToken);
///       });
///     } catch (e, stackTrace) {
///       // Other exceptions will still be caught
///     }
///   }
///
///   @override
///   void dispose() {
///     cancellationToken?.cancel();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     /// ...
///   }
/// }
/// ```
Future<void> ignoreCancellation(Future<dynamic> Function() callback) async {
  try {
    await callback();
  } on CancelledException {
    // Ignore cancellations
  } catch (e) {
    rethrow;
  }
}
