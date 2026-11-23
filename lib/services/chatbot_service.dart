import '../config/app_feature_registry.dart';
export '../config/app_feature_registry.dart' show ChatIntent;

class ChatbotService {
  static const welcome =
      "Hello! I'm your HAP Customer Assistant. What can I help you with today?";
  static String _normalize(String message) => message
      .toLowerCase()
      .replaceAll(RegExp("['’]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  static ChatIntent detect(String message) {
    final words = _normalize(message);
    if (const {
      'hello',
      'hi',
      'hey',
      'hello there',
      'hi there',
      'good morning',
      'good evening',
    }.contains(words)) {
      return ChatIntent.greeting;
    }
    // Removing articles and stay qualifiers makes "cancel my upcoming visit"
    // and "cancel a visit" share the same rule.
    const qualifiers = {
      'a',
      'an',
      'the',
      'my',
      'upcoming',
      'next',
      'future',
      'scheduled',
      'planned',
    };
    final meaningfulWords = words
        .split(' ')
        .where((word) => !qualifiers.contains(word));
    final phrase = ' ${meaningfulWords.join(' ')} ';

    for (final intent in ChatIntent.values) {
      final topic = topicsByIntent[intent];
      if (topic == null) continue;
      if (topic.aliases.contains(words) ||
          topic.questions.any((q) => _normalize(q.question) == words) ||
          topic.phrases.any((pattern) => phrase.contains(' $pattern '))) {
        return intent;
      }
    }
    return ChatIntent.unknown;
  }

  static String answer(ChatIntent intent) {
    if (intent == ChatIntent.greeting) {
      return 'Hello! How can I help you with the HAP North Coast app today?';
    }
    return topicsByIntent[intent]?.reply ??
        "I'm sorry, I couldn't find an answer to that question. You can check the FAQ section or contact customer support for further assistance.";
  }
}
