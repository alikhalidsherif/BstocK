import 'package:flutter/material.dart';

class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
  });

  static const SemanticColors light = SemanticColors(
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF0EA5E9),
    danger: Color(0xFFEF4444),
  );

  static const SemanticColors dark = SemanticColors(
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    danger: Color(0xFFFF6B6B),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}

