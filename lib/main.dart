import 'package:material_ui/material_ui.dart';

import 'app/portal_app.dart';
import 'services/mock_auth_service.dart';
import 'services/submission_repository.dart';

void main() {
  final auth = MockAuthService();
  runApp(PortalApp(auth: auth, repository: SubmissionRepository(auth)));
}
