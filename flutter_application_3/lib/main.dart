import 'package:flutter/material.dart';
import 'screens/add_blog_page.dart';
import 'screens/blog_page.dart';
import 'screens/login_user_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/users_page.dart';

void main() {
  // Punto de entrada de la aplicación Flutter.
  runApp(const LoginApp());
}

// Configura el tema, las rutas y la pantalla inicial de la aplicación.
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp centraliza la navegación entre las pantallas.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplicación móvil con FastAPI',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/users': (context) => const UsersPage(),
        '/blog': (context) => const BlogPage(),
        '/add-blog': (context) => const AddBlogPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
