import 'package:flutter/material.dart';

// Contenedor visual que agrupa los formularios de autenticación.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Aplica el estilo de tarjeta al contenido recibido.

    return Card(
      color: const Color.fromRGBO(20, 20, 20, 0.75),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: child,
        ),
      ),
    );
  }
}
