import 'package:flutter/material.dart';

// Fondo visual reutilizable para las pantallas de autenticación.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Coloca la imagen y el contenido de autenticación en pantalla.

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/wallpapers/login2.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
