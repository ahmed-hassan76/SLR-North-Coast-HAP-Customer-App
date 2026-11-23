import 'package:material_ui/material_ui.dart';

import '../models/booking_status.dart';

Future<bool?> confirmBookingCancellation(
  BuildContext context, {
  required String title,
  required String message,
  required String keepLabel,
  required String confirmLabel,
}) => showDialog<bool>(
  context: context,
  builder: (dialog) => AlertDialog(
    scrollable: true,
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialog, false),
        child: Text(keepLabel),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(dialog).colorScheme.error,
        ),
        onPressed: () {
          if (ModalRoute.of(dialog)!.isCurrent) {
            Navigator.pop(dialog, true);
          }
        },
        child: Text(confirmLabel),
      ),
    ],
  ),
);

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge(this.status, {super.key});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.scheduled => const Color(0xFF235B87),
      BookingStatus.completed => const Color(0xFF276844),
      BookingStatus.cancelled => const Color(0xFF993A3A),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class CancelBookingButton extends StatelessWidget {
  const CancelBookingButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      side: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}
