import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';

// Tarjeta resumida de una publicación dentro de la lista del blog.
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Construye la tarjeta y permite abrir el detalle al tocarla.
    return Card(
      color: const Color.fromARGB(188, 66, 63, 59),
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imagen.isNotEmpty)
              Image.network(
                ApiConfig.resolveImageUri(post.imagen).toString(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 110,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, size: 40),
                        SizedBox(height: 4),
                        Text('No se pudo cargar la imagen'),
                      ],
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.tags.isNotEmpty) ...[
                    Text(
                      post.tags,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 146, 145, 145),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    post.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Leer publicación',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
