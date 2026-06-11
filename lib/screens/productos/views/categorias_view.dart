import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/categoria.dart';
import '../../../providers/categoria_provider.dart';
import '../../../providers/auth_provider.dart';

class CategoriasView extends StatelessWidget {
  const CategoriasView({super.key});

  @override
  Widget build(BuildContext context) {
  final provider = context.watch<CategoriaProvider>();


    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Categorías',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioCategoria(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: provider.categorias.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final categoria = provider.categorias[index];

                        return ListTile(
                          title: Text(categoria.nombre),
                          subtitle: categoria.descripcion == null ||
                                  categoria.descripcion!.isEmpty
                              ? null
                              : Text(categoria.descripcion!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _mostrarFormularioCategoria(
                                  context,
                                  categoria: categoria,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmarEliminar(
                                  context,
                                  categoria,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCategoria(
    BuildContext context, {
    Categoria? categoria,
  }) {
    final nombreController = TextEditingController(
      text: categoria?.nombre ?? '',
    );

    final descripcionController = TextEditingController(
      text: categoria?.descripcion ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(categoria == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final descripcion = descripcionController.text.trim();

                if (nombre.isEmpty) return;

                final provider = context.read<CategoriaProvider>();
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

if (categoria == null) {
  await provider.crearCategoria(
    Categoria(
      nombre: nombre,
      descripcion: descripcion.isEmpty ? null : descripcion,
    ),
    usuarioId: usuarioId,
  );
} else {
  await provider.actualizarCategoria(
    categoria.copyWith(
      nombre: nombre,
      descripcion: descripcion.isEmpty ? null : descripcion,
    ),
    usuarioId: usuarioId,
  );
}

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminar(BuildContext context, Categoria categoria) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text('¿Seguro que quieres eliminar "${categoria.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
  final usuarioId =
      context.read<AuthProvider>().usuarioActual!.id!;

  await context.read<CategoriaProvider>().eliminarCategoria(
    categoria.id!,
    usuarioId: usuarioId,
  );

  if (context.mounted) Navigator.pop(context);
},
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}