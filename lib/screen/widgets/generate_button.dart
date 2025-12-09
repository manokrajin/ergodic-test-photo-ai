import 'package:flutter/material.dart';

/// Premium generate button with loading state and AI working indicator
class GenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const GenerateButton({super.key, required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildButton(),
        if (isLoading) ...[
          const SizedBox(height: 16),
          const AIWorkingIndicator(),
        ],
      ],
    );
  }

  Widget _buildButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 64,
          decoration: _buildDecoration(),
          child: Center(
            child: isLoading ? _buildLoadingIndicator() : _buildButtonContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: isLoading
          ? const LinearGradient(colors: [Color(0xFFD1D1D6), Color(0xFFAEAEB2)])
          : const LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: isLoading
          ? []
          : [
              BoxShadow(
                color: const Color(0xFF007AFF).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildButtonContent() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Text(
          'Transform Now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// AI working indicator shown during generation
class AIWorkingIndicator extends StatelessWidget {
  const AIWorkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [_buildIcon(), const SizedBox(width: 16), _buildText()],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildText() {
    return const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI is working...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Creating cinematic magic',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
