import '../models/faq_item.dart';
import 'appointment_config.dart';
import 'customer_support_config.dart';

// Intent order controls matching priority when a message mentions several topics.
enum ChatIntent {
  cancel,
  appointmentCancellation,
  appointmentTracking,
  appointmentHours,
  appointmentBooking,
  track,
  plan,
  complaint,
  feedback,
  survey,
  support,
  greeting,
  unknown,
}

class FeatureTopic {
  const FeatureTopic(
    this.intent,
    this.questions,
    this.phrases, {
    this.chatReply,
    this.aliases = const [],
  });
  final ChatIntent intent;
  final List<FaqItem> questions;
  final List<String> phrases;
  final List<String> aliases;
  final String? chatReply;
  String get reply => chatReply ?? questions.first.answer;
}

class AppFeature {
  const AppFeature(this.name, this.description, this.route, this.topics);
  final String name;
  final String description;
  final String route;
  final List<FeatureTopic> topics;
}

const feedbackFeature = AppFeature(
  'Resident Feedback & Complaints',
  'Share your feedback or report an issue.',
  '/feedback',
  [
    FeatureTopic(
      ChatIntent.complaint,
      [
        FaqItem(
          'How can I submit a complaint?',
          'From the Home Page, select Resident Feedback & Complaints. Choose Complaint as the submission type, describe your issue, and submit the form.',
        ),
      ],
      [
        'file complaint',
        'submit complaint',
        'make complaint',
        'lodge complaint',
        'report issue',
        'report problem',
        'problem with compound',
      ],
      aliases: ['complaint'],
      chatReply: 'You can submit a complaint through Resident Feedback & Complaints on the Home Page. Select Complaint, describe your issue, and submit the form.',
    ),
    FeatureTopic(
      ChatIntent.feedback,
      [
        FaqItem(
          'How can I provide feedback?',
          'Open Resident Feedback & Complaints from the Home Page, select Feedback, enter your comments, and submit.',
        ),
      ],
      [
        'give feedback',
        'provide feedback',
        'submit feedback',
        'share feedback',
        'leave feedback',
        'leave suggestion',
        'share opinion',
        'send comments',
      ],
      aliases: ['feedback'],
      chatReply: 'Open Resident Feedback & Complaints from the Home Page. Select Feedback, write your comments, and submit.',
    ),
  ],
);

const surveyFeature = AppFeature(
  'Resident Satisfaction Survey',
  'Tell us about your experience at the compound.',
  '/survey',
  [
    FeatureTopic(
      ChatIntent.survey,
      [
        FaqItem(
          'How can I complete the satisfaction survey?',
          'Select Resident Satisfaction Survey from the Home Page and rate your experience using the available questions.',
        ),
      ],
      [
        'satisfaction survey',
        'rate compound',
        'rate experience',
        'complete questionnaire',
        'complete survey',
        'take survey',
        'fill out survey',
      ],
      aliases: ['survey', 'questionnaire'],
      chatReply: 'You can complete the Resident Satisfaction Survey from the Home Page. Rate your experience using the available questions and submit your responses.',
    ),
  ],
);

const stayFeature = AppFeature(
  'Plan Your Stay',
  "Let us know when you're visiting, and we'll prepare your neighborhood for your arrival.",
  '/plan-stay',
  [
    FeatureTopic(
      ChatIntent.plan,
      [
        FaqItem(
          'How do I schedule my next visit?',
          'Select Plan Your Stay from the Home Page, choose your Parcel, enter your arrival and departure dates, and confirm your stay.',
        ),
        FaqItem(
          'Can I schedule more than one stay?',
          'Yes. You can schedule multiple future stays through Plan Your Stay.',
        ),
      ],
      [
        'schedule visit',
        'schedule stay',
        'plan stay',
        'plan visit',
        'book stay',
        'book visit',
        'schedule multiple stays',
        'schedule multiple visits',
        'schedule more than one stay',
        'coming to compound',
        'when i am arriving',
        'when im arriving',
        'when i arrive',
      ],
      aliases: ['plan your stay'],
      chatReply: 'Select Plan Your Stay on the Home Page. Choose your Parcel, select your arrival and departure dates, and confirm your stay.',
    ),
  ],
);

const myStaysFeature = AppFeature(
  'My Stays',
  'View and track your planned visits.',
  '/my-stays',
  [
    FeatureTopic(
      ChatIntent.track,
      [
        FaqItem(
          'How can I track my scheduled visits?',
          'Open My Stays to view your scheduled, completed, and cancelled visits.',
        ),
      ],
      [
        'see visits',
        'view visits',
        'view requests',
        'track stay',
        'track visit',
        'track visits',
        'review stays',
        'view stays',
        'check booking',
        'see stays',
        'where are stays',
      ],
      aliases: ['my stays'],
      chatReply: 'Open My Stays to review your scheduled, completed, and cancelled visits.',
    ),
  ],
);

