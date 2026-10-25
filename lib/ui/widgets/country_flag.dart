import 'package:flutter/material.dart';

class CountryFlag extends StatelessWidget {
  final String code;
  final double size;

  const CountryFlag({
    super.key,
    required this.code,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c = code.toLowerCase().trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161622),
        border: Border.all(
          color: const Color(0xFF2E2E42),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/flags/$c.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'https://flagcdn.com/w80/$c.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1B1B28),
                  child: Center(
                    child: Icon(
                      Icons.public_rounded,
                      size: size * 0.6,
                      color: const Color(0xFF8E8E9E),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
