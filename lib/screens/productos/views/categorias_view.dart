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
    final categorias = provider.categorias;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CategoriaResumenCard(
                  label: 'Total',
                  value: categorias.length.toString(),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioCategoria(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva categoría'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : categorias.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay categorías registradas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF2F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Categoría',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Descripción',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 96),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: categorias.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final categoria = categorias[index];
                                      final descripcion =
                                          categoria.descripcion?.trim();

                                      return Container(
                                        height: 58,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index.isEven
                                              ? Colors.white
                                              : const Color(0xFFFAFBFC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                Colors.grey.withOpacity(0.10),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 17,
                                              backgroundColor:
                                                  Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.10),
                                              child: Icon(
                                                Icons.category_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                categoria.nombre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                descripcion == null ||
                                                        descripcion.isEmpty
                                                    ? 'Sin descripción'
                                                    : descripcion,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: descripcion == null ||
                                                          descripcion.isEmpty
                                                      ? Colors.grey
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Editar',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: () =>
                                                  _mostrarFormularioCategoria(
                                                context,
                                                categoria: categoria,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Eliminar',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              color: Colors.red,
                                              onPressed: () =>
                                                  _confirmarEliminar(
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
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.12),
                child: Icon(
                  categoria == null ? Icons.add : Icons.edit_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  categoria == null ? 'Nueva categoría' : 'Editar categoría',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    hintText: 'Ej. Refrescos, Ferretería, Cigarros...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) async {
                    await _guardarCategoria(
                      context,
                      dialogContext,
                      nombreController,
                      descripcionController,
                      categoria,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Opcional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _guardarCategoria(
                  context,
                  dialogContext,
                  nombreController,
                  descripcionController,
                  categoria,
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarCategoria(
    BuildContext context,
    BuildContext dialogContext,
    TextEditingController nombreController,
    TextEditingController descripcionController,
    Categoria? categoria,
  ) async {
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

    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  void _confirmarEliminar(BuildContext context, Categoria categoria) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eliminar categoría',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${categoria.nombre}"?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                final usuarioId =
                    context.read<AuthProvider>().usuarioActual!.id!;

                await context.read<CategoriaProvider>().eliminarCategoria(
                      categoria.id!,
                      usuarioId: usuarioId,
                    );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoriaResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _CategoriaResumenCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}