const cancellationFeature = AppFeature(
  'Stay Cancellation',
  'Cancel a scheduled stay before arrival.',
  '/my-stays',
  [
    FeatureTopic(
      ChatIntent.cancel,
      [
        FaqItem(
          'How do I cancel a scheduled stay?',
          'Open My Stays and select Cancel Stay on an eligible request. Cancellation is only available before your scheduled arrival date.',
        ),
      ],
      [
        'cancel stay',
        'cancel visit',
        'cancel booking for stay',
        'cancel booking for visit',
        'cancel parcel booking',
        'cancel reservation',
        'cancel stay request',
        'stay cancellation',
      ],
      aliases: [],
      chatReply: 'Open My Stays and select Cancel Stay on the relevant request. Cancellation is available only before the arrival date.',
    ),
  ],
);

final supportFeature = AppFeature(
  'Customer Support',
  'Contact customer support.',
  '/faq',
  [
    FeatureTopic(
      ChatIntent.support,
      [
        FaqItem(
          'How can I contact customer support?',
          'You can contact customer support through the hotline, email, or WhatsApp details provided below.',
        ),
      ],
      [
        'need customer support',
        'contact customer support',
        'contact customer service',
        'reach customer support',
        'speak to someone',
        'talk to someone',
        'speak to agent',
        'what is hotline',
        'whats hotline',
        'what is your phone number',
        'whats your phone number',
        'what is your email',
        'whats your email',
        'have whatsapp',
        'contact via whatsapp',
        'support contact',
        'contact information',
        'contact details',
        'your hotline',
        'your whatsapp',
        'support email',
        'hotline number',
        'email address',
        'whatsapp number',
      ],
      aliases: [
        'hotline',
        'email',
        'whatsapp',
        'customer support',
        'contact information',
        'contact details',
      ],
      chatReply:
          'You can contact customer support through:\n\n${SupportContact.values.map((c) => '${c.label}: ${c.value}').join('\n')}\n\nYou can also find these details in the FAQ section.',
    ),
  ],
);

final appointmentFeature = AppFeature(
  'Schedule Appointment',
  'Book a convenient time to meet with one of our departments.',
  '/appointment',
  [
    FeatureTopic(
      ChatIntent.appointmentBooking,
      const [
        FaqItem(
          'How do I schedule an appointment?',
          'Select Schedule Appointment from the Home Page. Choose your appointment date, department, and an available time slot, then confirm your booking.',
        ),
      ],
      const [
        'book appointment',
        'schedule appointment',
        'reserve appointment',
        'meet department',
        'meet with department',
        'schedule meeting',
        'book meeting',
        'reserve time slot',
        'avoid waiting at office',
      ],
      aliases: const ['appointment', 'appointments'],
    ),
    FeatureTopic(
      ChatIntent.appointmentHours,
      [
        FaqItem(
          'How long is each appointment?',
          'Each appointment slot lasts ${AppointmentConfig.duration}.',
        ),
        FaqItem(
          'What are the available appointment hours?',
          'Appointments are currently available between ${AppointmentConfig.formatTime(AppointmentConfig.openingHour * 60)} and ${AppointmentConfig.formatTime(AppointmentConfig.closingHour * 60)}, subject to slot availability.',
        ),
      ],
      const [
        'appointment hours',
        'appointment times',
        'how long is appointment',
        'how long is each appointment',
        'appointment duration',
        'how long does appointment',
      ],
      chatReply:
          'Appointment slots are currently available from ${AppointmentConfig.hours}. Each appointment lasts ${AppointmentConfig.duration}.',
    ),
  ],
);
const myAppointmentsFeature = AppFeature(
  'My Appointments',
  'Track your bookings and cancel an upcoming appointment.',
  '/my-appointments',
  [
    FeatureTopic(
      ChatIntent.appointmentCancellation,
      [
        FaqItem(
          'Can I cancel my scheduled appointment?',
          'Yes. Open My Appointments and select Cancel Appointment. Cancellation is available only before the appointment date.',
        ),
      ],
      [
        'cancel appointment',
        'cancel meeting',
        'cancel booking',
        'cancel department booking',
        'cancel office appointment',
        'appointment cancellation',
        'dont need appointment',
        'do not need appointment',
        'no longer need appointment',
      ],
      chatReply: 'You can cancel your appointment through My Appointments. Select Cancel Appointment on the relevant booking. Cancellation is only available before the appointment date.',
    ),
    FeatureTopic(
      ChatIntent.appointmentTracking,
      [
        FaqItem(
          'Where can I view my appointments?',
          'Open My Appointments to view your scheduled bookings.',
        ),
      ],
      [
        'view appointment',
        'view appointments',
        'see appointment',
        'see appointments',
        'track appointment',
        'find appointment',
        'view bookings',
        'see bookings',
      ],
      aliases: ['my appointments'],
    ),
  ],
);

final appFeatures = [
  feedbackFeature,
  surveyFeature,
  stayFeature,
  myStaysFeature,
  cancellationFeature,
  appointmentFeature,
  myAppointmentsFeature,
  supportFeature,
];
final topicsByIntent = {
  for (final feature in appFeatures)
    for (final topic in feature.topics) topic.intent: topic,
};
final faqItems = [
  for (final feature in appFeatures)
    for (final topic in feature.topics) ...topic.questions,
];
