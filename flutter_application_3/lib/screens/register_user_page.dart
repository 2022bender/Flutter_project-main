import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

// Pantalla para crear una cuenta nueva.
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// Estado y controladores del formulario de registro.
class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();

  final TextEditingController correoController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController tipoController = TextEditingController();

  final AuthService authService = AuthService();

  bool cargando = false;

  @override
  void dispose() {
    // Libera todos los controladores del formulario.
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    tipoController.dispose();

    super.dispose();
  }

  Future<void> registrarUsuario() async {
    // Valida y envía los datos para registrar el usuario.
    final mensaje = authService.validarRegistro(
      nombre: nombreController.text.trim(),
      correo: correoController.text.trim(),
      password: passwordController.text,
      confirmarpassword: passwordController.text,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
        ),
      );

      return;
    }

    final tipoUsuario = int.tryParse(tipoController.text.trim());
    if (tipoUsuario == null || (tipoUsuario != 1 && tipoUsuario != 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe 1 para Administrador o 2 para General'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await authService.registrarUsuario(
        nombre: nombreController.text,
        correo: correoController.text,
        password: passwordController.text,
        tipoUsuario: tipoUsuario,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cuenta creada correctamente. Ya puedes iniciar sesión.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construye los campos y el botón de registro.
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: AuthCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add,
                            size: 65,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'CREAR CUENTA',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08245C),
                            ),
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: nombreController,
                            label: 'Nombre completo',
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            controller: correoController,
                            label: 'Correo electrónico',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            controller: passwordController,
                            label: 'Contraseña',
                            prefixIcon: Icons.lock,
                            obscureText: true,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: tipoController,
                            label: 'Tipo (1=Administrador, 2=General)',
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.number,
                          ),
                          PrimaryButton(
                            text: cargando ? 'REGISTRANDO...' : 'REGISTRARME',
                            onPressed: cargando ? () {} : registrarUsuario,
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Ya tengo una cuenta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
