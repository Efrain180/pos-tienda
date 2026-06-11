import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/credito.dart';
import '../../models/movimiento_credito.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/credito_provider.dart';
import '../../providers/auth_provider.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Clientes y fiados',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioCliente(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo cliente'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: provider.clientes.isEmpty
                        ? const Center(child: Text('No hay clientes registrados'))
                        : ListView.separated(
                            itemCount: provider.clientes.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final cliente = provider.clientes[index];

                              if (cliente.nombre == 'PUBLICO GENERAL') {
                                return const SizedBox.shrink();
                              }

                              return FutureBuilder<double>(
                                future: provider.obtenerSaldoPendiente(cliente.id!),
                                builder: (context, snapshot) {
                                  final saldo = snapshot.data ?? 0;

                                  return ListTile(
                                    title: Text(cliente.nombre),
                                    subtitle: Text(
                                      'Tel: ${cliente.telefono ?? 'Sin teléfono'} | '
                                      'Límite: \$${cliente.limiteCredito.toStringAsFixed(2)} | '
                                      'Saldo: \$${saldo.toStringAsFixed(2)}',
                                    ),
                                    leading: Icon(
                                      cliente.permiteFiado
                                          ? Icons.credit_score
                                          : Icons.person,
                                      color: cliente.bloqueadoCredito
                                          ? Colors.red
                                          : null,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(
                                            cliente.permiteFiado
                                                ? 'Fiado'
                                                : 'Normal',
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _mostrarFormularioCliente(
                                            context,
                                            cliente: cliente,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: cliente.bloqueadoCredito
                                              ? 'Desbloquear crédito'
                                              : 'Bloquear crédito',
                                          icon: Icon(
                                            cliente.bloqueadoCredito
                                                ? Icons.lock_open
                                                : Icons.lock,
                                          ),
                                          onPressed: () async {
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

await context.read<ClienteProvider>().bloquearCredito(
  cliente.id!,
  !cliente.bloqueadoCredito,
  usuarioId: usuarioId,
);
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () =>
                                        _mostrarEstadoCuenta(context, cliente),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCliente(
    BuildContext context, {
    Cliente? cliente,
  }) {
    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final telefonoController =
        TextEditingController(text: cliente?.telefono ?? '');
    final direccionController =
        TextEditingController(text: cliente?.direccion ?? '');
    final limiteController = TextEditingController(
      text: cliente?.limiteCredito.toString() ?? '0',
    );

    bool permiteFiado = cliente?.permiteFiado ?? true;
    bool bloqueadoCredito = cliente?.bloqueadoCredito ?? false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(cliente == null ? 'Nuevo cliente' : 'Editar cliente'),
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
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: limiteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Límite de crédito',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Permitir fiado'),
                        value: permiteFiado,
                        onChanged: (value) {
                          setState(() => permiteFiado = value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Bloquear crédito'),
                        value: bloqueadoCredito,
                        onChanged: permiteFiado
                            ? (value) {
                                setState(() => bloqueadoCredito = value);
                              }
                            : null,
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
                          content: Text('El nombre del cliente es obligatorio'),
                        ),
                      );
                      return;
                    }

                    final limite =
                        double.tryParse(limiteController.text.trim()) ?? 0;

                    final nuevoCliente = Cliente(
                      id: cliente?.id,
                      nombre: nombre,
                      telefono: telefonoController.text.trim().isEmpty
                          ? null
                          : telefonoController.text.trim(),
                      direccion: direccionController.text.trim().isEmpty
                          ? null
                          : direccionController.text.trim(),
                      permiteFiado: permiteFiado,
                      limiteCredito: limite,
                      bloqueadoCredito:
                          permiteFiado ? bloqueadoCredito : false,
                      fechaRegistro: cliente?.fechaRegistro ??
                          DateTime.now().toIso8601String(),
                    );
final clienteProvider = context.read<ClienteProvider>();
final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

if (cliente == null) {
  await clienteProvider.crearCliente(
    nuevoCliente,
    usuarioId: usuarioId,
  );
} else {
  await clienteProvider.actualizarCliente(
    nuevoCliente,
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
      },
    );
  }

  void _mostrarEstadoCuenta(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Estado de cuenta - ${cliente.nombre}'),
          content: SizedBox(
            width: 760,
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([
                context.read<ClienteProvider>().obtenerSaldoPendiente(cliente.id!),
                context.read<CreditoProvider>().obtenerCreditosCliente(cliente.id!),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final saldo = snapshot.data![0] as double;
                final creditos = snapshot.data![1] as List<Credito>;

                return SizedBox(
                  height: 520,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Límite',
                              valor:
                                  '\$${cliente.limiteCredito.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Saldo pendiente',
                              valor: '\$${saldo.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Disponible',
                              valor:
                                  '\$${(cliente.limiteCredito - saldo).toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: creditos.isEmpty
                            ? const Center(
                                child: Text('Este cliente no tiene créditos'),
                              )
                            : ListView.separated(
                                itemCount: creditos.length,
                                separatorBuilder: (_, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final credito = creditos[index];

                                  return ListTile(
                                    leading: Icon(
                                      credito.estado == 'PAGADO'
                                          ? Icons.check_circle
                                          : Icons.pending_actions,
                                      color: credito.estado == 'PAGADO'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    title: Text('Crédito #${credito.id}'),
                                    subtitle: Text(
                                      'Venta #${credito.ventaId} | '
                                      'Fecha: ${credito.fecha.substring(0, 10)} | '
                                      'Estado: ${credito.estado}',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Original: \$${credito.montoOriginal.toStringAsFixed(2)}',
                                        ),
                                        Text(
                                          'Saldo: \$${credito.saldoActual.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _mostrarDetalleCredito(
                                      context,
                                      cliente,
                                      credito,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetalleCredito(
    BuildContext context,
    Cliente cliente,
    Credito credito,
  ) {
    final abonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Crédito #${credito.id} - ${cliente.nombre}'),
          content: SizedBox(
            width: 700,
            child: FutureBuilder<List<MovimientoCredito>>(
              future: context
                  .read<CreditoProvider>()
                  .obtenerMovimientosCredito(credito.id!),
              builder: (context, snapshot) {
                final movimientos = snapshot.data ?? [];

                return SizedBox(
                  height: 460,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Monto original',
                              valor:
                                  '\$${credito.montoOriginal.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Saldo actual',
                              valor:
                                  '\$${credito.saldoActual.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Estado',
                              valor: credito.estado,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (credito.estado == 'PENDIENTE') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: abonoController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Monto del abono',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final monto = double.tryParse(
                                      abonoController.text.trim(),
                                    ) ??
                                    0;

                                if (monto <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Monto inválido'),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final usuarioId = context.read<AuthProvider>().usuarioActual!.id!;

await context.read<CreditoProvider>().registrarAbono(
  creditoId: credito.id!,
  monto: monto,
  usuarioId: usuarioId,
);
                                  await context
                                      .read<ClienteProvider>()
                                      .cargarClientes();

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _mostrarEstadoCuenta(context, cliente);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.payments),
                              label: const Text('Registrar abono'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Movimientos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : movimientos.isEmpty
                                ? const Center(
                                    child: Text('Sin movimientos'),
                                  )
                                : ListView.separated(
                                    itemCount: movimientos.length,
                                    separatorBuilder: (_, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final mov = movimientos[index];

                                      return ListTile(
                                        leading: Icon(
                                          mov.tipo == 'ABONO'
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: mov.tipo == 'ABONO'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        title: Text(mov.tipo),
                                        subtitle: Text(
                                          mov.fecha.substring(0, 10),
                                        ),
                                        trailing: Text(
                                          '\$${mov.monto.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _ResumenCreditoCard extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResumenCreditoCard({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(titulo),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}