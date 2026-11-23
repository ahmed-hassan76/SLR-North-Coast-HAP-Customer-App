import 'package:material_ui/material_ui.dart';

import '../config/customer_support_config.dart';
import '../config/app_feature_registry.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            'Frequently Asked Questions',
            'Find answers to common questions about our services.',
          ),
          const SizedBox(height: 24),
          Panel(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final item in faqItems)
                    ExpansionTile(
                      key: PageStorageKey(item.question),
                      title: Text(
                        item.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: navy,
                        ),
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 22, 16),
                      children: [
                        Text(
                          item.answer,
                          style: const TextStyle(color: inkMuted, height: 1.45),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Customer Support', style: heading(25)),
                  const SizedBox(height: 8),
                  for (final contact in SupportContact.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: mist,
                        child: Icon(switch (contact) {
                          SupportContact.hotline => Icons.phone_outlined,
                          SupportContact.email => Icons.mail_outline,
                          SupportContact.whatsApp => Icons.chat_outlined,
                        }, color: sea),
                      ),
                      title: Text(contact.label),
                      subtitle: SelectableText(contact.value),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
