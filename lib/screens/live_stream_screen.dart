import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:gal/gal.dart';
import '../models.dart';
import '../theme.dart';
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
  final bool record;
  final int initialViewerCount;
  final AccountType accountType;
  final String pseudo;
  final Uint8List? avatarBytes;
  final bool showVerification;

  const LiveStreamScreen({
    super.key,
    this.record = false,
    this.initialViewerCount = 1247,
    this.accountType = AccountType.standard,
    this.pseudo = 'Vous',
    this.avatarBytes,
    this.showVerification = false,
  });

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
  Timer? _smoothTimer;
  late int _targetViewerCount;
  late double _displayViewerCount;
  double _animBase = 0;
  int _animBaseMs = 0;
  int _animDeadlineMs = 0;

  // Boutons de volume
  static const double _midVolume = 0.5;

  int get _viewerStep => (_targetViewerCount * 0.1).round().clamp(1, 10000);
  double? _originalVolume;
  bool _ignoreVolumeChange = false;
  Timer? _volumeResetTimer;

  @override
  void initState() {
    super.initState();
    _targetViewerCount = widget.initialViewerCount.clamp(
      0,
      widget.accountType.maxViewers,
    );
    _displayViewerCount = _targetViewerCount.toDouble();
    _initCamera();
    _startSimulation();
    _initVolumeButtons();
    _startSmoothTimer();
  }

  void _startSmoothTimer() {
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= _animDeadlineMs) {
        // Pas d'animation active — fluctuations simulation en direct
        if (_displayViewerCount != _targetViewerCount.toDouble()) {
          setState(() => _displayViewerCount = _targetViewerCount.toDouble());
        }
        return;
      }
      final total = (_animDeadlineMs - _animBaseMs).toDouble();
      final elapsed = (now - _animBaseMs).toDouble();
      final t = (elapsed / total).clamp(0.0, 1.0);
      setState(() => _displayViewerCount = _animBase + (_targetViewerCount - _animBase) * t);
    });
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
        enableAudio: widget.record,
      );
      await controller.initialize();
      if (widget.record) {
        await controller.startVideoRecording();
      }
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

  Future<void> _stopRecordingAndSave() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;
    try {
      final file = await controller.stopVideoRecording();
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        await file.saveTo(file.name);
      } else {
        await Gal.putVideo(file.path, album: 'HelloChat Live');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vidéo enregistrée dans la galerie')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
        );
      }
    }
  }

  // ── Boutons de volume ──

  Future<void> _initVolumeButtons() async {
    if (kIsWeb) return;
    try {
      _originalVolume = await FlutterVolumeController.getVolume();
      await FlutterVolumeController.updateShowSystemUI(false);
      await FlutterVolumeController.setVolume(_midVolume);
      FlutterVolumeController.addListener(_onVolumeChanged, emitOnStart: false);
    } catch (_) {
      // Plateforme non supportée : on ignore, le slider reste utilisable.
    }
  }

  void _onVolumeChanged(double volume) {
    if (_ignoreVolumeChange) return;
    final delta = volume - _midVolume;
    if (delta.abs() < 0.01) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _animBase = _displayViewerCount;
    _animBaseMs = now;
    _animDeadlineMs = max(_animDeadlineMs, now) + 1000;
    _targetViewerCount =
        (_targetViewerCount + (delta > 0 ? _viewerStep : -_viewerStep)).clamp(
          0,
          widget.accountType.maxViewers,
        );

    // Remettre le volume au milieu déclenche lui-même un événement (souvent
    // de l'autre côté du point médian à cause des paliers de volume), qu'on
    // ignore pendant une courte fenêtre pour éviter un double comptage.
    _ignoreVolumeChange = true;
    FlutterVolumeController.setVolume(_midVolume);
    _volumeResetTimer?.cancel();
    _volumeResetTimer = Timer(const Duration(milliseconds: 300), () {
      _ignoreVolumeChange = false;
    });
  }

  void _disposeVolumeButtons() {
    if (kIsWeb) return;
    _volumeResetTimer?.cancel();
    FlutterVolumeController.removeListener();
    if (_originalVolume != null) {
      FlutterVolumeController.setVolume(_originalVolume!);
    }
    FlutterVolumeController.updateShowSystemUI(true);
  }

  // ── Simulation ──

  void _startSimulation() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final profile = profiles[_random.nextInt(profiles.length)];
      _addMessage(
        ChatMessage(
          username: profile.username,
          text: simulatedMessages[_random.nextInt(simulatedMessages.length)],
          color: profile.color,
          avatarIndex: profile.avatarIndex,
        ),
      );
    });

    _viewerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _targetViewerCount = (_targetViewerCount + _random.nextInt(7) - 3).clamp(
        0,
        widget.accountType.maxViewers,
      );
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
    final heartsPerSecond = (_targetViewerCount / 400.0).clamp(1.0, 8.0);
    final baseMs = (1000.0 / heartsPerSecond).round();
    final jitter = (baseMs * 0.4 * _random.nextDouble()).toInt();
    final delayMs = (baseMs - jitter ~/ 2 + _random.nextInt(jitter + 1)).clamp(
      100,
      1200,
    );

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
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 300),
    );

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
    _addMessage(
      ChatMessage(
        username: widget.pseudo,
        text: text,
        color: Colors.white,
        isOwn: true,
        avatarBytes: widget.avatarBytes,
      ),
    );
    _inputController.clear();
  }

  // ── Hearts ──

  void _spawnHeart({String? emoji}) {
    if (!mounted) return;
    setState(() {
      _hearts.add(
        _HeartData(
          _nextHeartId++,
          (_random.nextDouble() - 0.5) * 64,
          emoji ?? heartEmojis[_random.nextInt(heartEmojis.length)],
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
    _smoothTimer?.cancel();
    _cameraController?.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _disposeVolumeButtons();
    super.dispose();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isRecording = _cameraController?.value.isRecordingVideo ?? false;
    return PopScope(
      canPop: !isRecording,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _stopRecordingAndSave();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildBackground() {
    if (_isCameraReady && _cameraController != null) {
      // Sur mobile, CameraPreview applique une rotation interne (capteur en
      // mode paysage affiché en portrait) sans ajuster `aspectRatio`, qui
      // reste donc dans l'orientation paysage : on l'inverse pour obtenir le
      // ratio réellement affiché. Sur web, aucune rotation n'est appliquée.
      final cameraAspectRatio = kIsWeb
          ? _cameraController!.value.aspectRatio
          : 1 / _cameraController!.value.aspectRatio;
      return SizedBox.expand(
        child: Center(
          child: AspectRatio(
            aspectRatio: cameraAspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(gradient: appBackgroundGradient),
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
          const LiveBadge(),
          const SizedBox(width: 8),
          ViewerCount(count: _displayViewerCount.round()),
          const Spacer(),
          StreamerAvatar(
            pseudo: widget.pseudo,
            avatarBytes: widget.avatarBytes,
          ),
          if (widget.showVerification) ...[
            const SizedBox(width: 4),
            Image.asset('assets/verified.png', width: 22, height: 22),
          ],
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
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
          itemBuilder: (_, i, animation) =>
              _buildChatItem(_messages[i], animation),
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
          ActionButton(
            icon: Icons.send,
            color: accentColor,
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
                (h) => FloatingHeart(
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
