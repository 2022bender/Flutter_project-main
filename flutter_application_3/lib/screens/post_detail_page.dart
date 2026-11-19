import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/comentario_service.dart';

// Pantalla que muestra una publicación completa y permite agregar comentarios.
class PostDetailPage extends StatefulWidget {
  // Publicación que se recibió desde la lista del blog.
  final PostModel post;

  // Datos del usuario que inició sesión, necesarios para guardar comentarios.
  final Map<String, dynamic> usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.usuario,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

// Estado de la pantalla de detalle.
class _PostDetailPageState extends State<PostDetailPage> {
  // Controla el texto escrito por el usuario en el campo de comentario.
  final _comentarioController = TextEditingController();

  // Servicio encargado de consultar y registrar comentarios en la API.
  final _comentarioService = ComentarioService();

  // Future que contiene los comentarios de la publicación actual.
  late Future<List<ComentarioModel>> _comentarios;

  // Evita enviar más de un comentario al mismo tiempo.
  bool _enviando = false;

  @override
  void initState() {
    super.initState();

    // Carga los comentarios asociados al ID de la publicación.
    _comentarios = _comentarioService.obtenerComentarios(widget.post.id);
  }

  @override
  void dispose() {
    // Libera el controlador cuando la pantalla deja de existir.
    _comentarioController.dispose();
    super.dispose();
  }

  // Valida y envía el comentario del usuario a la API.
  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();

    // Se acepta el identificador con cualquiera de los nombres usados por la app.
    final identificador = widget.usuario['id_usr'] ?? widget.usuario['id'];
    final usuarioId = identificador is num
        ? identificador.toInt()
        : int.tryParse(identificador?.toString() ?? '');

    // No permite enviar comentarios vacíos.
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario')),
      );
      return;
    }

    // Sin usuario identificado no se puede asociar el comentario.
    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario')),
      );
      return;
    }

    // Deshabilita el botón mientras se realiza la petición.
    setState(() => _enviando = true);

    try {
      // Construye el comentario con el usuario y la publicación actuales.
      await _comentarioService.agregarComentario(
        ComentarioModel(
          id: 0,
          comentario: texto,
          fecha: '',
          estatus: 1,
          usuarioId: usuarioId,
          blogId: widget.post.id,
        ),
      );

      if (!mounted) return;

      // Limpia el campo y vuelve a consultar los comentarios actualizados.
      _comentarioController.clear();
      setState(() {
        _comentarios = _comentarioService.obtenerComentarios(widget.post.id);
      });
    } catch (error) {
      if (!mounted) return;

      // Muestra el error devuelto por la API o por la conexión.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el comentario: $error')),
      );
    } finally {
      // Reactiva el botón aunque la petición falle.
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    // Estructura visual de la pantalla de detalle.
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de publicación')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Muestra la imagen solo si la publicación tiene una URL guardada.
              if (post.imagen.isNotEmpty)
                Image.network(
                  // Convierte la ruta o enlace guardado en la BD a una URL utilizable.
                  ApiConfig.resolveImageUri(post.imagen).toString(),
                  // Define la altura máxima de la imagen en el detalle.
                  height: 230,
                  // Ocupa todo el ancho disponible de la pantalla.
                  width: double.infinity,
                  // Recorta la imagen para cubrir el espacio sin deformarla.
                  fit: BoxFit.cover,
                  // Widget alternativo si la imagen no puede descargarse.
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 230,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Text('No se pudo cargar la imagen'),
                  ),
                ),
              // Espacio entre la imagen y el resto del contenido.
              const SizedBox(height: 16),
              // Muestra las etiquetas únicamente si existen.
              if (post.tags.isNotEmpty) Text(post.tags),
              // Muestra el título principal de la publicación.
              Text(
                post.titulo,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Espacio entre el título y la descripción.
              const SizedBox(height: 12),
              // Muestra el contenido completo de la publicación.
              Text(post.descripcion),
              // Separa la publicación de la sección de comentarios.
              const SizedBox(height: 24),
              // Encabezado de la sección de comentarios.
              const Text(
                'Comentarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // FutureBuilder actualiza la interfaz según el estado de la consulta.
              FutureBuilder<List<ComentarioModel>>(
                // Future que contiene los comentarios de esta publicación.
                future: _comentarios,
                // Builder que reconstruye la sección cuando cambia el estado.
                builder: (context, snapshot) {
                  // Mientras se consultan los comentarios, muestra un indicador.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Informa si la API no pudo devolver los comentarios.
                  if (snapshot.hasError) {
                    return Text(
                        'Error al cargar comentarios: ${snapshot.error}');
                  }

                  final comentarios = snapshot.data ?? [];

                  // Mensaje para publicaciones que todavía no tienen comentarios.
                  if (comentarios.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Todavía no hay comentarios.'),
                    );
                  }

                  // Genera una fila visual por cada comentario recibido.
                  return Column(
                    // Convierte cada comentario en un ListTile.
                    children: comentarios
                        .map(
                          (comentario) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.comment),
                            title: Text(comentario.comentario),
                            subtitle: Text(comentario.fecha),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              // Campo donde el usuario escribe un nuevo comentario.
              TextField(
                controller: _comentarioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Escribe un comentario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Botón que envía el comentario y muestra el estado de carga.
              ElevatedButton(
                onPressed: _enviando ? null : _enviarComentario,
                child: Text(_enviando ? 'Enviando...' : 'Comentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
