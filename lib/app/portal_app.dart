import 'package:material_ui/material_ui.dart';

import '../screens/feedback_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/survey_screen.dart';
import '../services/mock_auth_service.dart';
import '../services/submission_repository.dart';
import '../theme/portal_theme.dart';

class PortalApp extends StatelessWidget {
  const PortalApp({super.key, required this.auth, required this.repository});
  final MockAuthService auth;
  final SubmissionRepository repository;

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
          debugShowCheckedModeBanner: false,
          home: resident == null
              ? LoginScreen(auth: auth)
              : HomeScreen(resident: resident, onLogout: auth.logout),
          routes: resident == null
              ? {}
              : {
                  '/feedback': (_) => FeedbackScreen(
                    resident: resident,
                    repository: repository,
                  ),
                  '/survey': (_) => SurveyScreen(repository: repository),
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
