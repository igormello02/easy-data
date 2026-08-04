import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import 'theme/app_theme.dart';

class EasyDataApp extends StatelessWidget {
  const EasyDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Data',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}
