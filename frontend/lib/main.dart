import 'package:flutter/material.dart';
import 'package:farmconnect/core/theme/app_theme.dart';
import 'package:farmconnect/core/constants/app_constants.dart';
import 'package:farmconnect/widgets/navigation/main_screen.dart';

void main() {
  runApp(const FarmConnectApp());
}

class FarmConnectApp extends StatelessWidget {
  const FarmConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
