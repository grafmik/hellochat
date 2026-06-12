import 'package:flutter/material.dart';
import '../theme.dart';
import 'live_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildLogo(),
                const Spacer(),
                _MenuItem(icon: Icons.storefront_outlined, label: 'Boutique'),
                const SizedBox(height: 12),
                _MenuItem(icon: Icons.school_outlined, label: 'Tutoriel'),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.groups_outlined,
                  label: 'Rejoindre la communauté HelloChat',
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                ),
                const SizedBox(height: 32),
                _buildStartButton(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, Colors.purpleAccent],
            ),
          ),
          child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        const Text(
          'HelloChat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LIVE SIMULATOR',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LiveSetupScreen()),
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

/// Élément de menu non interactif pour l'instant : la navigation associée
/// (boutique, tutoriel, ...) sera ajoutée sur une page dédiée par la suite.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
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
    );
  }
}
