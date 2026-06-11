import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auditoria_provider.dart';

class AuditoriaScreen extends StatelessWidget {
  const AuditoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditoriaProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Auditoría',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () {
                  context.read<AuditoriaProvider>().cargarAuditoria();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: provider.registros.isEmpty
                        ? const Center(
                            child: Text('No hay registros de auditoría'),
                          )
                        : ListView.separated(
                            itemCount: provider.registros.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = provider.registros[index];

                              return ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  '${item.accion} - ${item.tablaAfectada}',
                                ),
                                subtitle: Text(
                                  '${item.detalle ?? 'Sin detalle'}\n'
                                  'Usuario: ${item.usuarioNombre ?? 'Sistema'} | '
                                  'Fecha: ${item.fecha.substring(0, 19)}',
                                ),
                                isThreeLine: true,
                                trailing: item.registroId == null
                                    ? null
                                    : Text(
                                        '#${item.registroId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
}