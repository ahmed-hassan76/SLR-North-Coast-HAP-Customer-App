import 'package:material_ui/material_ui.dart';

import '../services/chatbot_service.dart';
import '../theme/portal_theme.dart';

typedef ChatMessage = ({String text, bool fromResident});

// Owned by the authenticated navigator. Logging out disposes the entire session.
class CustomerHelpSession extends StatefulWidget {
  const CustomerHelpSession({super.key, required this.child});
  final Widget child;

  static List<ChatMessage>? historyOf(BuildContext context) =>
      context.findAncestorStateOfType<_CustomerHelpSessionState>()?.history;

  @override
  State<CustomerHelpSession> createState() => _CustomerHelpSessionState();
}

class _CustomerHelpSessionState extends State<CustomerHelpSession> {
  final history = <ChatMessage>[
    (text: ChatbotService.welcome, fromResident: false),
  ];
  @override
  Widget build(BuildContext context) => widget.child;
}

class CustomerAssistant extends StatefulWidget {
  const CustomerAssistant({super.key, required this.history});
  final List<ChatMessage> history;

  @override
  State<CustomerAssistant> createState() => _CustomerAssistantState();
}

class _CustomerAssistantState extends State<CustomerAssistant> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final intent = ChatbotService.detect(text);
    setState(() {
      widget.history.add((text: text, fromResident: true));
      widget.history.add((
        text: ChatbotService.answer(intent),
        fromResident: false,
      ));
      _input.clear();
    });
    // A reversed list keeps the newest bubble at scroll offset zero.
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    return Dialog(
      alignment: desktop ? Alignment.bottomRight : Alignment.bottomCenter,
      insetPadding: EdgeInsets.all(desktop ? 24 : 8),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 414,
        height: 494,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final compact = bounds.maxHeight < 250;
            final header = ColoredBox(
              color: navy,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  compact ? 0 : 8,
                  6,
                  compact ? 0 : 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'HAP Customer Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close assistant',
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            );
            final composer = Padding(
              padding: EdgeInsets.all(compact ? 4 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask me a question...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _input,
                    builder: (context, value, _) => IconButton.filled(
                      tooltip: 'Send',
                      onPressed: value.text.trim().isEmpty ? null : _send,
                      icon: const Icon(Icons.send_outlined),
                    ),
                  ),
                ],
              ),
            );
            Widget panel() => Column(
              children: [
                header,
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    itemCount: widget.history.length,
                    itemBuilder: (_, index) => _Bubble(
                      widget.history[widget.history.length - 1 - index],
                    ),
                  ),
                ),
                const Divider(height: 1, color: line),
                composer,
              ],
            );
            if (bounds.maxHeight < 180) {
              return SingleChildScrollView(
                child: SizedBox(height: 250, child: panel()),
              );
            }
            return panel();
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final fromResident = message.fromResident;
    return Align(
      alignment: fromResident ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .87,
        alignment: fromResident ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: fromResident
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fromResident ? navy : mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: fromResident ? Colors.white : navy,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
