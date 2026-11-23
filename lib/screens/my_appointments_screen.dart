import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../config/app_feature_registry.dart';
import '../models/appointment.dart';
import '../models/booking_status.dart';
import '../services/appointment_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';
import '../widgets/booking_cancellation.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key, required this.repository});
  final AppointmentRepository repository;
  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late Future<List<Appointment>> _bookings = _load();
  Timer? _statusTimer;
  bool _cancelling = false;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<List<Appointment>> _load() async {
    final bookings = await widget.repository.myAppointments();
    if (!mounted) return bookings;
    _statusTimer?.cancel();
    final now = widget.repository.clock().toLocal();
    final scheduled = bookings.where(
      (a) => a.statusOn(now) == BookingStatus.scheduled,
    );
    if (scheduled.isNotEmpty) {
      // Recheck cancellation at midnight and completion just after the end time.
      var next = DateTime(now.year, now.month, now.day + 1);
      for (final booking in scheduled) {
        final completion = booking.end.add(const Duration(milliseconds: 1));
        if (completion.isBefore(next)) next = completion;
      }
      _statusTimer = Timer(next.difference(now), _refresh);
    }
    return bookings;
  }

  Future<void> _cancel(Appointment booking) async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      final confirmed = await confirmBookingCancellation(
        context,
        title: 'Cancel Appointment?',
        message: 'Are you sure you want to cancel this appointment?',
        keepLabel: 'Keep Appointment',
        confirmLabel: 'Yes, Cancel Appointment',
      );
      if (confirmed != true || !mounted) return;
      String message;
      try {
        await widget.repository.cancel(booking);
        message = 'Your appointment has been cancelled successfully.';
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
      _bookings = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: PageHeading(
                  myAppointmentsFeature.name,
                  myAppointmentsFeature.description,
                ),
              ),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Refresh appointments',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Appointment>>(
            future: _bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Panel(
                  child: Column(
                    children: [
                      const Text('Your appointments could not be loaded.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              final bookings = snapshot.requireData;
              final now = widget.repository.clock();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bookings.isEmpty)
                    const Panel(
                      child: Text(
                        "You haven't scheduled any appointments yet.",
                      ),
                    ),
                  for (final status in BookingStatus.values)
                    if (bookings.any((b) => b.statusOn(now) == status)) ...[
                      Text(switch (status) {
                        BookingStatus.scheduled => 'Upcoming appointments',
                        BookingStatus.completed => 'Past appointments',
                        BookingStatus.cancelled => 'Cancelled appointments',
                      }, style: heading(23)),
                      for (final b in bookings.where(
                        (b) => b.statusOn(now) == status,
                      ))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(b.department.name, style: heading(22)),
                                    BookingStatusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  MaterialLocalizations.of(context)
                                      .formatShortDate(b.date),
                                ),
                                Text(b.timeSlot),
                                const Divider(height: 24, color: line),
                                SelectableText(
                                  'Appointment ID: ${b.id}',
                                  style: const TextStyle(color: inkMuted),
                                ),
                                if (b.canCancelOn(now)) ...[
                                  const SizedBox(height: 14),
                                  CancelBookingButton(
                                    label: 'Cancel Appointment',
                                    onPressed: _cancelling
                                        ? null
                                        : () => _cancel(b),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, appointmentFeature.route),
                    child: const Text('Schedule an Appointment'),
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
