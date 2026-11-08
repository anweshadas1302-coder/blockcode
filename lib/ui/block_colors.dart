import 'package:flutter/material.dart';

// Backgrounds
const bgDeep = Color(0xFF0A0E1F);
const bgPanel = Color(0xFF121933);
const bgCard = Color(0xFF1A2342);
const inkDark = Color(0xFF06101F);

// Neon accents
const neonCyan = Color(0xFF22E5FF);
const neonPink = Color(0xFFFF3DCB);
const neonLime = Color(0xFFB6FF3B);
const neonAmber = Color(0xFFFFC53D);
const neonViolet = Color(0xFF9B5CFF);

// Block categories
const motionColor = Color(0xFF1F8BFF);
const looksColor = Color(0xFF9B5CFF);
const controlColor = Color(0xFFFF7A1A);
const dataColor = Color(0xFF17B978);

/// Diagonal gradient used for blocks and buttons.
LinearGradient neonGradient(Color c) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.lerp(c, Colors.white, 0.18)!,
    Color.lerp(c, Colors.black, 0.25)!,
  ],
);

/// Soft colored glow behind a widget.
List<BoxShadow> neonGlow(Color c, {double strength = 0.45}) => [
  BoxShadow(
    color: c.withValues(alpha: strength),
    blurRadius: 14,
    spreadRadius: 0.5,
  ),
];
