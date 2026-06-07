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

// ─── Models ───────────────────────────────────────────────────────────────────

class ChatMessage {
  final String username;
  final String text;
  final Color color;
  final bool isOwn;
  final int? avatarIndex; // null = initiale, 0-255 = cellule de avatar_grid.png

  const ChatMessage({
    required this.username,
    required this.text,
    required this.color,
    this.isOwn = false,
    this.avatarIndex,
  });
}

class _HeartData {
  final int id;
  final double xDrift;
  final String emoji;
  _HeartData(this.id, this.xDrift, this.emoji);
}

// ─── Live Screen ──────────────────────────────────────────────────────────────

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

  // Hearts
  final List<_HeartData> _hearts = [];
  int _nextHeartId = 0;
  bool _inBurst = false;

  // Simulation
  final _random = Random();
  Timer? _messageTimer;
  Timer? _viewerTimer;
  Timer? _heartTimer; // spawn individuel pendant un burst
  Timer? _phaseTimer; // transitions quiet ↔ burst
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

  static const _heartEmojis = ['❤️', '🧡', '💛', '💖', '💗', '💜', '🤍'];

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
      final hasAvatar = _random.nextDouble() > 0.35;
      _addMessage(
        ChatMessage(
          username: _simulatedUsers[_random.nextInt(_simulatedUsers.length)],
          text: _simulatedMessages[_random.nextInt(_simulatedMessages.length)],
          color: _userColors[_random.nextInt(_userColors.length)],
          avatarIndex: hasAvatar ? _random.nextInt(256) : null,
        ),
      );
    });

    _viewerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _viewerCount = (_viewerCount + _random.nextInt(7) - 3).clamp(0, 99999);
      });
    });

    _enterQuiet();
  }

  // ── Phase quiet : silence, puis on déclenche un burst ──

  void _enterQuiet() {
    _inBurst = false;
    _heartTimer?.cancel();
    // Silence de 2 à 6 secondes
    final ms = 2000 + _random.nextInt(4000);
    _phaseTimer = Timer(Duration(milliseconds: ms), _enterBurst);
  }

  // ── Phase burst : rafale de cœurs, puis retour quiet ──

  void _enterBurst() {
    _inBurst = true;
    // Durée du burst : 1.5 à 4 secondes
    final burstMs = 1500 + _random.nextInt(2500);
    _phaseTimer = Timer(Duration(milliseconds: burstMs), _enterQuiet);
    _scheduleNextHeart();
  }

  // ── Spawn récursif pendant un burst ──

  void _scheduleNextHeart() {
    if (!_inBurst) return;
    // Fréquence proportionnelle aux viewers : 400 viewers ≈ 1 cœur/sec, max 8/sec
    final heartsPerSecond = (_viewerCount / 400.0).clamp(1.0, 8.0);
    final baseMs = (1000.0 / heartsPerSecond).round();
    // Jitter ±40% pour un rythme organique
    final jitter = (baseMs * 0.4 * _random.nextDouble()).toInt();
    final delayMs = (baseMs - jitter ~/ 2 + _random.nextInt(jitter + 1)).clamp(
      100,
      1200,
    );

    _heartTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_inBurst) return;
      _spawnHeart();
      // Au-delà de 3/sec, rafale de 2 cœurs proches
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

  // ── Hearts ──

  void _spawnHeart({String? emoji}) {
    setState(() {
      _hearts.add(
        _HeartData(
          _nextHeartId++,
          (_random.nextDouble() - 0.5) * 64,
          emoji ?? _heartEmojis[_random.nextInt(_heartEmojis.length)],
        ),
      );
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
              .map(
                (h) => _FloatingHeart(
                  key: ValueKey(h.id),
                  emoji: h.emoji,
                  xDrift: h.xDrift,
                  onComplete: () => _removeHeart(h.id),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─── Floating Heart ───────────────────────────────────────────────────────────

class _FloatingHeart extends StatefulWidget {
  final String emoji;
  final double xDrift;
  final VoidCallback onComplete;

  const _FloatingHeart({
    super.key,
    required this.emoji,
    required this.xDrift,
    required this.onComplete,
  });

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward().whenComplete(widget.onComplete);

    _y = Tween<double>(
      begin: 0,
      end: -240,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.translate(
        offset: Offset(widget.xDrift * _ctrl.value, _y.value),
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 30)),
          ),
        ),
      ),
    );
  }
}

// ─── UI Components ────────────────────────────────────────────────────────────

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
          'S',
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.username,
                  style: TextStyle(
                    color: message.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.avatarIndex != null) {
      return _GridAvatar(index: message.avatarIndex!);
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.color.withValues(alpha: 0.25),
      child: Text(
        message.username[0].toUpperCase(),
        style: TextStyle(
          color: message.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Affiche une cellule de la grille avatar_grid.png (16×16 cellules de 128px)
class _GridAvatar extends StatelessWidget {
  final int index; // 0–255
  static const double size = 32;

  const _GridAvatar({required this.index});

  @override
  Widget build(BuildContext context) {
    final row = index ~/ 16;
    final col = index % 16;
    final totalSize = size * 16; // image entière à cette échelle

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          maxWidth: totalSize,
          maxHeight: totalSize,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(-col * size, -row * size),
            child: Image.asset(
              'assets/avatar_grid.png',
              width: totalSize,
              height: totalSize,
              filterQuality: FilterQuality.medium,
            ),
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
