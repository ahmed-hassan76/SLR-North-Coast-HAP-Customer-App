# HAP North Coast Resident Portal

A Flutter prototype for residents to submit feedback, report complaints, complete a five-question satisfaction survey, plan visits to their parcel, and book department appointments. The same app runs on Chrome and Android.

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

Use the fictional phone number `01000000000` and password `Demo1234`. Tap **Login** to continue.

## Storage and follow-up

Feedback and surveys use an in-memory repository. Those submissions survive navigation and logout within the running app. Refreshing Chrome or restarting the app clears the session and those records. Use fictional data only.

Each record includes its ID, UTC timestamp, and an immutable snapshot of the resident's ID, name, and phone. A complaint gets **Pending Follow-up**. Feedback gets **Received**. A survey gets **Pending Follow-up** if any score is 1, 2, or 3. The record keeps each triggering question and its score. **Not Applicable / Not Used** counts as an answer and is excluded from scoring. All other completed surveys get **Received**.

## Plan Your Stay

Stay requests use a separate persistent repository. From home, choose **Plan My Stay**, select one of the 15 parcels and both dates, then choose **Confirm My Stay**. After **OK**, open **My Stays** to see the request. **Plan Another Stay** adds another record.

Each stay has its own key in Chrome local storage or Android app-private preferences. **My Stays** loads the current resident's records. A stay remains **Scheduled** throughout departure day and becomes **Completed** the next local calendar day. Opening the list or choosing **Refresh stays** recalculates the order and status. The confirmation records the visit for this prototype. Physical service activation is outside its scope.

To demonstrate persistence across development server restarts, use the same regular Chrome profile and address each time. Run `flutter run -d web-server --web-hostname localhost --web-port 7357`, open `http://localhost:7357` in Chrome, and sign in again after a reload. Clearing site data or Android app data removes the corresponding local stays.

## Where to make changes

### Stay cancellation and customer help

In **My Stays**, **Cancel Stay** is available through the calendar day before arrival. **Keep My Stay** dismisses the confirmation. **Yes, Cancel Stay** checks the saved request again and adds a UTC cancellation timestamp to that same record. Earlier requests load without a timestamp. Cancelled stays keep their status after departure and appear after completed visits, most recently cancelled first.

Every signed-in page provides **FAQ** and **AI Assistant** controls. Open the FAQ to expand a question or view the support contacts. Open the assistant over a partly filled form, ask “How do I cancel my booking?”, then close it to continue the form. Conversation history lasts until logout or restart. Replies come from local Dart rules and never perform a resident action.

### Registering a customer feature

After implementing a customer feature, add its authenticated route in `lib/app/portal_app.dart`. In `lib/config/app_feature_registry.dart`, create an `AppFeature` with the name, home description, route, and one or more `FeatureTopic` entries. Add the feature to `appFeatures` and, when it needs a home card, reference it in `HomeScreen`.

For each topic, supply its FAQ questions and answers, an intent, and common phrases. The assistant uses the first FAQ answer by default. Supply `chatReply` only when conversational wording or dynamic details are needed. Order specific intents before broader ones in `ChatIntent`. The FAQ list and chat lookup are derived from the registry. Add example questions and ambiguity cases to `test/chatbot_service_test.dart`. Keep development notes in code or documentation.

Edit `lib/config/customer_support_config.dart` to update all customer support methods in both help interfaces.

### Department appointments

Choose **Book Appointment** on the home page, pick a date and department, select an available slot, and confirm. Open **My Appointments** after signing in again to see the saved booking. For a browser restart test, use the same Chrome profile and localhost address described above.

Edit `lib/config/appointment_config.dart` for department names, opening and closing hours, slot duration, or working weekdays. Keep the department ID stable when renaming a department. Saved records retain the name and time range at booking. The slot generator, FAQ, and assistant all read the same schedule.

Each slot has a key under `hap.appointments.v1/` composed of date, stable department ID, and start minute. The key retains its booking history and also accepts the original single-booking format. In **My Appointments**, residents can cancel before the appointment date. Cancellation releases the slot immediately. Rebooking appends a new appointment with its own ID. Appointments stay scheduled through their end time, and cancelled entries retain their status. The tracking page shows only the signed-in resident's entries. Chrome uses site storage and Android uses app-private preferences. Clearing that storage removes its bookings.

### Project layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart`, `lib/app/` | Create the services, retain the session, and protect navigation. |
| `lib/screens/` | Resident service forms, tracking pages, login, home, and FAQ. |
| `lib/models/` | Residents, submission records, survey rules, and date-based stay status and duration. |
| `lib/services/` | Mock authentication, in-memory feedback and surveys, and stay and appointment repositories with shared local storage adapters. |
| `android/app/src/main/kotlin/com/example/customer_app/MainActivity.kt` | Android's app-private record storage. |
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
