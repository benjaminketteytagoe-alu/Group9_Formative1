import 'package:flutter/material.dart';

import '../models/enums.dart';

/// One place for the SLA colours, so every screen matches.
extension SlaStatusColors on SlaStatus {
  Color get color {
    switch (this) {
      case SlaStatus.onTrack:
        return const Color(0xFF2E7D32); // green
      case SlaStatus.atRisk:
        return const Color(0xFFF57F17); // amber
      case SlaStatus.overdue:
        return const Color(0xFFC62828); // red
      case SlaStatus.completed:
        return const Color(0xFF607D8B); // grey
    }
  }

  /// A soft version of the colour, used behind chip text.
  Color get background => color.withValues(alpha: 0.12);
}