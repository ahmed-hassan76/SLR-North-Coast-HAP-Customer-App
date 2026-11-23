import 'dart:js_interop';

@JS('window.localStorage')
external _LocalStorage get _storage;

extension type _LocalStorage(JSObject _) implements JSObject {
  external int get length;
  external String? key(int index);
  external String? getItem(String key);
  external void setItem(String key, String value);
}

Future<void> writeRecord(String key, String value) async {
  _storage.setItem(key, value);
}

Future<String?> readRecord(String key) async => _storage.getItem(key);

@JS('navigator.locks')
external _WebLocks? get _locks;

extension type _WebLocks(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> request(String name, JSFunction callback);
}

Future<bool> compareAndSetRecord(
  String key,
  String? expected,
  String value,
) async {
  bool replace() {
    if (_storage.getItem(key) != expected) return false;
    _storage.setItem(key, value);
    return true;
  }

  // Serialize edits to this record across Chrome tabs on localhost and HTTPS.
  final locks = _locks;
  if (locks == null) return replace();
  final result = await locks
      .request(key, ((JSObject _) => replace().toJS).toJS)
      .toDart;
  return result.toDart;
}

Future<List<String>> readRecords(String prefix) async {
  final records = <String>[];
  for (var index = 0; index < _storage.length; index++) {
    final key = _storage.key(index);
    if (key != null && key.startsWith(prefix)) {
      final value = _storage.getItem(key);
      if (value != null) records.add(value);
    }
  }
  return records;
}
