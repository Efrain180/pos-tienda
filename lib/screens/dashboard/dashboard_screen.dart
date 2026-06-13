import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargarDashboard();
  }

  Future<_DashboardData> _cargarDashboard() async {
    final stockBajo = await _service.productosStockBajo();
    final agotados = await _service.productosAgotados();
    final porVencer = await _service.productosPorVencer();
    final fiadoPendiente = await _service.fiadoPendiente();
    final mermasMes = await _service.mermasMes();
    final masVendidos = await _service.productosMasVendidosSemana();
    final sinMovimiento = await _service.productosSinMovimiento();

    return _DashboardData(
      stockBajo: stockBajo,
      agotados: agotados,
      productosPorVencer: porVencer,
      fiadoPendiente: fiadoPendiente,
      mermasMes: mermasMes,
      productosMasVendidos: masVendidos,
      productosSinMovimiento: sinMovimiento,
    );
  }

  void _actualizar() {
    setState(() {
      _future = _cargarDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        final pendientes = data.stockBajo.length +
            data.agotados.length +
            data.productosPorVencer.length;

        return Container(
          color: const Color(0xFFF4F6F8),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.dashboard_outlined, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Información',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _EstadoOperacionChip(pendientes: pendientes),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Actualizar',
                      onPressed: _actualizar,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    _KpiDashboardCard(
                      titulo: 'Stock bajo',
                      valor: data.stockBajo.length.toString(),
                      descripcion: 'Productos por reponer',
                      icono: Icons.inventory_2_outlined,
                      color: data.stockBajo.isEmpty
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _KpiDashboardCard(
                      titulo: 'Agotados',
                      valor: data.agotados.length.toString(),
                      descripcion: 'Productos en cero',
                      icono: Icons.remove_shopping_cart_outlined,
                      color:
                          data.agotados.isEmpty ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _KpiDashboardCard(
                      titulo: 'Por vencer',
                      valor: data.productosPorVencer.length.toString(),
                      descripcion: 'Próximos 30 días',
                      icono: Icons.event_busy_outlined,
                      color: data.productosPorVencer.isEmpty
                          ? Colors.green
                          : Colors.deepOrange,
                    ),
                    const SizedBox(width: 12),
                    _KpiDashboardCard(
                      titulo: 'Fiado pendiente',
                      valor: '\$${data.fiadoPendiente.toStringAsFixed(2)}',
                      descripcion: 'Dinero por cobrar',
                      icono: Icons.credit_score_outlined,
                      color: data.fiadoPendiente <= 0
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _MiniInfoCard(
                      titulo: 'Mermas del mes',
                      valor: _formatearNumero(data.mermasMes),
                      icono: Icons.warning_amber_rounded,
                      color: data.mermasMes <= 0
                          ? Colors.green
                          : Colors.deepOrange,
                    ),
                    const SizedBox(width: 12),
                    _MiniInfoCard(
                      titulo: 'Más vendidos semana',
                      valor: data.productosMasVendidos.length.toString(),
                      icono: Icons.local_fire_department_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _MiniInfoCard(
                      titulo: 'Sin movimiento',
                      valor: data.productosSinMovimiento.length.toString(),
                      icono: Icons.hourglass_empty_outlined,
                      color: data.productosSinMovimiento.isEmpty
                          ? Colors.green
                          : Colors.blueGrey,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _StockBajoCard(productos: data.stockBajo),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PorVencerCard(
                          productos: data.productosPorVencer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _ListaSimpleDashboard(
                                titulo: 'Más vendidos esta semana',
                                subtitulo: 'Ayuda a saber qué surtir',
                                icono: Icons.local_fire_department_outlined,
                                color: Colors.orange,
                                emptyText: 'Sin ventas esta semana',
                                items: data.productosMasVendidos,
                                nombreBuilder: (item) =>
                                    item['producto'].toString(),
                                detalleBuilder: (item) {
                                  final cantidad =
                                      (item['cantidad'] as num?)?.toDouble() ??
                                          0;
                                  return 'Vendidos: ${_formatearNumero(cantidad)}';
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: _ListaSimpleDashboard(
                                titulo: 'Productos sin movimiento',
                                subtitulo: 'Más de 30 días sin vender',
                                icono: Icons.hourglass_empty_outlined,
                                color: Colors.blueGrey,
                                emptyText: 'Todo tiene movimiento',
                                items: data.productosSinMovimiento,
                                nombreBuilder: (item) =>
                                    item['nombre'].toString(),
                                detalleBuilder: (item) {
                                  final stock =
                                      (item['stock_actual'] as num?)
                                              ?.toDouble() ??
                                          0;
                                  final ultima =
                                      item['ultima_venta']?.toString();

                                  return ultima == null
                                      ? 'Stock: ${_formatearNumero(stock)} · Nunca vendido'
                                      : 'Stock: ${_formatearNumero(stock)} · Última venta: ${_formatearFecha(ultima)}';
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
      },
    );
  }
}

class _EstadoOperacionChip extends StatelessWidget {
  final int pendientes;

  const _EstadoOperacionChip({
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    final bien = pendientes == 0;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:
            bien ? Colors.green.withOpacity(0.10) : Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: bien
              ? Colors.green.withOpacity(0.22)
              : Colors.orange.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bien ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: bien ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            bien ? 'Todo en orden' : '$pendientes pendientes',
            style: TextStyle(
              color: bien ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiDashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descripcion;
  final IconData icono;
  final Color color;

  const _KpiDashboardCard({
    required this.titulo,
    required this.valor,
    required this.descripcion,
    required this.icono,
    required this.color,
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
                      valor,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
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

class _MiniInfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _MiniInfoCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 74,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icono, color: color, size: 22),
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
                      valor,
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

class _StockBajoCard extends StatelessWidget {
  final List<Producto> productos;

  const _StockBajoCard({
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelDashboard(
      titulo: 'Productos que comprar',
      subtitulo: 'Basado en stock mínimo',
      icono: Icons.inventory_2_outlined,
      color: Colors.orange,
      emptyText: 'No hay productos bajos',
      child: productos.isEmpty
          ? null
          : ListView.separated(
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final producto = productos[index];

                final faltan =
                    producto.stockMinimo - producto.stockActual;

                final double faltanSeguro =
                    faltan <= 0 ? 0.0 : faltan;

                final porcentaje = producto.stockMinimo <= 0
                    ? 1.0
                    : (producto.stockActual / producto.stockMinimo)
                        .clamp(0.0, 1.0);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _DashboardChip(
                            texto:
                                'Comprar ${_formatearNumero(faltanSeguro)}',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Actual: ${_formatearNumero(producto.stockActual)} · Mínimo: ${_formatearNumero(producto.stockMinimo)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: porcentaje,
                          backgroundColor: Colors.orange.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PorVencerCard extends StatelessWidget {
  final List<Map<String, dynamic>> productos;

  const _PorVencerCard({
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelDashboard(
      titulo: 'Productos por vencer',
      subtitulo: 'Próximos 30 días',
      icono: Icons.event_busy_outlined,
      color: Colors.red,
      emptyText: 'No hay productos por vencer',
      child: productos.isEmpty
          ? null
          : ListView.separated(
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = productos[index];

                final producto = item['producto'].toString();
                final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 0;
                final fechaRaw = item['fecha_caducidad'].toString();
                final fecha = _formatearFecha(fechaRaw);
                final dias = _diasParaVencer(fechaRaw);

                final color = dias <= 7 ? Colors.red : Colors.orange;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withOpacity(0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(
                          dias <= 7
                              ? Icons.error_outline
                              : Icons.schedule_outlined,
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: ${_formatearNumero(cantidad)} · Vence: $fecha',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _DashboardChip(
                        texto: dias < 0
                            ? 'Vencido'
                            : dias == 0
                                ? 'Hoy'
                                : '$dias días',
                        color: color,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ListaSimpleDashboard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final String emptyText;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic> item) nombreBuilder;
  final String Function(Map<String, dynamic> item) detalleBuilder;

  const _ListaSimpleDashboard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.emptyText,
    required this.items,
    required this.nombreBuilder,
    required this.detalleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelDashboard(
      titulo: titulo,
      subtitulo: subtitulo,
      icono: icono,
      color: color,
      emptyText: emptyText,
      child: items.isEmpty
          ? null
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withOpacity(0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: color.withOpacity(0.12),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreBuilder(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detalleBuilder(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
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
    );
  }
}

class _PanelDashboard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final String emptyText;
  final Widget? child;

  const _PanelDashboard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.emptyText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
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
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: child ??
                  Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _DashboardChip({
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatearNumero(double valor) {
  if (valor % 1 == 0) return valor.toStringAsFixed(0);
  return valor.toStringAsFixed(2);
}

String _formatearFecha(String fecha) {
  try {
    final date = DateTime.parse(fecha);
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final anio = date.year.toString();

    return '$dia/$mes/$anio';
  } catch (_) {
    return fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
  }
}

int _diasParaVencer(String fecha) {
  try {
    final caducidad = DateTime.parse(fecha);
    final hoy = DateTime.now();

    final hoyLimpio = DateTime(hoy.year, hoy.month, hoy.day);
    final caducidadLimpia = DateTime(
      caducidad.year,
      caducidad.month,
      caducidad.day,
    );

    return caducidadLimpia.difference(hoyLimpio).inDays;
  } catch (_) {
    return 999;
  }
}

class _DashboardData {
  final List<Producto> stockBajo;
  final List<Producto> agotados;
  final List<Map<String, dynamic>> productosPorVencer;
  final double fiadoPendiente;
  final double mermasMes;
  final List<Map<String, dynamic>> productosMasVendidos;
  final List<Map<String, dynamic>> productosSinMovimiento;

  _DashboardData({
    required this.stockBajo,
    required this.agotados,
    required this.productosPorVencer,
    required this.fiadoPendiente,
    required this.mermasMes,
    required this.productosMasVendidos,
    required this.productosSinMovimiento,
  });
}