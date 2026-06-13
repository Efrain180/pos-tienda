import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/marca.dart';
import '../../../providers/marca_provider.dart';
import '../../../providers/auth_provider.dart';

class MarcasView extends StatelessWidget {
  const MarcasView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarcaProvider>();
    final marcas = provider.marcas;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sell_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Marcas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MarcaResumenCard(
                  label: 'Total',
                  value: marcas.length.toString(),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioMarca(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva marca'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : marcas.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay marcas registradas',
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
                                        child: Text(
                                          'Nombre de la marca',
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
                                    itemCount: marcas.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final marca = marcas[index];

                                      return Container(
                                        height: 54,
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
                                                Icons.sell_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                marca.nombre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Editar',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: () =>
                                                  _mostrarFormularioMarca(
                                                context,
                                                marca: marca,
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
                                                marca,
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

  void _mostrarFormularioMarca(BuildContext context, {Marca? marca}) {
    final nombreController = TextEditingController(
      text: marca?.nombre ?? '',
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
                  marca == null ? Icons.add : Icons.edit_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  marca == null ? 'Nueva marca' : 'Editar marca',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: nombreController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre de la marca',
                hintText: 'Ej. Coca-Cola, Truper, Marlboro...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) async {
                await _guardarMarca(
                  context,
                  dialogContext,
                  nombreController,
                  marca,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _guardarMarca(
                  context,
                  dialogContext,
                  nombreController,
                  marca,
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

  Future<void> _guardarMarca(
    BuildContext context,
    BuildContext dialogContext,
    TextEditingController nombreController,
    Marca? marca,
  ) async {
    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) return;

    final provider = context.read<MarcaProvider>();
    final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

    if (marca == null) {
      await provider.crearMarca(
        Marca(nombre: nombre),
        usuarioId: usuarioId,
      );
    } else {
      await provider.actualizarMarca(
        marca.copyWith(nombre: nombre),
        usuarioId: usuarioId,
      );
    }

    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  void _confirmarEliminar(BuildContext context, Marca marca) {
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
                  'Eliminar marca',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${marca.nombre}"?\n\n'
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

                await context.read<MarcaProvider>().eliminarMarca(
                      marca.id!,
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

class _MarcaResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _MarcaResumenCard({
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