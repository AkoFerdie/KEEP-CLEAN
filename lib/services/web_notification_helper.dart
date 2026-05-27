// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void showWebPatrolNotification(String title, String body) {
  try {
    js.context.callMethod('showPatrolNotification', [title, body]);
  } catch (_) {}
}
