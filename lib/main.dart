import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/vip_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VipService.instance.load();
  runApp(const HelloChatApp());
}

class HelloChatApp extends StatelessWidget {
  const HelloChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloChat Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
