import 'package:flutter/material.dart';

// Menú lateral para usuarios normales.
class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const UserDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? '';
  String get correo => usuario['mail']?.toString() ?? '';

  void _navegar(BuildContext context, String ruta) {
    // Cierra el menú y navega a la sección seleccionada.
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    Navigator.pushReplacementNamed(
      context,
      ruta,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Presenta los datos del usuario y sus opciones de navegación.
    return Drawer(
      backgroundColor: const Color.fromARGB(220, 220, 212, 226),
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration:
                  const BoxDecoration(color: Color.fromARGB(255, 44, 45, 46)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person,
                    color: Color.fromARGB(255, 0, 5, 14), size: 34),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            ),
            _opcion(context, Icons.post_add, 'Agregar blog', '/add-blog'),
            _opcion(context, Icons.account_circle_outlined, 'Mi perfil',
                '/profile'),
            _opcion(context, Icons.article_outlined, 'Blog', '/blog'),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final seleccionado = ruta == rutaActual;
    return ListTile(
      leading: Icon(icono,
          color: seleccionado ? const Color.fromARGB(255, 0, 0, 0) : null),
      title: Text(
        titulo,
        style: TextStyle(
          color: seleccionado ? const Color.fromARGB(255, 236, 106, 0) : null,
        ),
      ),
      selected: seleccionado,
      onTap: () => _navegar(context, ruta),
    );
  }
}
