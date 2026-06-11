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
    final ventasHoy = await _service.ventasHoy();
    final ventasMes = await _service.ventasMes();
    final comprasMes = await _service.comprasMes();
    final ganancia = await _service.gananciaEstimadaMes();
    final stockBajo = await _service.productosStockBajo();
    final porVencer = await _service.productosPorVencer();

    return _DashboardData(
      ventasHoy: ventasHoy,
      ventasMes: ventasMes,
      comprasMes: comprasMes,
      gananciaEstimada: ganancia,
      stockBajo: stockBajo,
      productosPorVencer: porVencer,
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

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Informacion',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _actualizar,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),


              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _StockBajoCard(productos: data.stockBajo),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _PorVencerCard(productos: data.productosPorVencer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardResumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _CardResumen({
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
              Icon(icono, size: 36),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo),
                  const SizedBox(height: 6),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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

class _StockBajoCard extends StatelessWidget {
  final List<Producto> productos;

  const _StockBajoCard({
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.warning_amber),
            title: Text(
              'Productos con stock bajo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: productos.isEmpty
                ? const Center(child: Text('No hay productos bajos'))
                : ListView.separated(
                    itemCount: productos.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      final faltan =
                          producto.stockMinimo - producto.stockActual;

                      return ListTile(
                        title: Text(producto.nombre),
                        subtitle: Text(
                          'Stock actual: ${producto.stockActual} | '
                          'Mínimo: ${producto.stockMinimo}',
                        ),
                        trailing: Text(
                          'Faltan: ${faltan <= 0 ? 0 : faltan}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.event_busy),
            title: Text(
              'Productos por vencer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Próximos 30 días'),
          ),
          const Divider(height: 1),
          Expanded(
            child: productos.isEmpty
                ? const Center(child: Text('No hay productos por vencer'))
                : ListView.separated(
                    itemCount: productos.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = productos[index];
                      final fecha =
                          item['fecha_caducidad'].toString().substring(0, 10);

                      return ListTile(
                        title: Text(item['producto'].toString()),
                        subtitle: Text('Cantidad: ${item['cantidad']}'),
                        trailing: Text(
                          fecha,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final double ventasHoy;
  final double ventasMes;
  final double comprasMes;
  final double gananciaEstimada;
  final List<Producto> stockBajo;
  final List<Map<String, dynamic>> productosPorVencer;

  _DashboardData({
    required this.ventasHoy,
    required this.ventasMes,
    required this.comprasMes,
    required this.gananciaEstimada,
    required this.stockBajo,
    required this.productosPorVencer,
  });
}