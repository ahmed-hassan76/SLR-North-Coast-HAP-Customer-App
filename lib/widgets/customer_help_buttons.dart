import 'package:material_ui/material_ui.dart';

import '../theme/portal_theme.dart';
import 'customer_assistant.dart';

class CustomerHelpButtons extends StatelessWidget {
  const CustomerHelpButtons({super.key, required this.history});
  final List<ChatMessage> history;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 2,
      minimumSize: const Size(0, 40),
      shape: const StadiumBorder(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FilledButton.icon(
            style: style,
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('FAQ'),
            onPressed: route?.settings.name == '/faq'
                ? null
                : () {
                    if (route?.isCurrent == true) {
                      Navigator.pushNamed(context, '/faq');
                    }
                  },
          ),
          const SizedBox(height: 2),
          FilledButton.icon(
            style: style,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('AI Assistant'),
            onPressed: () {
              if (route?.isCurrent == true) {
                showDialog<void>(
                  context: context,
                  builder: (_) => CustomerAssistant(history: history),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
