import '../config/app_feature_registry.dart';

import 'package:material_ui/material_ui.dart';

import '../models/resident.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.resident, required this.onLogout});
  final Resident resident;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final services = [
      (
        guide: feedbackFeature,
        button: 'Open Form',
        icon: Icons.chat_bubble_outline,
        tracking: null,
      ),
      (
        guide: surveyFeature,
        button: 'Start Survey',
        icon: Icons.fact_check_outlined,
        tracking: null,
      ),
      (
        guide: stayFeature,
        button: 'Plan My Stay',
        icon: Icons.calendar_month_outlined,
        tracking: myStaysFeature,
      ),
      (
        guide: appointmentFeature,
        button: 'Book Appointment',
        icon: Icons.event_available_outlined,
        tracking: myAppointmentsFeature,
      ),
    ];
    return PortalScaffold(
      maxWidth: 960,
      onLogout: onLogout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            'Welcome, ${resident.name}',
            'How can we help you today?',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, size) {
              final width = size.maxWidth >= 640
                  ? (size.maxWidth - 18) / 2
                  : size.maxWidth;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final service in services)
                    SizedBox(
                      width: width,
                      child: _ServiceCard(
                        feature: service.guide,
                        icon: service.icon,
                        button: service.button,
                        tracking: service.tracking,
                      ),
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.feature,
    required this.icon,
    required this.button,
    this.tracking,
  });
  final AppFeature feature;
  final IconData icon;
  final String button;
  final AppFeature? tracking;

  @override
  Widget build(BuildContext context) {
    void plan() => Navigator.pushNamed(context, feature.route);
    return Panel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: plan,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: mist,
                  child: Icon(icon, color: sea),
                ),
                const SizedBox(height: 20),
                Text(feature.name, style: heading(25)),
                const SizedBox(height: 10),
                Text(
                  feature.description,
                  style: TextStyle(color: inkMuted, height: 1.4),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: plan,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(button),
                    ),
                    if (tracking != null)
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, tracking!.route),
                        child: Text(tracking!.name),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
