import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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

class ChatMessage {
  final String username;
  final String text;
  final Color color;
  final bool isOwn;

  const ChatMessage({
    required this.username,
    required this.text,
    required this.color,
    this.isOwn = false,
  });
}

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  // Camera
  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _cameraError;

  // Chat
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final _random = Random();

  Timer? _messageTimer;
  Timer? _viewerTimer;
  int _viewerCount = 1247;

  static const _simulatedUsers = [
    'Alex_B',
    'Sarah_M',
    'João99',
    'YukiChan',
    'DevMaster',
    'CoolKid42',
    'NightOwl',
    'StarGazer',
    'TechFan',
    'MusicLover',
    'xXDarkXx',
    'FlutterFan',
    'Watcher99',
    'Lila_R',
    'Mo_streams',
  ];

  static const _simulatedMessages = [
    '🔥🔥🔥',
    'Trop bien !',
    'Bonjour depuis Paris !',
    'Premier !',
    'C\'est incroyable',
    'Tu nous vois ?',
    '❤️❤️',
    'Trop fort',
    'Super stream',
    'Allez !!!',
    'Salut tout le monde !',
    '👋',
    'Magnifique !',
    'Encore !',
    'GG',
    '🎉🎉🎉',
    'oh là là',
    'meilleur live ever',
    '💯💯',
    'trop drôle',
    'j\'adore ce live',
    'continuez comme ça !',
    'vous êtes les meilleurs',
    'trop stylé 😍',
  ];

  static const _userColors = [
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.lightBlueAccent,
    Colors.tealAccent,
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startSimulation();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'Aucune caméra disponible');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = e.toString());
    }
  }

  void _startSimulation() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _addSimulatedMessage();
    });
    _viewerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _viewerCount = (_viewerCount + _random.nextInt(7) - 3).clamp(0, 99999);
      });
    });
  }

  void _addSimulatedMessage() {
    _addMessage(
      ChatMessage(
        username: _simulatedUsers[_random.nextInt(_simulatedUsers.length)],
        text: _simulatedMessages[_random.nextInt(_simulatedMessages.length)],
        color: _userColors[_random.nextInt(_userColors.length)],
      ),
    );
  }

  void _addMessage(ChatMessage msg) {
    setState(() {
      _messages.add(msg);
      if (_messages.length > 60) _messages.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _addMessage(
      ChatMessage(
        username: 'Vous',
        text: text,
        color: Colors.white,
        isOwn: true,
      ),
    );
    _inputController.clear();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _viewerTimer?.cancel();
    _cameraController?.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildChatArea(),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_isCameraReady && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: Center(
        child: _cameraError != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off,
                    color: Colors.white38,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cameraError!,
                    style: const TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.white30),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _LiveBadge(),
          const SizedBox(width: 8),
          _ViewerCount(count: _viewerCount),
          const Spacer(),
          const _StreamerAvatar(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _messages.length,
        itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Dites quelque chose...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.favorite,
            color: Colors.pinkAccent,
            onTap: () {},
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.send,
            color: Colors.cyanAccent,
            onTap: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerCount extends StatelessWidget {
  final int count;
  const _ViewerCount({required this.count});

  String _format(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.remove_red_eye, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            _format(count),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StreamerAvatar extends StatelessWidget {
  const _StreamerAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pinkAccent, width: 2),
      ),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFF0f3460),
        child: Text(
          'M',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: message.isOwn
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.zero,
        decoration: message.isOwn
            ? BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${message.username} ',
                style: TextStyle(
                  color: message.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: message.text,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
