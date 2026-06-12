import 'package:flutter/material.dart';

/// Dégradé de fond commun à toutes les pages de l'app.
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
);

/// Couleur d'accent commune (CTA, icônes actives, ...).
const accentColor = Colors.cyanAccent;
