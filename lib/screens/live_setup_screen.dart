import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../services/vip_service.dart';
import '../theme.dart';
import 'edit_comments_screen.dart';
import 'live_stream_screen.dart';
import 'paywall_screen.dart';

class LiveSetupScreen extends StatefulWidget {
  const LiveSetupScreen({super.key});

  @override
  State<LiveSetupScreen> createState() => _LiveSetupScreenState();
}

enum _AvatarAction { camera, gallery, remove }

class _LiveSetupScreenState extends State<LiveSetupScreen> {
  bool _showProfile = true;
  bool _showVerification = false;
  bool _record = false;
  bool _haterMode = false;
  bool _audienceDonations = false;
  double _viewerTarget = 50;
  final _pseudoController = TextEditingController();
  Uint8List? _avatarBytes;

  AccountType get _accountType =>
      VipService.instance.isVip ? AccountType.vip : AccountType.standard;

  @override
  void initState() {
    super.initState();
    VipService.instance.addListener(_onVipChanged);
  }

  @override
  void dispose() {
    VipService.instance.removeListener(_onVipChanged);
    _pseudoController.dispose();
    super.dispose();
  }

  void _onVipChanged() => setState(() {});

  void _openPaywall() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );

  Future<void> _pickAvatar() async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: accentColor),
              title: const Text('Prendre une photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(_AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: accentColor),
              title: const Text('Choisir dans la galerie', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop(_AvatarAction.gallery),
            ),
            if (_avatarBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;

    if (action == _AvatarAction.remove) {
      setState(() => _avatarBytes = null);
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: action == _AvatarAction.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isVip = VipService.instance.isVip;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Retour',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _ToggleItem(
                        icon: Icons.person_outline,
                        label: 'Afficher le profil',
                        value: _showProfile,
                        onChanged: (v) => setState(() => _showProfile = v),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        sizeCurve: Curves.easeInOut,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildProfileEditor(),
                          ],
                        ),
                        crossFadeState: _showProfile
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.verified_outlined,
                        label: 'Vérifié',
                        labelSuffix: Image.asset('assets/verified.png', width: 18, height: 18),
                        value: _showVerification,
                        onChanged: (v) => setState(() => _showVerification = v),
                        locked: !isVip,
                        onLockedTap: _openPaywall,
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.videocam_outlined,
                        label: 'Enregistrer',
                        value: _record,
                        onChanged: (v) => setState(() => _record = v),
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.sentiment_very_dissatisfied_outlined,
                        label: 'Mode Hater',
                        value: _haterMode,
                        onChanged: (v) => setState(() => _haterMode = v),
                        locked: !isVip,
                        onLockedTap: _openPaywall,
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Dons des spectateurs',
                        value: _audienceDonations,
                        onChanged: (v) => setState(() => _audienceDonations = v),
                        locked: !isVip,
                        onLockedTap: _openPaywall,
                      ),
                      const SizedBox(height: 12),
                      _NavigationItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Éditer les commentaires',
                        locked: !isVip,
                        onTap: isVip
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const EditCommentsScreen()),
                                )
                            : _openPaywall,
                      ),
                      const SizedBox(height: 12),
                      _buildViewersSlider(),
                      if (!isVip) ...[
                        const SizedBox(height: 12),
                        _buildLockedItem(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStartButton(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileEditor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white12,
                  backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                  child: _avatarBytes == null
                      ? const Icon(Icons.person, color: Colors.white38, size: 32)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _pseudoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Votre pseudo',
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
        ],
      ),
    );
  }

  Widget _buildViewersSlider() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: accentColor, size: 22),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Nombre de spectateurs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 2),
            child: Text(
              '${_viewerTarget.round()} (0 - ${_accountType.maxViewers})',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ),
          Slider(
            value: _viewerTarget.clamp(0, _accountType.maxViewers.toDouble()),
            min: 0,
            max: _accountType.maxViewers.toDouble(),
            activeColor: accentColor,
            inactiveColor: Colors.white24,
            onChanged: (v) => setState(() => _viewerTarget = v),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Utilise les boutons de volume pour contrôler manuellement le nombre de spectateurs.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedItem() {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openPaywall,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: accentColor, size: 22),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '100 000 spectateurs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) {
              final pseudo = _pseudoController.text.trim();
              return LiveStreamScreen(
                record: _record,
                initialViewerCount: _viewerTarget.round(),
                accountType: _accountType,
                pseudo: _showProfile && pseudo.isNotEmpty ? pseudo : 'Vous',
                avatarBytes: _showProfile ? _avatarBytes : null,
                showVerification: _showVerification,
              );
            },
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: const Text('Démarrer le Live'),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? labelSuffix;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;
  final VoidCallback? onLockedTap;

  const _ToggleItem({
    required this.icon,
    required this.label,
    this.labelSuffix,
    required this.value,
    required this.onChanged,
    this.locked = false,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked ? onLockedTap : () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (labelSuffix != null) ...[
                      const SizedBox(width: 6),
                      labelSuffix!,
                    ],
                  ],
                ),
              ),
              AbsorbPointer(
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool locked;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: locked ? 0.03 : 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
