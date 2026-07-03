// 主题颜色令牌定义。集中管理应用主色、辅助色和状态色，避免页面内硬编码色值。

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4A8FE8);
  static const secondary = Color(0xFF3ECFB2);
  static const deepNavy = Color(0xFF1A3A5C);
  static const softBg = Color(0xFFF0F6FF);
  static const inputBg = Color(0xFFF5F9FF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F2540);
  static const textSecondary = Color(0xFF5A7A99);
  static const textHint = Color(0xFF9BB5CC);
  static const borderColor = Color(0x264A8FE8);
  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );
  
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6FD4), Color(0xFF1DB896)],
  );
}
