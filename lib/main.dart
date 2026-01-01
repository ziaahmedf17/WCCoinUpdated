import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:wc_coin_app/screens/exm.dart';
import 'package:wc_coin_app/screens/profile/my_profile.dart';
import 'package:wc_coin_app/screens/splash/splash.dart';
import 'package:wc_coin_app/services/network_listener.dart';

Map<String, dynamic> apads = {};

Future<bool> checkInternetConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return true;
  } else {
    return false;
  }
}

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

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  if (await checkInternetConnection() == true) {
    apads = await getAdValues();

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
  print(apads);

  // AdHelper.init();

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
          home: const SplashView(),
          // home: ConnectivityWrapper(child: SplashView()),
          // home: PostApiDemo(),
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
