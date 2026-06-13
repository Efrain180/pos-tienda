import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/caja.dart';
import '../../models/movimiento_caja.dart';
import '../../providers/caja_provider.dart';
import '../../providers/auth_provider.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CajaProvider>();

    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Corte de caja',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CajaEstadoChip(
                  texto: provider.cajaAbierta == null
                      ? 'Caja cerrada'
                      : 'Caja abierta',
                  color: provider.cajaAbierta == null
                      ? Colors.red
                      : Colors.green,
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Actualizar',
                  onPressed: () {
                    context.read<CajaProvider>().cargarCaja();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Column(
                children: [
                  if (provider.cajaAbierta == null)
                    _CajaCerradaView()
                  else
                    Expanded(
                      child: _CajaAbiertaView(
                        caja: provider.cajaAbierta!,
                      ),
                    ),

                  if (provider.cajaAbierta == null) ...[
                    const SizedBox(height: 14),
                    Expanded(
                      child: _HistorialCajasView(
                        cajas: provider.historial,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaCerradaView extends StatelessWidget {
  _CajaCerradaView();

  final montoInicialController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red.withOpacity(0.10),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No hay caja abierta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ingresa el monto inicial para comenzar operaciones del día.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: montoInicialController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto inicial',
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  final monto =
                      double.tryParse(montoInicialController.text.trim()) ?? 0;

                  try {
                    final usuarioId =
                        context.read<AuthProvider>().usuarioActual!.id!;

                    await context.read<CajaProvider>().abrirCaja(
                          montoInicial: monto,
                          usuarioId: usuarioId,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Caja abierta')),
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
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir caja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CajaAbiertaView extends StatelessWidget {
  final Caja caja;

  const _CajaAbiertaView({
    required this.caja,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _ResumenCajaCard(
              titulo: 'Monto inicial',
              valor: '\$${caja.montoInicial.toStringAsFixed(2)}',
              icono: Icons.account_balance_wallet_outlined,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _ResumenCajaCard(
              titulo: 'Esperado',
              valor: '\$${caja.montoEsperado.toStringAsFixed(2)}',
              icono: Icons.savings_outlined,
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            _ResumenCajaCard(
              titulo: 'Estado',
              valor: caja.estado,
              icono: Icons.lock_open,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _ResumenCajaCard(
              titulo: 'Apertura',
              valor: _formatearFecha(caja.fechaApertura),
              icono: Icons.calendar_today_outlined,
              color: Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _registrarGasto(context),
                  icon: const Icon(Icons.money_off_outlined),
                  label: const Text('Registrar gasto'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _cerrarCaja(context, caja),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Cerrar caja'),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _ReporteCajaView(caja: caja),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: _MovimientosCajaView(cajaId: caja.id!),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 210,
          child: _HistorialCajasView(
            cajas: context.watch<CajaProvider>().historial,
          ),
        ),
      ],
    );
  }

  static String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');

      return '$dia/$mes $hora:$minuto';
    } catch (_) {
      return fecha;
    }
  }

  void _registrarGasto(BuildContext context) {
    final categoriaController = TextEditingController();
    final descripcionController = TextEditingController();
    final montoController = TextEditingController();

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
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(
                  Icons.money_off_outlined,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registrar gasto',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoriaController,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    hintText: 'Luz, renta, gasolina, papelería...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
                final categoria = categoriaController.text.trim();
                final descripcion = descripcionController.text.trim();
                final monto = double.tryParse(montoController.text.trim()) ?? 0;

                if (categoria.isEmpty || monto <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos inválidos')),
                  );
                  return;
                }

                try {
                  final usuarioId =
                      context.read<AuthProvider>().usuarioActual!.id!;

                  await context.read<CajaProvider>().registrarGasto(
                        categoria: categoria,
                        descripcion: descripcion.isEmpty ? null : descripcion,
                        monto: monto,
                        usuarioId: usuarioId,
                      );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
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

  void _cerrarCaja(BuildContext context, Caja caja) {
    final montoContadoController = TextEditingController(
      text: caja.montoEsperado.toStringAsFixed(2),
    );

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
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cerrar caja',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.14)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Monto esperado',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '\$${caja.montoEsperado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoContadoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto contado físicamente',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
                final contado =
                    double.tryParse(montoContadoController.text.trim()) ?? 0;

                try {
                  final usuarioId =
                      context.read<AuthProvider>().usuarioActual!.id!;

                  await context.read<CajaProvider>().cerrarCaja(
                        montoContado: contado,
                        usuarioId: usuarioId,
                      );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caja cerrada')),
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
              icon: const Icon(Icons.lock_outline),
              label: const Text('Cerrar caja'),
            ),
          ],
        );
      },
    );
  }
}
class _MovimientosCajaView extends StatelessWidget {
  final int cajaId;

  const _MovimientosCajaView({
    required this.cajaId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: FutureBuilder<List<MovimientoCaja>>(
        future: context.read<CajaProvider>().obtenerMovimientosCaja(cajaId),
        builder: (context, snapshot) {
          final movimientos = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (movimientos.isEmpty) {
            return const Center(
              child: Text('Sin movimientos de caja'),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(width: 8),
                    Text(
                      'Movimientos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: movimientos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mov = movimientos[index];

                    final positivo = mov.monto >= 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: positivo
                            ? Colors.green.withOpacity(0.12)
                            : Colors.red.withOpacity(0.12),
                        child: Icon(
                          positivo
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: positivo ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        mov.tipo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        mov.referencia ?? 'Sin referencia',
                      ),
                      trailing: Text(
                        '\$${mov.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: positivo
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistorialCajasView extends StatelessWidget {
  final List<Caja> cajas;

  const _HistorialCajasView({
    required this.cajas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: cajas.isEmpty
          ? const Center(
              child: Text('No hay cortes registrados'),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text(
                        'Historial de cortes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: cajas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final caja = cajas[index];

                      return ListTile(
                        onTap: () => _mostrarDetalleCaja(context, caja),
                        leading: CircleAvatar(
                          backgroundColor: caja.estado == 'ABIERTA'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          child: Icon(
                            caja.estado == 'ABIERTA'
                                ? Icons.lock_open
                                : Icons.lock_outline,
                            color: caja.estado == 'ABIERTA'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          'Caja #${caja.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${caja.estado} • ${_fechaCorta(caja.fechaApertura)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Esperado: \$${caja.montoEsperado.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (caja.montoContado != null)
                                  Text(
                                    'Contado: \$${caja.montoContado!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility_outlined),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _mostrarDetalleCaja(BuildContext context, Caja caja) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                caja.estado == 'ABIERTA'
                    ? Icons.lock_open
                    : Icons.lock_outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detalle caja #${caja.id}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _CajaEstadoChip(
                texto: caja.estado,
                color: caja.estado == 'ABIERTA' ? Colors.green : Colors.grey,
              ),
            ],
          ),
          content: SizedBox(
            width: 860,
            height: 560,
            child: Column(
              children: [
                Row(
                  children: [
                    _DetalleCajaCard(
                      titulo: 'Monto inicial',
                      valor: '\$${caja.montoInicial.toStringAsFixed(2)}',
                      icono: Icons.account_balance_wallet_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _DetalleCajaCard(
                      titulo: 'Esperado',
                      valor: '\$${caja.montoEsperado.toStringAsFixed(2)}',
                      icono: Icons.savings_outlined,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _DetalleCajaCard(
                      titulo: 'Contado',
                      valor: caja.montoContado == null
                          ? 'Sin cierre'
                          : '\$${caja.montoContado!.toStringAsFixed(2)}',
                      icono: Icons.payments_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _DetalleCajaCard(
                      titulo: 'Faltante',
                      valor: '\$${caja.faltante.toStringAsFixed(2)}',
                      icono: Icons.trending_down,
                      color: caja.faltante > 0 ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _DetalleCajaCard(
                      titulo: 'Sobrante',
                      valor: '\$${caja.sobrante.toStringAsFixed(2)}',
                      icono: Icons.trending_up,
                      color: caja.sobrante > 0 ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _DetalleCajaCard(
                      titulo: 'Apertura',
                      valor: _fechaLarga(caja.fechaApertura),
                      icono: Icons.calendar_today_outlined,
                      color: Colors.purple,
                    ),
                  ],
                ),
                if (caja.fechaCierre != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DetalleCajaCard(
                        titulo: 'Cierre',
                        valor: _fechaLarga(caja.fechaCierre!),
                        icono: Icons.event_available_outlined,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _ReporteCajaView(caja: caja),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MovimientosCajaView(cajaId: caja.id!),
                      ),
                    ],
                  ),
                ),
              ],
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

  static String _fechaCorta(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year.toString();

      return '$dia/$mes/$anio';
    } catch (_) {
      return fecha;
    }
  }

  static String _fechaLarga(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year.toString();
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$anio $hora:$minuto';
    } catch (_) {
      return fecha;
    }
  }
}
class _ReporteCajaView extends StatelessWidget {
  final Caja caja;

  const _ReporteCajaView({
    required this.caja,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: FutureBuilder<Map<String, double>>(
        future: context.read<CajaProvider>().obtenerResumenCaja(caja.id!),
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (data == null) {
            return const Center(
              child: Text('No se pudo cargar el reporte'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Reporte de caja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _LineaReporte(
                    titulo: 'Monto inicial',
                    valor: data['apertura'] ?? 0,
                  ),
                  _LineaReporte(
                    titulo: 'Ventas efectivo',
                    valor: data['ventas_efectivo'] ?? 0,
                  ),
                  _LineaReporte(
                    titulo: 'Abonos crédito',
                    valor: data['abonos_credito'] ?? 0,
                  ),
                  _LineaReporte(
                    titulo: 'Gastos',
                    valor: data['gastos'] ?? 0,
                  ),
                  const Divider(height: 28),
                  _LineaReporte(
                    titulo: 'Total esperado',
                    valor: data['esperado'] ?? 0,
                    destacado: true,
                  ),
                  if (caja.montoContado != null) ...[
                    const SizedBox(height: 10),
                    _LineaReporte(
                      titulo: 'Monto contado',
                      valor: caja.montoContado!,
                      destacado: true,
                    ),
                    _LineaReporte(
                      titulo: 'Faltante',
                      valor: caja.faltante,
                    ),
                    _LineaReporte(
                      titulo: 'Sobrante',
                      valor: caja.sobrante,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class _LineaReporte extends StatelessWidget {
  final String titulo;
  final double valor;
  final bool destacado;

  const _LineaReporte({
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final esNegativo = valor < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
                fontSize: destacado ? 18 : 15,
              ),
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              fontSize: destacado ? 18 : 15,
              color: esNegativo ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenCajaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenCajaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
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

class _CajaEstadoChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _CajaEstadoChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
class _DetalleCajaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _DetalleCajaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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