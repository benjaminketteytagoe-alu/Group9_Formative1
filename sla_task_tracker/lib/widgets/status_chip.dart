import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../utils/sla_colors.dart';

/// A small coloured pill showing an SLA status, e.g. "At Risk".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}