import 'package:flutter/material.dart';

class AdActions {
//open another sccreen
  static String screenName = "";
  static var context;
  static void OpenScreen() {
    if (screenName == "Home") {
    } else {}
    //use named routes
    print("Router Home called with $screenName");
    screenName = "";
  }
}
