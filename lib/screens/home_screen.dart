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
    const services = [
      (
        title: 'Resident Feedback & Complaints',
        description: 'Share your feedback or report an issue.',
        button: 'Open Form',
        icon: Icons.chat_bubble_outline,
        route: '/feedback',
      ),
      (
        title: 'Resident Satisfaction Survey',
        description: 'Tell us about your experience at the compound.',
        button: 'Start Survey',
        icon: Icons.fact_check_outlined,
        route: '/survey',
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
                      child: Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: mist,
                              child: Icon(service.icon, color: sea),
                            ),
                            const SizedBox(height: 20),
                            Text(service.title, style: heading(25)),
                            const SizedBox(height: 10),
                            Text(
                              service.description,
                              style: const TextStyle(
                                color: inkMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, service.route),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: Text(service.button),
                            ),
                          ],
                        ),
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
