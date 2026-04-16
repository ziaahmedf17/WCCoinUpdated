import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/firebase_options.dart';
import 'package:wc_coin_app/screens/splash/splash.dart';
import 'package:wc_coin_app/services/push_notifications.dart';

Map<String, dynamic> apads = {};

/// Reliable internet check using DNS lookup — works on both WiFi and mobile data.
/// connectivity_plus only checks if a network interface is active, not reachability.
Future<bool> checkInternetConnection() async {
  final hosts = ['google.com', 'cloudflare.com', '8.8.8.8'];
  for (final host in hosts) {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      continue;
    }
  }
  return false;
}

bool _isLoginEnabled = false;

Future<bool> getLoginEnableStatus() async {
  try {
    DatabaseReference ref = FirebaseDatabase.instance.ref("WcIsLoginEnabled");
    DatabaseEvent de = await ref.once();

    if (de.snapshot.value != null) {
      Map<String, dynamic> data =
          Map<String, dynamic>.from(de.snapshot.value as Map);
      _isLoginEnabled = data['isEnabled'] ?? false;
      return _isLoginEnabled;
    } else {
      _isLoginEnabled = false;
      return false;
    }
  } catch (e) {
    _isLoginEnabled = false;
    return false;
  }
}

bool get isLoginEnabled => _isLoginEnabled;

Future<Map<String, dynamic>> getAdValues() async {
  DatabaseReference ref = FirebaseDatabase.instance.ref("WCAds");
  DatabaseEvent de = await ref.once();
  if (de.snapshot.value != null) {
    Map<String, dynamic> ads =
        Map<String, dynamic>.from(de.snapshot.value as Map);
    return ads;
  } else {
    throw Exception('');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseNotifications().initNotifications();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  if (await checkInternetConnection() == true) {
    apads = await getAdValues();

    await getLoginEnableStatus();
    log(isLoginEnabled.toString());

    await _initializeCrashlytics();
    final adsProvider = GoogleAdmobProvider();
    await adsProvider.initializeAds();

    print(AppAdIds);
  } else {
    apads = {
      'banner': false,
      'int': false,
      'native': false,
    };
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (c) => GoogleAdmobProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: MaterialApp(
          title: 'WC Coin',
          theme: ThemeData(useMaterial3: false),
          debugShowCheckedModeBanner: false,
          navigatorObservers: [observer],
          home: const SplashView(),
        ),
      ),
    );
  }
}

Future<void> _initializeCrashlytics() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
