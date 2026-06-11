import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/reporte_provider.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReporteProvider>();

    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final resumen = provider.resumen;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reportes',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () {
                  context.read<ReporteProvider>().cargarReportes();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ReporteCard(
                titulo: 'Ventas hoy',
                valor: resumen['ventas_hoy'] ?? 0,
                icono: Icons.today,
              ),
              _ReporteCard(
                titulo: 'Ventas mes',
                valor: resumen['ventas_mes'] ?? 0,
                icono: Icons.point_of_sale,
              ),
              _ReporteCard(
                titulo: 'Ganancia mes',
                valor: provider.gananciaMes,
                icono: Icons.trending_up,
              ),
              _ReporteCard(
                titulo: 'Fiado pendiente',
                valor: resumen['fiado_pendiente'] ?? 0,
                icono: Icons.credit_score,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ReporteCard(
                titulo: 'Compras mes',
                valor: resumen['compras_mes'] ?? 0,
                icono: Icons.shopping_cart,
              ),
              _ReporteCard(
                titulo: 'Gastos mes',
                valor: resumen['gastos_mes'] ?? 0,
                icono: Icons.money_off,
              ),
              _ReporteCard(
                titulo: 'Utilidad aprox.',
                valor: (provider.gananciaMes) - (resumen['gastos_mes'] ?? 0),
                icono: Icons.attach_money,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ListaReporte(
                    titulo: 'Productos más vendidos del mes',
                    icono: Icons.local_fire_department,
                    items: provider.productosMasVendidos,
                    itemBuilder: (item) {
                      final producto = item['producto'].toString();
                      final cantidad =
                          (item['cantidad'] as num?)?.toDouble() ?? 0;
                      final total = (item['total'] as num?)?.toDouble() ?? 0;

                      return ListTile(
                        title: Text(producto),
                        subtitle: Text('Cantidad vendida: $cantidad'),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ListaReporte(
                    titulo: 'Clientes con deuda',
                    icono: Icons.people,
                    items: provider.clientesConDeuda,
                    itemBuilder: (item) {
                      final cliente = item['cliente'].toString();
                      final limite =
                          (item['limite'] as num?)?.toDouble() ?? 0;
                      final saldo = (item['saldo'] as num?)?.toDouble() ?? 0;

                      return ListTile(
                        title: Text(cliente),
                        subtitle: Text(
                          'Límite: \$${limite.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          '\$${saldo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ListaReporte(
                    titulo: 'Gastos por categoría',
                    icono: Icons.receipt_long,
                    items: provider.gastosMes,
                    itemBuilder: (item) {
                      final categoria = item['categoria'].toString();
                      final total = (item['total'] as num?)?.toDouble() ?? 0;

                      return ListTile(
                        title: Text(categoria),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}

class _ReporteCard extends StatelessWidget {
  final String titulo;
  final double valor;
  final IconData icono;

  const _ReporteCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icono, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo),
                    const SizedBox(height: 6),
                    Text(
                      '\$${valor.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaReporte extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic> item) itemBuilder;

  const _ListaReporte({
    required this.titulo,
    required this.icono,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icono),
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Sin información'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return itemBuilder(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}