import 'dart:io';
import 'package:flutter/material.dart';
import 'core/storage.dart';
import 'core/system_proxy_manager.dart';
import 'theme/vellor_theme.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.initialize();
  if (Platform.isWindows) {
    await SystemProxyManager.disableProxy();
  }
  runApp(const VellorApp());
}

class VellorApp extends StatelessWidget {
  const VellorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vellor Client',
      debugShowCheckedModeBanner: false,
      theme: TunyxTheme.darkTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
      home: const HomeScreen(),
    );
  }
}
