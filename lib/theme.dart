import 'package:flutter/material.dart';

/// Dégradé de fond commun à toutes les pages de l'app.
const appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A0828), Color(0xFF2C1054), Color(0xFF190A3A)],
);

/// Couleur d'accent commune (CTA, icônes actives, ...).
const accentColor = Color(0xFFF77737);
