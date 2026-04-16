import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotifications {
  final _firebaseMsg = FirebaseMessaging.instance;
  Future<void> initNotifications() async {
    await _firebaseMsg.requestPermission();
    final fcmToken = await _firebaseMsg.getToken();
    print('Token: $fcmToken');
  }
}
