import '../services/appointment_repository.dart';
import '../config/app_feature_registry.dart';
import '../screens/schedule_appointment_screen.dart';
import '../screens/my_appointments_screen.dart';

import 'package:material_ui/material_ui.dart';

import '../screens/feedback_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_stays_screen.dart';
import '../screens/plan_stay_screen.dart';
import '../screens/survey_screen.dart';
import '../services/mock_auth_service.dart';
import '../services/stay_repository.dart';
import '../services/submission_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/customer_assistant.dart';

class PortalApp extends StatelessWidget {
  const PortalApp({
    super.key,
    required this.auth,
    required this.repository,
    required this.stays,
    required this.appointments,
  });
  final MockAuthService auth;
  final SubmissionRepository repository;
  final StayRepository stays;
  final AppointmentRepository appointments;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final resident = auth.currentResident;
        return MaterialApp(
          // Start a fresh navigation stack when a resident logs in or out.
          key: ValueKey(resident),
          title: 'HAP North Coast',
          theme: portalTheme(),
          builder: (_, navigator) => resident == null
              ? navigator!
              : CustomerHelpSession(child: navigator!),
          debugShowCheckedModeBanner: false,
          home: resident == null
              ? LoginScreen(auth: auth)
              : HomeScreen(resident: resident, onLogout: auth.logout),
          routes: resident == null
              ? {}
              : {
                  feedbackFeature.route: (_) => FeedbackScreen(
                    resident: resident,
                    repository: repository,
                  ),
                  surveyFeature.route: (_) =>
                      SurveyScreen(repository: repository),
                  stayFeature.route: (_) =>
                      PlanStayScreen(resident: resident, repository: stays),
                  myStaysFeature.route: (_) => MyStaysScreen(repository: stays),
                  appointmentFeature.route: (_) => ScheduleAppointmentScreen(
                    resident: resident,
                    repository: appointments,
                  ),
                  myAppointmentsFeature.route: (_) =>
                      MyAppointmentsScreen(repository: appointments),
                  '/faq': (_) => const FaqScreen(),
                },
          onUnknownRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => resident == null
                ? LoginScreen(auth: auth)
                : HomeScreen(resident: resident, onLogout: auth.logout),
          ),
        );
      },
    );
  }
}
