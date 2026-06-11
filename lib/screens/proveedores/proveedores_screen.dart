import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/proveedor.dart';
import '../../providers/proveedor_provider.dart';
import '../../providers/auth_provider.dart';

class ProveedoresScreen extends StatelessWidget {
  const ProveedoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProveedorProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Proveedores',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioProveedor(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo proveedor'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: provider.proveedores.isEmpty
                        ? const Center(
                            child: Text('No hay proveedores registrados'),
                          )
                        : ListView.separated(
                            itemCount: provider.proveedores.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final proveedor = provider.proveedores[index];

                              return ListTile(
                                title: Text(proveedor.nombre),
                                subtitle: Text(
                                  'Tel: ${proveedor.telefono ?? 'Sin teléfono'} | '
                                  'Contacto: ${proveedor.contacto ?? 'Sin contacto'}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _mostrarFormularioProveedor(
                                        context,
                                        proveedor: proveedor,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Desactivar',
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _confirmarDesactivar(
                                        context,
                                        proveedor,
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

  void _mostrarFormularioProveedor(
    BuildContext context, {
    Proveedor? proveedor,
  }) {
    final nombreController = TextEditingController(
      text: proveedor?.nombre ?? '',
    );
    final telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );
    final direccionController = TextEditingController(
      text: proveedor?.direccion ?? '',
    );
    final contactoController = TextEditingController(
      text: proveedor?.contacto ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            proveedor == null ? 'Nuevo proveedor' : 'Editar proveedor',
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
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
                    controller: telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactoController,
                    decoration: const InputDecoration(
                      labelText: 'Contacto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();

                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre del proveedor es obligatorio'),
                    ),
                  );
                  return;
                }

                final nuevoProveedor = Proveedor(
                  id: proveedor?.id,
                  nombre: nombre,
                  telefono: telefonoController.text.trim().isEmpty
                      ? null
                      : telefonoController.text.trim(),
                  direccion: direccionController.text.trim().isEmpty
                      ? null
                      : direccionController.text.trim(),
                  contacto: contactoController.text.trim().isEmpty
                      ? null
                      : contactoController.text.trim(),
                  activo: true,
                );

final proveedorProvider = context.read<ProveedorProvider>();
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

if (proveedor == null) {
  await proveedorProvider.crearProveedor(
    nuevoProveedor,
    usuarioId: usuarioId,
  );
} else {
  await proveedorProvider.actualizarProveedor(
    nuevoProveedor,
    usuarioId: usuarioId,
  );
}

if (dialogContext.mounted) {
  Navigator.pop(dialogContext);
}
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarDesactivar(
    BuildContext context,
    Proveedor proveedor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Desactivar proveedor'),
          content: Text(
            '¿Seguro que quieres desactivar "${proveedor.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
ElevatedButton(
  onPressed: () async {
    final usuarioId =
        context.read<AuthProvider>().usuarioActual!.id!;

    await context.read<ProveedorProvider>().desactivarProveedor(
      proveedor.id!,
      usuarioId: usuarioId,
    );

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  },
  child: const Text('Desactivar'),
),
          ],
        );
      },
    );
  }
}