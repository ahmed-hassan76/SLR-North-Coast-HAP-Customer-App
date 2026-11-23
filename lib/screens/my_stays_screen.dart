import 'package:material_ui/material_ui.dart';

import '../models/stay_request.dart';
import '../services/stay_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';
import '../widgets/booking_cancellation.dart';

class MyStaysScreen extends StatefulWidget {
  const MyStaysScreen({super.key, required this.repository});
  final StayRepository repository;
  @override
  State<MyStaysScreen> createState() => _MyStaysScreenState();
}

class _MyStaysScreenState extends State<MyStaysScreen> {
  late Future<List<StayRequest>> _stays = widget.repository.myStays();
  bool _cancelling = false;

  Future<void> _cancel(StayRequest stay) async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      final confirmed = await confirmBookingCancellation(
        context,
        title: 'Cancel Your Stay?',
        message: 'Are you sure you want to cancel this scheduled stay?',
        keepLabel: 'Keep My Stay',
        confirmLabel: 'Yes, Cancel Stay',
      );
      if (confirmed != true || !mounted) return;
      String message;
      try {
        await widget.repository.cancel(stay.id);
        message = 'Your stay has been cancelled successfully.';
      } on StateError catch (error) {
        message = error.message;
      } catch (_) {
        message = 'Your cancellation could not be saved. Please try again.';
      }
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _refresh() {
    setState(() {
      _stays = widget.repository.myStays();
    });
  }

  Future<void> _plan() async {
    await Navigator.pushNamed(context, '/plan-stay');
    if (mounted && ModalRoute.of(context)?.isCurrent == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PageHeading(
                  'My Stays',
                  'View and track your planned visits.',
                ),
              ),
              IconButton(
                tooltip: 'Refresh stays',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<StayRequest>>(
            future: _stays,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Panel(
                  child: Column(
                    children: [
                      const Text('Your stays could not be loaded.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              final stays = snapshot.requireData;
              if (stays.isEmpty) {
                return Panel(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        backgroundColor: mist,
                        child: Icon(Icons.calendar_month_outlined, color: sea),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "You haven't planned any stays yet.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _plan,
                        child: const Text('Plan Your First Stay'),
                      ),
                    ],
                  ),
                );
              }
              final today = widget.repository.clock();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final stay in stays)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StayCard(
                        stay: stay,
                        status: stay.statusOn(today),
                        canCancel: stay.canCancelOn(today),
                        onCancel: _cancelling ? null : () => _cancel(stay),
                      ),
                    ),
                  FilledButton(
                    onPressed: _plan,
                    child: const Text('Plan Another Stay'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.stay,
    required this.status,
    required this.canCancel,
    required this.onCancel,
  });
  final bool canCancel;
  final VoidCallback? onCancel;
  final StayRequest stay;
  final StayStatus status;

  @override
  Widget build(BuildContext context) {
    final format = MaterialLocalizations.of(context).formatShortDate;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Parcel ${stay.parcel}', style: heading(25)),
              BookingStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          Text('Arrival Date: ${format(stay.arrival)}'),
          const SizedBox(height: 6),
          Text('Departure Date: ${format(stay.departure)}'),
          const SizedBox(height: 6),
          Text(
            'Stay Duration: ${stay.nights} ${stay.nights == 1 ? 'Night' : 'Nights'}',
          ),
          const Divider(height: 26, color: line),
          SelectableText(
            'Request ID: ${stay.id}',
            style: const TextStyle(color: inkMuted, fontSize: 13),
          ),
          if (canCancel) ...[
            const SizedBox(height: 14),
            CancelBookingButton(label: 'Cancel Stay', onPressed: onCancel),
          ],
        ],
      ),
    );
  }
}
