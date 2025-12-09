import 'package:flutter/material.dart';

/// Premium app bar with gradient icon and branding
class RemixAppBar extends StatelessWidget {
  final AnimationController fadeController;

  const RemixAppBar({super.key, required this.fadeController});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          children: [
            Row(
              children: [
                Hero(tag: 'app_icon', child: _buildAppIcon()),
                const SizedBox(width: 16),
                const Expanded(child: _AppTitle()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remix Studio',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: Color(0xFF000000),
            height: 1.1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'AI-Powered Photo Magic',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
