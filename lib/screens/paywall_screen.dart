import 'package:flutter/material.dart';
import '../services/vip_service.dart';
import '../theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;

  Future<void> _activate() async {
    setState(() => _loading = true);
    await VipService.instance.upgrade();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.15),
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: const Icon(Icons.workspace_premium, color: accentColor, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Passer en VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Débloquez toutes les fonctionnalités',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
                ),
                const SizedBox(height: 36),
                _Feature(icon: Icons.groups_outlined, label: 'Jusqu\'à 100 000 spectateurs'),
                const SizedBox(height: 14),
                _Feature(
                  icon: Icons.verified_outlined,
                  label: 'Badge de vérification',
                  imageSuffix: Image.asset('assets/verified.png', width: 18, height: 18),
                ),
                const SizedBox(height: 14),
                _Feature(icon: Icons.sentiment_very_dissatisfied_outlined, label: 'Mode Hater'),
                const SizedBox(height: 14),
                _Feature(icon: Icons.chat_bubble_outline, label: 'Édition des commentaires'),
                const SizedBox(height: 14),
                _Feature(icon: Icons.card_giftcard_outlined, label: 'Dons des spectateurs'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _activate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Activer VIP'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Achat unique · Stocké localement sur cet appareil',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? imageSuffix;

  const _Feature({required this.icon, required this.label, this.imageSuffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 22),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        if (imageSuffix != null) ...[const SizedBox(width: 6), imageSuffix!],
      ],
    );
  }
}
