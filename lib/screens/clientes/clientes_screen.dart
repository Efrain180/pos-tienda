import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/credito.dart';
import '../../models/movimiento_credito.dart';
import '../../providers/cliente_provider.dart';
import '../../providers/credito_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/detalle_credito_venta.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();

    final clientes = provider.clientes
        .where((c) => c.nombre != 'PUBLICO GENERAL')
        .toList();

    final conFiado = clientes.where((c) => c.permiteFiado).length;
    final bloqueados = clientes.where((c) => c.bloqueadoCredito).length;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Clientes y fiados',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ClienteResumenCard(
                  label: 'Clientes',
                  value: clientes.length.toString(),
                ),
                const SizedBox(width: 10),
                _ClienteResumenCard(
                  label: 'Fiado',
                  value: conFiado.toString(),
                ),
                const SizedBox(width: 10),
                _ClienteResumenCard(
                  label: 'Bloqueados',
                  value: bloqueados.toString(),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioCliente(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo cliente'),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : clientes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay clientes registrados',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                                        flex: 3,
                                        child: Text(
                                          'Cliente',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Teléfono',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Límite',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Saldo',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Estado',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 132),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: clientes.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final cliente = clientes[index];

                                      return FutureBuilder<double>(
                                        future: provider.obtenerSaldoPendiente(
                                          cliente.id!,
                                        ),
                                        builder: (context, snapshot) {
                                          final saldo = snapshot.data ?? 0;
                                          final disponible =
                                              cliente.limiteCredito - saldo;

                                          final colorEstado =
                                              cliente.bloqueadoCredito
                                                  ? Colors.red
                                                  : cliente.permiteFiado
                                                      ? Colors.green
                                                      : Colors.grey;

                                          return InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () => _mostrarEstadoCuenta(
                                              context,
                                              cliente,
                                            ),
                                            child: Container(
                                              height: 62,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: index.isEven
                                                    ? Colors.white
                                                    : const Color(0xFFFAFBFC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: cliente
                                                          .bloqueadoCredito
                                                      ? Colors.red
                                                          .withOpacity(0.28)
                                                      : saldo > 0
                                                          ? Colors.orange
                                                              .withOpacity(0.28)
                                                          : Colors.grey
                                                              .withOpacity(
                                                                  0.10),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18,
                                                    backgroundColor: colorEstado
                                                        .withOpacity(0.12),
                                                    child: Icon(
                                                      cliente.permiteFiado
                                                          ? Icons.credit_score
                                                          : Icons.person_outline,
                                                      size: 20,
                                                      color: colorEstado,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          cliente.nombre,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Disponible: \$${disponible.toStringAsFixed(2)}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: disponible < 0
                                                                ? Colors.red
                                                                : Colors.grey
                                                                    .shade600,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      cliente.telefono ??
                                                          'Sin teléfono',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      '\$${cliente.limiteCredito.toStringAsFixed(2)}',
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      '\$${saldo.toStringAsFixed(2)}',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: saldo > 0
                                                            ? Colors.orange
                                                            : Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Center(
                                                      child: _ClienteChip(
                                                        texto: cliente
                                                                .bloqueadoCredito
                                                            ? 'Bloqueado'
                                                            : cliente.permiteFiado
                                                                ? 'Fiado'
                                                                : 'Normal',
                                                        color: colorEstado,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Editar',
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                    ),
                                                    onPressed: () =>
                                                        _mostrarFormularioCliente(
                                                      context,
                                                      cliente: cliente,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: cliente
                                                            .bloqueadoCredito
                                                        ? 'Desbloquear crédito'
                                                        : 'Bloquear crédito',
                                                    icon: Icon(
                                                      cliente.bloqueadoCredito
                                                          ? Icons.lock_open
                                                          : Icons.lock_outline,
                                                    ),
                                                    color: cliente
                                                            .bloqueadoCredito
                                                        ? Colors.green
                                                        : Colors.red,
                                                    onPressed: () async {
                                                      final usuarioId = context
                                                          .read<AuthProvider>()
                                                          .usuarioActual!
                                                          .id!;

                                                      await context
                                                          .read<
                                                              ClienteProvider>()
                                                          .bloquearCredito(
                                                            cliente.id!,
                                                            !cliente
                                                                .bloqueadoCredito,
                                                            usuarioId:
                                                                usuarioId,
                                                          );
                                                    },
                                                  ),
                                                  IconButton(
                                                    tooltip:
                                                        'Estado de cuenta',
                                                    icon: const Icon(
                                                      Icons
                                                          .account_balance_wallet_outlined,
                                                    ),
                                                    onPressed: () =>
                                                        _mostrarEstadoCuenta(
                                                      context,
                                                      cliente,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                        ),
            ),
          ],
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.12),
                    child: Icon(
                      cliente == null ? Icons.person_add_alt : Icons.edit,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cliente == null ? 'Nuevo cliente' : 'Editar cliente',
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
                          labelText: 'Nombre',
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
                              controller: telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: limiteController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Límite de crédito',
                                prefixText: '\$ ',
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.14),
                          ),
                        ),
child: Column(
  children: [
    Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: const Text(
          'Permitir fiado',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'El cliente podrá comprar a crédito',
        ),
        value: permiteFiado,
        onChanged: (value) {
          setState(() => permiteFiado = value);
        },
      ),
    ),

    const Divider(height: 1),

    Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: const Text(
          'Bloquear crédito',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Evita que el cliente siga comprando fiado',
        ),
        value: bloqueadoCredito,
        onChanged: permiteFiado
            ? (value) {
                setState(() {
                  bloqueadoCredito = value;
                });
              }
            : null,
      ),
    ),
  ],
),
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
                    final usuarioId =
                        context.read<AuthProvider>().usuarioActual!.id!;

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
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estado de cuenta - ${cliente.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 840,
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([
                context
                    .read<ClienteProvider>()
                    .obtenerSaldoPendiente(cliente.id!),
                context
                    .read<CreditoProvider>()
                    .obtenerCreditosCliente(cliente.id!),
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
                final disponible = cliente.limiteCredito - saldo;

                return SizedBox(
                  height: 540,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Límite',
                              valor:
                                  '\$${cliente.limiteCredito.toStringAsFixed(2)}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Saldo pendiente',
                              valor: '\$${saldo.toStringAsFixed(2)}',
                              color: saldo > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Disponible',
                              valor:
                                  '\$${disponible.toStringAsFixed(2)}',
                              color: disponible < 0 ? Colors.red : Colors.green,
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
                            : Column(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF2F5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            'Crédito',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Venta',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Fecha',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Estado',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Original',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Saldo',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: creditos.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, index) {
                                        final credito = creditos[index];

                                        return InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () => _mostrarDetalleCredito(
                                            context,
                                            cliente,
                                            credito,
                                          ),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: index.isEven
                                                  ? Colors.white
                                                  : const Color(0xFFFAFBFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.10),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 90,
                                                  child: Text(
                                                    '#${credito.id}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '#${credito.ventaId}',
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    credito.fecha
                                                        .substring(0, 10),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _ClienteChip(
                                                    texto: credito.estado,
                                                    color: credito.estado ==
                                                            'PAGADO'
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '\$${credito.montoOriginal.toStringAsFixed(2)}',
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '\$${credito.saldoActual.toStringAsFixed(2)}',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
actions: [
  if (cliente.permiteFiado)
    TextButton.icon(
      onPressed: () async {
        final saldo = await context
            .read<ClienteProvider>()
            .obtenerSaldoPendiente(cliente.id!);

        if (saldo <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este cliente no tiene deuda pendiente'),
            ),
          );
          return;
        }

        final confirmar = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Liquidar deuda completa',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Text(
                '¿Seguro que deseas liquidar toda la deuda de ${cliente.nombre}?\n\n'
                'Monto a liquidar: \$${saldo.toStringAsFixed(2)}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Sí, liquidar todo'),
                ),
              ],
            );
          },
        );

        if (confirmar != true) return;

        final usuarioId =
            context.read<AuthProvider>().usuarioActual!.id!;

        try {
          await context.read<CreditoProvider>().liquidarDeudaCliente(
                clienteId: cliente.id!,
                usuarioId: usuarioId,
              );

          await context.read<ClienteProvider>().cargarClientes();

          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }

          if (context.mounted) {
            _mostrarEstadoCuenta(context, cliente);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Deuda liquidada por \$${saldo.toStringAsFixed(2)}',
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.done_all),
      label: const Text('Liquidar todo'),
    ),

  FilledButton(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Crédito #${credito.id} - ${cliente.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 760,
child: FutureBuilder<List<dynamic>>(
  future: Future.wait([
    context.read<CreditoProvider>().obtenerMovimientosCredito(credito.id!),
    context.read<CreditoProvider>().obtenerDetalleVentaCredito(credito.ventaId),
  ]),
              builder: (context, snapshot) {
                final movimientos = snapshot.hasData
    ? snapshot.data![0] as List<MovimientoCredito>
    : <MovimientoCredito>[];

final productos = snapshot.hasData
    ? snapshot.data![1] as List<DetalleCreditoVenta>
    : <DetalleCreditoVenta>[];

                return SizedBox(
                  height: 500,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Monto original',
                              valor:
                                  '\$${credito.montoOriginal.toStringAsFixed(2)}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Saldo actual',
                              valor:
                                  '\$${credito.saldoActual.toStringAsFixed(2)}',
                              color: credito.saldoActual > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCreditoCard(
                              titulo: 'Estado',
                              valor: credito.estado,
                              color: credito.estado == 'PAGADO'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (credito.estado == 'PENDIENTE') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: abonoController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Monto del abono',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final monto = double.tryParse(
                                          abonoController.text.trim(),
                                        ) ??
                                        0;

                                    if (monto <= 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Monto inválido'),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final usuarioId = context
                                          .read<AuthProvider>()
                                          .usuarioActual!
                                          .id!;

                                      await context
                                          .read<CreditoProvider>()
                                          .registrarAbono(
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.payments),
                                  label: const Text('Registrar abono'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Productos comprados',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
  ),
),
const SizedBox(height: 8),

Container(
  constraints: const BoxConstraints(maxHeight: 170),
  decoration: BoxDecoration(
    color: const Color(0xFFF7F8FA),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.grey.withOpacity(0.14),
    ),
  ),
  child: productos.isEmpty
      ? const SizedBox(
          height: 80,
          child: Center(
            child: Text('No se encontró el detalle de la venta'),
          ),
        )
      : ListView.separated(
          shrinkWrap: true,
          itemCount: productos.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = productos[index];

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
  flex: 4,
  child: Text(
    item.nombreVisual,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
    ),
  ),
),
Expanded(
  child: Text(
    'x${item.cantidadVisual.toStringAsFixed(2)}',
    textAlign: TextAlign.center,
  ),
),
                  Expanded(
                    child: Text(
                      '\$${item.precioUnitario.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
),

const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Movimientos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : movimientos.isEmpty
                                ? const Center(child: Text('Sin movimientos'))
                                : ListView.separated(
                                    itemCount: movimientos.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final mov = movimientos[index];

                                      return Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index.isEven
                                              ? Colors.white
                                              : const Color(0xFFFAFBFC),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color:
                                                Colors.grey.withOpacity(0.10),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 15,
                                              backgroundColor: mov.tipo ==
                                                      'ABONO'
                                                  ? Colors.green
                                                      .withOpacity(0.12)
                                                  : Colors.red
                                                      .withOpacity(0.12),
                                              child: Icon(
                                                mov.tipo == 'ABONO'
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                size: 17,
                                                color: mov.tipo == 'ABONO'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                mov.tipo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                mov.fecha.substring(0, 10),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '\$${mov.monto.toStringAsFixed(2)}',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
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
                );
              },
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _ClienteResumenCard extends StatelessWidget {
  final String label;
  final String value;

  const _ClienteResumenCard({
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

class _ClienteChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _ClienteChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ResumenCreditoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _ResumenCreditoCard({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}