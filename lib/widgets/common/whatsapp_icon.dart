import 'package:flutter/material.dart';

class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/whatsapp.png',
      width: size,
      height: size,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Si no encuentra la imagen, usa un icono alternativo
        return Icon(Icons.chat_bubble, size: size, color: color);
      },
    );
  }
}
