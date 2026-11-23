import 'package:customer_app/config/customer_support_config.dart';
import 'package:customer_app/services/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final examples = <ChatIntent, List<String>>{
    ChatIntent.complaint: [
      'Where can I file a complaint?',
      'How do I submit a complaint?',
      'I want to report an issue.',
      'I have a problem with the compound.',
    ],
    ChatIntent.feedback: [
      'How can I give feedback?',
      'I want to leave a suggestion.',
      'Where can I share my opinion?',
    ],
    ChatIntent.survey: [
      'Where is the satisfaction survey?',
      'How can I rate the compound?',
      'I want to complete the questionnaire.',
    ],
    ChatIntent.plan: [
      'How do I schedule my visit?',
      'I am coming to the compound.',
      'I want to plan my stay.',
      'How do I tell you when I am arriving?',
    ],
    ChatIntent.track: [
      'Where can I see my visits?',
      'How do I track my stay?',
      'Where can I view my scheduled requests?',
    ],
    ChatIntent.cancel: [
      'How can I cancel my visit?',
      'I want to cancel my stay.',
      'Can I cancel my stay booking?',
      'Can I cancel my booking for a stay?',
      'How can I plan my stay and then CANCEL... my scheduled VISIT?',
    ],
    ChatIntent.support: [
      'Where can I find your contact information?',
      'I need customer support.',
      'How can I contact customer service?',
      'What is the hotline?',
      'What is your phone number?',
      'What is your email?',
      'Do you have WhatsApp?',
      'I want to speak to someone.',
    ],
    ChatIntent.greeting: [
      'Hello',
      'HI!!',
      'hey',
      'good morning',
      'Good evening.',
    ],
    ChatIntent.appointmentBooking: [
      'How do I book an appointment?',
      'I need to meet a department.',
      'Can I schedule a meeting?',
      'Where can I reserve a time slot?',
      'How can I avoid waiting at the office?',
    ],
    ChatIntent.appointmentCancellation: [
      'How do I cancel my appointment?',
      'Can I cancel my booking?',
      "I don't need my appointment anymore.",
      'Where can I cancel my meeting?',
      'Can I cancel my scheduled appointment?',
    ],
    ChatIntent.appointmentHours: [
      'What are the appointment hours?',
      'How long is an appointment?',
    ],
    ChatIntent.appointmentTracking: [
      'Where can I see my appointment?',
      'Where can I view my appointments?',
    ],
    ChatIntent.unknown: [
      'What are the pool fees?',
      'Which parcel has a cafe?',
      'cancel a payment',
      'what time is dinner during my stay?',
      'schedule multiple lessons',
      '',
      '   ',
    ],
  };
  for (final entry in examples.entries) {
    test('recognizes ${entry.key.name} and returns a stable answer', () {
      for (final question in entry.value) {
        final intent = ChatbotService.detect(question);
        expect(intent, entry.key, reason: question);
        expect(ChatbotService.answer(intent), isNotEmpty);
        expect(
          ChatbotService.answer(ChatbotService.detect(question)),
          ChatbotService.answer(intent),
        );
      }
    });
  }
  test('support answer reads the updated shared contacts', () {
    expect(SupportContact.values.map((c) => c.value), [
      '19172',
      'info@hap.com.eg',
      '+201002765455',
    ]);
    final reply = ChatbotService.answer(ChatIntent.support);
    for (final contact in SupportContact.values) {
      expect(reply, contains('${contact.label}: ${contact.value}'));
    }
  });
  test('appointment and stay cancellation direct residents to their respective bookings', () {
    expect(
      ChatbotService.answer(ChatbotService.detect('Can I cancel my booking?')),
      'You can cancel your appointment through My Appointments. Select Cancel Appointment on the relevant booking. Cancellation is only available before the appointment date.',
    );
    expect(
      ChatbotService.answer(ChatbotService.detect('How do I cancel my stay?')),
      contains('My Stays'),
    );
  });
}
