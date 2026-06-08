import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/floating_heart.dart';
import '../widgets/live_ui.dart';

class _HeartData {
  final int id;
  final double xDrift;
  final String emoji;
  _HeartData(this.id, this.xDrift, this.emoji);
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  // Hearts
  final List<_HeartData> _hearts = [];
  int _nextHeartId = 0;
  bool _inBurst = false;

  // Simulation
  final _random = Random();
  Timer? _messageTimer;
  Timer? _viewerTimer;
  Timer? _heartTimer;
  Timer? _phaseTimer;
  int _viewerCount = 1247;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startSimulation();
  }

  // ── Camera ──

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

  // ── Simulation ──

  void _startSimulation() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final profile = profiles[_random.nextInt(profiles.length)];
      _addMessage(ChatMessage(
        username: profile.username,
        text: simulatedMessages[_random.nextInt(simulatedMessages.length)],
        color: profile.color,
        avatarIndex: profile.avatarIndex,
      ));
    });

    _viewerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _viewerCount = (_viewerCount + _random.nextInt(7) - 3).clamp(0, 99999);
      });
    });

    _enterQuiet();
  }

  void _enterQuiet() {
    _inBurst = false;
    _heartTimer?.cancel();
    final ms = 2000 + _random.nextInt(4000);
    _phaseTimer = Timer(Duration(milliseconds: ms), _enterBurst);
  }

  void _enterBurst() {
    _inBurst = true;
    final burstMs = 1500 + _random.nextInt(2500);
    _phaseTimer = Timer(Duration(milliseconds: burstMs), _enterQuiet);
    _scheduleNextHeart();
  }

  void _scheduleNextHeart() {
    if (!_inBurst) return;
    final heartsPerSecond = (_viewerCount / 400.0).clamp(1.0, 8.0);
    final baseMs = (1000.0 / heartsPerSecond).round();
    final jitter = (baseMs * 0.4 * _random.nextDouble()).toInt();
    final delayMs = (baseMs - jitter ~/ 2 + _random.nextInt(jitter + 1)).clamp(100, 1200);

    _heartTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_inBurst) return;
      _spawnHeart();
      if (heartsPerSecond > 3 && _random.nextDouble() > 0.55) {
        Timer(Duration(milliseconds: 100 + _random.nextInt(150)), () {
          if (_inBurst) _spawnHeart();
        });
      }
      _scheduleNextHeart();
    });
  }

  // ── Chat ──

  void _addMessage(ChatMessage msg) {
    _messages.insert(0, msg);
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));

    if (_messages.length > 60) {
      final removed = _messages.removeAt(60);
      _listKey.currentState?.removeItem(
        60,
        (_, animation) => _buildChatItem(removed, animation),
        duration: Duration.zero,
      );
    }
  }

  Widget _buildChatItem(ChatMessage message, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: curved,
      alignment: AlignmentDirectional(-1.0, 1.0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: ChatBubble(message: message),
      ),
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _addMessage(ChatMessage(
      username: 'Vous',
      text: text,
      color: Colors.white,
      isOwn: true,
    ));
    _inputController.clear();
  }

  // ── Hearts ──

  void _spawnHeart({String? emoji}) {
    setState(() {
      _hearts.add(_HeartData(
        _nextHeartId++,
        (_random.nextDouble() - 0.5) * 64,
        emoji ?? heartEmojis[_random.nextInt(heartEmojis.length)],
      ));
    });
  }

  void _removeHeart(int id) {
    if (mounted) setState(() => _hearts.removeWhere((h) => h.id == id));
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _viewerTimer?.cancel();
    _heartTimer?.cancel();
    _phaseTimer?.cancel();
    _cameraController?.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // ── Build ──

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
          _buildHeartsOverlay(),
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
                  const Icon(Icons.videocam_off, color: Colors.white38, size: 60),
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
          const LiveBadge(),
          const SizedBox(width: 8),
          ViewerCount(count: _viewerCount),
          const Spacer(),
          const StreamerAvatar(),
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
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0.0, 0.25],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: AnimatedList(
          key: _listKey,
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          initialItemCount: _messages.length,
          itemBuilder: (_, i, animation) => _buildChatItem(_messages[i], animation),
        ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ActionButton(
            icon: Icons.send,
            color: Colors.cyanAccent,
            onTap: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildHeartsOverlay() {
    return Positioned(
      right: 12,
      bottom: 80,
      child: SizedBox(
        width: 80,
        height: 320,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: _hearts
              .map((h) => FloatingHeart(
                    key: ValueKey(h.id),
                    emoji: h.emoji,
                    xDrift: h.xDrift,
                    onComplete: () => _removeHeart(h.id),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
