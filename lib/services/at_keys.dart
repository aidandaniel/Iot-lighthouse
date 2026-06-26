import 'package:at_client/at_client.dart';

const appNamespace = 'iotprotector';
const protectionServiceAtSign = '@lyra6dj02_sp';
const threatMonitorAtSign = '@lyra6dj03_sp';

class IotKeys {
  const IotKeys._();

  static AtKey companyProfile({String? sharedWith}) {
    return _shared('company.profile', sharedWith: sharedWith);
  }

  static AtKey deviceRegistry({String? sharedWith}) {
    return _shared('devices.registry', sharedWith: sharedWith);
  }

  static AtKey deviceRecord(String deviceId, {String? sharedWith}) {
    return _shared('device.$deviceId.record', sharedWith: sharedWith);
  }

  static AtKey telemetry(String deviceId, String readingId,
      {String? sharedWith}) {
    return _shared('telemetry.$deviceId.$readingId', sharedWith: sharedWith);
  }

  static AtKey traceLog(String deviceId, {String? sharedWith}) {
    return _shared('trace.$deviceId.log', sharedWith: sharedWith);
  }

  static AtKey protectionCommand(String deviceId, {String? sharedWith}) {
    return _shared('command.$deviceId.protection', sharedWith: sharedWith);
  }

  static AtKey alertFeed({String? sharedWith}) {
    return _shared('alerts.feed', sharedWith: sharedWith);
  }

  static AtKey alert(String alertId, {String? sharedWith}) {
    return _shared('alert.$alertId', sharedWith: sharedWith);
  }

  static AtKey mutex(String requestId) {
    return AtKey()
      ..key = 'mutex.$requestId'
      ..namespace = appNamespace
      ..metadata = (Metadata()
        ..immutable = true
        ..ttl = 30000);
  }

  static AtKey _shared(String key, {String? sharedWith}) {
    return AtKey()
      ..key = key
      ..namespace = appNamespace
      ..sharedWith = sharedWith;
  }
}
