import 'package:flutter/material.dart';
import 'screens/live_stream_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LiveStreamScreen(),
    );
  }
}
