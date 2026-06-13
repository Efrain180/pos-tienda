import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ticket_provider.dart';

class TicketPreviewDialog extends StatelessWidget {
  final int ventaId;

  const TicketPreviewDialog({
    super.key,
    required this.ventaId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ticket venta #$ventaId'),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<Map<String, dynamic>>(
          future: context.read<TicketProvider>().obtenerTicketVenta(ventaId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final data = snapshot.data!;
            final venta = data['venta'] as Map<String, dynamic>;
            final detalles = data['detalles'] as List<Map<String, dynamic>>;
            final pagos = data['pagos'] as List<Map<String, dynamic>>;
            final config = data['configuracion'] as Map<String, dynamic>;

            final nombreNegocio =
                (config['nombre_negocio'] ?? 'Mi Tienda').toString();
            final telefono = (config['telefono'] ?? '').toString();
            final direccion = (config['direccion'] ?? '').toString();

            return SingleChildScrollView(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          nombreNegocio,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (telefono.isNotEmpty)
                        Center(child: Text('Tel: $telefono')),
                      if (direccion.isNotEmpty)
                        Center(
                          child: Text(
                            direccion,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Text('Ticket: #${venta['id']}'),
                      Text('Fecha: ${venta['fecha'].toString().substring(0, 19)}'),
                      Text('Cliente: ${venta['cliente']}'),
                      Text('Tipo: ${venta['tipo_venta']}'),
                      const Divider(),
                      ...detalles.map((detalle) {
       final productoBase = detalle['producto'].toString();

final nombrePresentacion =
    detalle['nombre_presentacion']?.toString().trim() ?? '';

final producto = nombrePresentacion.isEmpty
    ? productoBase
    : '$productoBase - $nombrePresentacion';

final cantidad = detalle['cantidad_mostrada'] == null
    ? (detalle['cantidad'] as num).toDouble()
    : (detalle['cantidad_mostrada'] as num).toDouble();

final precio =
    (detalle['precio_unitario'] as num).toDouble();

final subtotal =
    (detalle['subtotal'] as num).toDouble();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(producto),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${cantidad.toStringAsFixed(2)} x \$${precio.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  Text('\$${subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      _LineaTicket(
                        label: 'Subtotal',
                        valor:
                            '\$${(venta['subtotal'] as num).toDouble().toStringAsFixed(2)}',
                      ),
                      _LineaTicket(
                        label: 'Descuento',
                        valor:
                            '\$${(venta['descuento'] as num).toDouble().toStringAsFixed(2)}',
                      ),
                      _LineaTicket(
                        label: 'TOTAL',
                        valor:
                            '\$${(venta['total'] as num).toDouble().toStringAsFixed(2)}',
                        negrita: true,
                      ),
                      const Divider(),
                      if (pagos.isEmpty)
                        const Text('Pago: CRÉDITO / FIADO')
                      else
                        ...pagos.map((pago) {
                          final tipo = pago['tipo_pago'].toString();
                          final monto = (pago['monto'] as num).toDouble();

                          return _LineaTicket(
                            label: tipo,
                            valor: '\$${monto.toStringAsFixed(2)}',
                          );
                        }),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Gracias por su compra',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
actions: [
  TextButton.icon(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay impresora configurada todavía'),
        ),
      );
    },
    icon: const Icon(Icons.print),
    label: const Text('Imprimir'),
  ),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cerrar'),
  ),
],
    );
  }
}

class _LineaTicket extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrita;

  const _LineaTicket({
    required this.label,
    required this.valor,
    this.negrita = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}