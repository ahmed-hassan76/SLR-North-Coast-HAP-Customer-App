import 'package:flutter/services.dart';

const _channel = MethodChannel('hap/stay_storage');

Future<String?> readRecord(String key) =>
    _channel.invokeMethod<String>('get', key);

Future<bool> compareAndSetRecord(
  String key,
  String? expected,
  String value,
) async => (await _channel.invokeMethod<bool>('replace', {
  'key': key,
  'expected': expected,
  'value': value,
}))!;

Future<void> writeRecord(String key, String value) =>
    _channel.invokeMethod<void>('save', {'key': key, 'value': value});

Future<List<String>> readRecords(String prefix) async =>
    (await _channel.invokeListMethod<String>('read', prefix))!;
