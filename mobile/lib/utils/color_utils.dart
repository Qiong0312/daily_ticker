import 'package:flutter/material.dart';

Color parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

Color missionTint(String hex, int amount) {
  final color = parseHexColor(hex);
  return Color.lerp(Colors.white, color, amount / 100)!;
}
