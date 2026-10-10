import 'package:flutter/material.dart';

import '../models/team_member.dart';

/// Circle with the member's initials in their colour.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 20});

  final TeamMember member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(member.colorValue),
      foregroundColor: Colors.white,
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
