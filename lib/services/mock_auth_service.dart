import 'package:flutter/foundation.dart';

import '../models/resident.dart';

/// Fictional credentials for the Phase 1 prototype only.
class MockAuthService extends ChangeNotifier {
  static const demoResident = Resident(
    id: 'RES001',
    name: 'Demo Resident',
    phone: '01000000000',
  );
  static const demoPassword = 'Demo1234';
  Resident? _resident;
  Resident? get currentResident => _resident;

  bool login(String phone, String password) {
    if (phone.trim() != demoResident.phone || password != demoPassword) {
      return false;
    }
    _resident = demoResident;
    notifyListeners();
    return true;
  }

  void logout() {
    _resident = null;
    notifyListeners();
  }
}
