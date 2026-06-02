import 'package:flutter/material.dart';

/// Pops the navigation stack back to [AppHomePage] (first route under [MaterialApp]).
void navigateDonorHome(BuildContext context) {
  Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
}
