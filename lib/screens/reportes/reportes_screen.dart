import 'package:fl_chart/fl_chart.dart';
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

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reportes',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _PeriodoSelector(provider: provider),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Actualizar',
                  onPressed: () {
                    context.read<ReporteProvider>().cargarReportes();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _KpiCard(
                  titulo: 'Ventas netas',
                  valor: provider.ventasNetas,
                  icono: Icons.point_of_sale_outlined,
                  color: Colors.green,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _KpiCard(
                  titulo: 'Utilidad bruta',
                  valor: provider.utilidadBruta,
                  icono: Icons.trending_up,
                  color: provider.utilidadBruta >= 0 ? Colors.teal : Colors.red,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _KpiCard(
                  titulo: 'Margen bruto',
                  valor: provider.margenBruto,
                  icono: Icons.percent,
                  color: provider.margenBruto >= 30
                      ? Colors.green
                      : provider.margenBruto >= 15
                          ? Colors.orange
                          : Colors.red,
                  formato: _FormatoKpi.porcentaje,
                ),
                const SizedBox(width: 12),
                _KpiCard(
                  titulo: 'Utilidad neta aprox.',
                  valor: provider.utilidadNetaAprox,
                  icono: Icons.account_balance_wallet_outlined,
                  color:
                      provider.utilidadNetaAprox >= 0 ? Colors.green : Colors.red,
                  formato: _FormatoKpi.dinero,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _MiniKpiCard(
                  titulo: 'Costo ventas',
                  valor: provider.costoVentas,
                  color: Colors.indigo,
                  icono: Icons.inventory_2_outlined,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _MiniKpiCard(
                  titulo: 'Gastos',
                  valor: provider.gastos,
                  color: Colors.red,
                  icono: Icons.money_off_outlined,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _MiniKpiCard(
                  titulo: 'Mermas',
                  valor: provider.valorMerma,
                  color: Colors.deepOrange,
                  icono: Icons.warning_amber_rounded,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _MiniKpiCard(
                  titulo: 'Ticket promedio',
                  valor: provider.ticketPromedio,
                  color: Colors.blue,
                  icono: Icons.receipt_long_outlined,
                  formato: _FormatoKpi.dinero,
                ),
                const SizedBox(width: 12),
                _MiniKpiCard(
                  titulo: 'Tickets',
                  valor: provider.numeroVentas,
                  color: Colors.purple,
                  icono: Icons.confirmation_number_outlined,
                  formato: _FormatoKpi.numero,
                ),
                const SizedBox(width: 12),
                _MiniKpiCard(
                  titulo: 'Productos',
                  valor: provider.productosVendidos,
                  color: Colors.orange,
                  icono: Icons.shopping_basket_outlined,
                  formato: _FormatoKpi.numero,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: _GraficaRentabilidad(provider: provider),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _GraficaVentasPorDia(
                            data: provider.ventasPorDia,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _ListaConBarras(
                            titulo: 'Top más vendidos',
                            subtitulo: 'Ordenado por cantidad',
                            icono: Icons.local_fire_department_outlined,
                            items: provider.productosMasVendidos,
                            color: Colors.orange,
                            emptyText: 'Sin productos vendidos',
                            nombreBuilder: (item) => item['producto'].toString(),
                            detalleBuilder: (item) {
                              final cantidad =
                                  (item['cantidad'] as num?)?.toDouble() ?? 0;
                              return 'Cantidad: ${cantidad.toStringAsFixed(0)}';
                            },
                            valorBuilder: (item) {
                              return (item['total'] as num?)?.toDouble() ?? 0;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _ListaConBarras(
                            titulo: 'Top rentables',
                            subtitulo: 'Ordenado por utilidad',
                            icono: Icons.attach_money,
                            items: provider.productosMasRentables,
                            color: Colors.green,
                            emptyText: 'Sin utilidad registrada',
                            nombreBuilder: (item) => item['producto'].toString(),
                            detalleBuilder: (item) {
                              final venta =
                                  (item['venta'] as num?)?.toDouble() ?? 0;
                              final costo =
                                  (item['costo'] as num?)?.toDouble() ?? 0;
                              return 'Venta \$${venta.toStringAsFixed(2)} | Costo \$${costo.toStringAsFixed(2)}';
                            },
                            valorBuilder: (item) {
                              return (item['utilidad'] as num?)?.toDouble() ?? 0;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _ListaConBarras(
                            titulo: 'Clientes con deuda',
                            subtitulo: 'A quién debes cobrarle',
                            icono: Icons.people_alt_outlined,
                            items: provider.clientesConDeuda,
                            color: Colors.red,
                            emptyText: 'No hay clientes con deuda',
                            nombreBuilder: (item) => item['cliente'].toString(),
                            detalleBuilder: (item) {
                              final limite =
                                  (item['limite'] as num?)?.toDouble() ?? 0;
                              return 'Límite: \$${limite.toStringAsFixed(2)}';
                            },
                            valorBuilder: (item) {
                              return (item['saldo'] as num?)?.toDouble() ?? 0;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _ListaConBarras(
                            titulo: 'Mermas por motivo',
                            subtitulo: 'Pérdida estimada por daño/caducidad',
                            icono: Icons.warning_amber_rounded,
                            items: provider.mermasPorMotivo,
                            color: Colors.deepOrange,
                            emptyText: 'Sin mermas registradas',
                            nombreBuilder: (item) =>
                                _motivoLegible(item['motivo'].toString()),
                            detalleBuilder: (item) {
                              final cantidad =
                                  (item['cantidad'] as num?)?.toDouble() ?? 0;
                              return 'Cantidad: ${cantidad.toStringAsFixed(0)}';
                            },
                            valorBuilder: (item) {
                              return (item['total'] as num?)?.toDouble() ?? 0;
                            },
                          ),
                        ),
                      ],
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

enum _FormatoKpi {
  dinero,
  numero,
  porcentaje,
}

String _formatearValor(double valor, _FormatoKpi formato) {
  switch (formato) {
    case _FormatoKpi.dinero:
      return '\$${valor.toStringAsFixed(2)}';
    case _FormatoKpi.porcentaje:
      return '${valor.toStringAsFixed(2)}%';
    case _FormatoKpi.numero:
      return valor.toStringAsFixed(0);
  }
}

String _motivoLegible(String motivo) {
  switch (motivo) {
    case 'PRODUCTO_ROTO':
      return 'Producto roto';
    case 'PRODUCTO_CADUCADO':
      return 'Producto caducado';
    case 'PRODUCTO_PERDIDO':
      return 'Producto perdido';
    case 'DEVOLUCION_DANADA':
      return 'Devolución dañada';
    case 'CONSUMO_INTERNO':
      return 'Consumo interno';
    case 'ROBO':
      return 'Robo';
    default:
      return motivo;
  }
}

class _PeriodoSelector extends StatelessWidget {
  final ReporteProvider provider;

  const _PeriodoSelector({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReportePeriodo>(
      segments: const [
        ButtonSegment(
          value: ReportePeriodo.hoy,
          label: Text('Hoy'),
          icon: Icon(Icons.today_outlined),
        ),
        ButtonSegment(
          value: ReportePeriodo.semana,
          label: Text('Semana'),
          icon: Icon(Icons.date_range_outlined),
        ),
        ButtonSegment(
          value: ReportePeriodo.mes,
          label: Text('Mes'),
          icon: Icon(Icons.calendar_month_outlined),
        ),
      ],
      selected: {provider.periodo},
      onSelectionChanged: (value) {
        context.read<ReporteProvider>().cambiarPeriodo(value.first);
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final double valor;
  final IconData icono;
  final Color color;
  final _FormatoKpi formato;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.formato,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icono, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearValor(valor, formato),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color color;
  final IconData icono;
  final _FormatoKpi formato;

  const _MiniKpiCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
    required this.formato,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icono, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      _formatearValor(valor, formato),
                      style: TextStyle(
                        fontSize: 17,
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficaRentabilidad extends StatelessWidget {
  final ReporteProvider provider;

  const _GraficaRentabilidad({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final valores = [
      provider.ventasNetas,
      provider.costoVentas,
      provider.utilidadBruta.abs(),
      provider.gastos,
      provider.valorMerma,
      provider.utilidadNetaAprox.abs(),
    ];

    final maxY = valores.fold<double>(
      0,
      (max, valor) => valor > max ? valor : max,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rentabilidad del periodo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 0 ? 100 : maxY * 1.25,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Ventas',
                            'Costo',
                            'Bruta',
                            'Gastos',
                            'Mermas',
                            'Neta',
                          ];

                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    _bar(0, provider.ventasNetas, Colors.green),
                    _bar(1, provider.costoVentas, Colors.indigo),
                    _bar(
                      2,
                      provider.utilidadBruta.abs(),
                      provider.utilidadBruta >= 0 ? Colors.teal : Colors.red,
                    ),
                    _bar(3, provider.gastos, Colors.red),
                    _bar(4, provider.valorMerma, Colors.deepOrange),
                    _bar(
                      5,
                      provider.utilidadNetaAprox.abs(),
                      provider.utilidadNetaAprox >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value < 0 ? 0 : value,
          width: 22,
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ],
    );
  }
}

class _GraficaVentasPorDia extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _GraficaVentasPorDia({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final puntos = <FlSpot>[];

    for (var i = 0; i < data.length; i++) {
      final total = (data[i]['total'] as num?)?.toDouble() ?? 0;
      puntos.add(FlSpot(i.toDouble(), total));
    }

    final maxY = puntos.isEmpty
        ? 100.0
        : puntos
            .map((p) => p.y)
            .fold<double>(0, (max, valor) => valor > max ? valor : max);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ventas por día',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: puntos.isEmpty
                  ? const Center(child: Text('Sin ventas en este periodo'))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY <= 0 ? 100 : maxY * 1.25,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: puntos,
                            isCurved: true,
                            barWidth: 4,
                            color: Colors.green,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaConBarras extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<Map<String, dynamic>> items;
  final Color color;
  final String emptyText;
  final String Function(Map<String, dynamic> item) nombreBuilder;
  final String Function(Map<String, dynamic> item) detalleBuilder;
  final double Function(Map<String, dynamic> item) valorBuilder;

  const _ListaConBarras({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.items,
    required this.color,
    required this.emptyText,
    required this.nombreBuilder,
    required this.detalleBuilder,
    required this.valorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final maxValor = items.isEmpty
        ? 0.0
        : items
            .map(valorBuilder)
            .fold<double>(0, (max, valor) => valor > max ? valor : max);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icono, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        emptyText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final valor = valorBuilder(item);
                        final porcentaje =
                            maxValor <= 0 ? 0.0 : valor / maxValor;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.10),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: color.withOpacity(0.12),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      nombreBuilder(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${valor.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  detalleBuilder(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: porcentaje.clamp(0.0, 1.0),
                                  backgroundColor: color.withOpacity(0.10),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
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
    );
  }
}