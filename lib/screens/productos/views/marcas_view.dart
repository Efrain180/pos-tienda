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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Marcas',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioMarca(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva marca'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: provider.marcas.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final marca = provider.marcas[index];

                        return ListTile(
                          title: Text(marca.nombre),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _mostrarFormularioMarca(
                                  context,
                                  marca: marca,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmarEliminar(
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
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioMarca(BuildContext context, {Marca? marca}) {
    final nombreController = TextEditingController(
      text: marca?.nombre ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(marca == null ? 'Nueva marca' : 'Editar marca'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
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

if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminar(BuildContext context, Marca marca) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar marca'),
          content: Text('¿Seguro que quieres eliminar "${marca.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
ElevatedButton(
  onPressed: () async {
    final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

    await context.read<MarcaProvider>().eliminarMarca(
      marca.id!,
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