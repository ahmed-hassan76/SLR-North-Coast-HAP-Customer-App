# HAP North Coast Resident Portal

A Flutter prototype for residents to submit feedback, report complaints, and complete a five-question satisfaction survey. The same app runs on Chrome and Android.

## Run from the VS Code terminal

Open this project folder and run the following command for Chrome.

```powershell
flutter run -d chrome
```

For the configured Android emulator, launch the Pixel 4 and wait for its home screen.

```powershell
flutter emulators --launch Pixel_4
flutter devices
```

With the Pixel 4 running as the first emulator, start the app with the following command. If Flutter lists a different ID for the Pixel 4, use that ID in the command.

```powershell
flutter run -d emulator-5554
```

Use the fictional phone number `01000000000` and password `Demo1234`. In debug mode, **Fill demo credentials** enters them for you. Tap **Login** to continue.

## Storage and follow-up

The running app owns one in-memory repository. Submissions survive navigation and logout within that instance. Refreshing Chrome or restarting the app clears the session and all records. Use fictional data only.

Each record includes its ID, UTC timestamp, and an immutable snapshot of the resident's ID, name, and phone. A complaint gets **Pending Follow-up**. Feedback gets **Received**. A survey gets **Pending Follow-up** if any score is 1, 2, or 3. The record keeps each triggering question and its score. **Not Applicable / Not Used** counts as an answer and is excluded from scoring. All other completed surveys get **Received**.

## Where to make changes

| Path | Purpose |
| --- | --- |
| `lib/main.dart`, `lib/app/` | Create the services, retain the session, and protect navigation. |
| `lib/screens/` | Login, home, feedback, and survey screens. The service list in `home_screen.dart` defines the home cards. |
| `lib/models/` | Resident and submission records, survey questions, ratings, and follow-up rules. |
| `lib/services/` | Mock login and logout, submission validation, and in-memory storage. |
| `lib/theme/`, `lib/widgets/` | Shared colors, typography, layouts, and submission confirmation. |
| `assets/images/north_coast.jpg` | Original generated coastal image bundled with the app. |
| `test/` | Unit tests for the records and business rules, plus mobile and desktop widget tests. |

## Connecting a backend later

Replace the credential check in `MockAuthService` with an authentication API and use its session to load the resident. Replace the in-memory writes in `SubmissionRepository` with authenticated requests. The server should derive the resident from the session, validate each submission, assign its ID and timestamp, and apply the same follow-up rules before saving. When these calls become asynchronous, keep the submit button disabled while saving, show the confirmation after the server acknowledges the write, and allow retry after an error.

## Checks

```powershell
dart format lib test
flutter analyze
flutter test
```
