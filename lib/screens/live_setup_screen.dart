import 'package:flutter/material.dart';
import '../theme.dart';
import 'edit_comments_screen.dart';
import 'live_stream_screen.dart';

class LiveSetupScreen extends StatefulWidget {
  const LiveSetupScreen({super.key});

  @override
  State<LiveSetupScreen> createState() => _LiveSetupScreenState();
}

class _LiveSetupScreenState extends State<LiveSetupScreen> {
  bool _showProfile = true;
  bool _showVerification = false;
  bool _record = false;
  bool _haterMode = false;
  bool _audienceDonations = false;
  double _viewerTarget = 50;
  final _pseudoController = TextEditingController();

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        'Comment jouer',
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
                        label: 'Afficher la vérification',
                        value: _showVerification,
                        onChanged: (v) => setState(() => _showVerification = v),
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.videocam_outlined,
                        label: 'Enregistrer',
                        subtitle: "(l'IA ne fonctionnera pas pendant l'enregistrement)",
                        value: _record,
                        onChanged: (v) => setState(() => _record = v),
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.sentiment_very_dissatisfied_outlined,
                        label: 'Mode Hater',
                        value: _haterMode,
                        onChanged: (v) => setState(() => _haterMode = v),
                      ),
                      const SizedBox(height: 12),
                      _ToggleItem(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Dons des spectateurs',
                        value: _audienceDonations,
                        onChanged: (v) => setState(() => _audienceDonations = v),
                      ),
                      const SizedBox(height: 12),
                      _NavigationItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Éditer les commentaires',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditCommentsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildViewersSlider(),
                      const SizedBox(height: 12),
                      _buildLockedItem(),
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
          Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, color: Colors.white38, size: 32),
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
                  'Spectateurs cible',
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
              '${_viewerTarget.round()} (0 - 150)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ),
          Slider(
            value: _viewerTarget,
            min: 0,
            max: 150,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.3), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Débloquer 100 000 spectateurs',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LiveStreamScreen()),
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
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Switch(value: value, onChanged: onChanged, activeThumbColor: accentColor),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 38, bottom: 10),
              child: Text(
                subtitle!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
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
