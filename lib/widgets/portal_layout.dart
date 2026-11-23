import 'package:material_ui/material_ui.dart';

import '../theme/portal_theme.dart';
import 'customer_assistant.dart';
import 'customer_help_buttons.dart';

class PortalScaffold extends StatelessWidget {
  const PortalScaffold({
    super.key,
    required this.child,
    this.onLogout,
    this.maxWidth = 760,
  });
  final Widget child;
  final VoidCallback? onLogout;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final history = CustomerHelpSession.historyOf(context);
    final page = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 40 : 16,
        vertical: wide ? 44 : 22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: navy,
        centerTitle: false,
        toolbarHeight: wide ? 76 : 64,
        titleSpacing: wide ? 32 : 16,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: line),
        ),
        title: Semantics(
          header: true,
          label: 'HAP North Coast',
          excludeSemantics: true,
          child: Image.asset(
            'assets/images/New HAP Logo - Horizontal.jpeg',
            height: wide ? 54 : 42,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        actions: [
          if (onLogout != null)
            Padding(
              padding: EdgeInsets.only(right: wide ? 24 : 8),
              child: TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: history == null
            ? page
            : LayoutBuilder(
                builder: (context, bounds) {
                  final help = CustomerHelpButtons(history: history);
                  if (bounds.maxHeight < 150) return page;
                  // Give the controls their own space so they never cover form actions.
                  if (bounds.maxWidth >= 1040 ||
                      (bounds.maxWidth >= 580 && bounds.maxHeight < 360)) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: bounds.maxHeight,
                            child: page,
                          ),
                        ),
                        help,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: page),
                      if (bounds.maxHeight >= 220) help,
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0915394B),
            offset: Offset(0, 5),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: heading(34))),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: inkMuted, fontSize: 16, height: 1.45),
        ),
      ],
    );
  }
}

Future<void> confirmSubmission(BuildContext context, String message) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.check_circle_outline, color: sea, size: 34),
      title: const Text('Submission received'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Back to home'),
        ),
      ],
    ),
  );
  if (context.mounted) Navigator.of(context).pop();
}
