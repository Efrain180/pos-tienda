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
    final proveedores = provider.proveedores;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Proveedores',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ProveedorResumenCard(
                  label: 'Total',
                  value: proveedores.length.toString(),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioProveedor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo proveedor'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : proveedores.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay proveedores registrados',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final ancho = constraints.maxWidth;

                            final columnas = ancho >= 1300
                                ? 4
                                : ancho >= 950
                                    ? 3
                                    : ancho >= 650
                                        ? 2
                                        : 1;

                            return GridView.builder(
                              itemCount: proveedores.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnas,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.75,
                              ),
                              itemBuilder: (context, index) {
                                final proveedor = proveedores[index];

                                return _ProveedorCard(
                                  proveedor: proveedor,
                                  onEditar: () => _mostrarFormularioProveedor(
                                    context,
                                    proveedor: proveedor,
                                  ),
                                  onDesactivar: () => _confirmarDesactivar(
                                    context,
                                    proveedor,
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.12),
                child: Icon(
                  proveedor == null
                      ? Icons.add_business_outlined
                      : Icons.edit_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  proveedor == null ? 'Nuevo proveedor' : 'Editar proveedor',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nombreController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nombre del proveedor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: contactoController,
                          decoration: InputDecoration(
                            labelText: 'Contacto',
                            hintText: 'Persona encargada',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: telefonoController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: direccionController,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      hintText: 'Opcional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
            FilledButton.icon(
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
                final usuarioId =
                    context.read<AuthProvider>().usuarioActual!.id!;

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
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(
                  Icons.block_outlined,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Desactivar proveedor',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Seguro que quieres desactivar "${proveedor.nombre}"?\n\n'
            'El proveedor dejará de estar disponible para nuevas operaciones.',
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

                await context.read<ProveedorProvider>().desactivarProveedor(
                      proveedor.id!,
                      usuarioId: usuarioId,
                    );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.block_outlined),
              label: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
  }
}

class _ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;

  const _ProveedorCard({
    required this.proveedor,
    required this.onEditar,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final contacto = proveedor.contacto?.trim();
    final telefono = proveedor.telefono?.trim();
    final direccion = proveedor.direccion?.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
child: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              proveedor.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      _ProveedorInfoRow(
        icon: Icons.person_outline,
        label: contacto == null || contacto.isEmpty ? 'Sin contacto' : contacto,
        muted: contacto == null || contacto.isEmpty,
      ),
      const SizedBox(height: 4),
      _ProveedorInfoRow(
        icon: Icons.phone_outlined,
        label: telefono == null || telefono.isEmpty ? 'Sin teléfono' : telefono,
        muted: telefono == null || telefono.isEmpty,
      ),
      const SizedBox(height: 4),
      _ProveedorInfoRow(
        icon: Icons.location_on_outlined,
        label: direccion == null || direccion.isEmpty
            ? 'Sin dirección'
            : direccion,
        muted: direccion == null || direccion.isEmpty,
      ),

      const SizedBox(height: 8),

      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: onEditar,
                child: const Text('Editar'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: onDesactivar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Desactivar'),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
      ),
    );
  }
}

class _ProveedorInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _ProveedorInfoRow({
    required this.icon,
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: muted ? Colors.grey : Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted ? Colors.grey : Colors.black87,
              fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProveedorResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProveedorResumenCard({
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