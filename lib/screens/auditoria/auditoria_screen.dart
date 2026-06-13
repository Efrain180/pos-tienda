import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auditoria_provider.dart';

class AuditoriaScreen extends StatelessWidget {
  const AuditoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditoriaProvider>();
    final registros = provider.registros;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.manage_search_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Auditoría',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _AuditoriaPeriodoSelector(provider: provider),
                const SizedBox(width: 12),
                _AuditoriaResumenCard(
                  label: 'Cargados',
                  value: registros.length.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Actualizar',
                  onPressed: () {
                    context.read<AuditoriaProvider>().cargarAuditoria();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _AuditoriaFiltros(provider: provider),

            const SizedBox(height: 12),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : registros.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay registros de auditoría con estos filtros',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
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
                                        flex: 2,
                                        child: Text(
                                          'Acción',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Módulo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          'Detalle',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Usuario',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Fecha',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 56),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: registros.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final item = registros[index];
                                      final color = _colorAccion(item.accion);

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _mostrarDetalleAuditoria(
                                          context,
                                          item,
                                        ),
                                        child: Container(
                                          height: 62,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: index.isEven
                                                ? Colors.white
                                                : const Color(0xFFFAFBFC),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: color.withOpacity(0.18),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: _AuditoriaChip(
                                                    texto: item.accion,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  _moduloLegible(
                                                    item.tablaAfectada,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 4,
                                                child: Text(
                                                  item.detalle ?? 'Sin detalle',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  item.usuarioNombre ??
                                                      'Sistema',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  _formatearFecha(item.fecha),
                                                  textAlign: TextAlign.right,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 56,
                                                child: IconButton(
                                                  tooltip: 'Ver detalle',
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarDetalleAuditoria(
                                                    context,
                                                    item,
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

                                if (provider.hayMas) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      onPressed: provider.cargandoMas
                                          ? null
                                          : () {
                                              context
                                                  .read<AuditoriaProvider>()
                                                  .cargarMas();
                                            },
                                      icon: provider.cargandoMas
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.expand_more),
                                      label: Text(
                                        provider.cargandoMas
                                            ? 'Cargando...'
                                            : 'Cargar más registros',
                                      ),
                                    ),
                                  ),
                                ],
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

  void _mostrarDetalleAuditoria(BuildContext context, dynamic item) {
    final color = _colorAccion(item.accion);

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
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  _iconoAccion(item.accion),
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Detalle de auditoría',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetalleAuditoriaRow(
                  label: 'Acción realizada',
                  value: item.accion,
                  color: color,
                ),
                _DetalleAuditoriaRow(
                  label: 'Módulo afectado',
                  value: _moduloLegible(item.tablaAfectada),
                ),
                _DetalleAuditoriaRow(
                  label: 'Tabla interna',
                  value: item.tablaAfectada,
                ),
                _DetalleAuditoriaRow(
                  label: 'Registro',
                  value: item.registroId == null
                      ? 'Sin registro relacionado'
                      : '#${item.registroId}',
                ),
                _DetalleAuditoriaRow(
                  label: 'Usuario',
                  value: item.usuarioNombre ?? 'Sistema',
                ),
                _DetalleAuditoriaRow(
                  label: 'Fecha',
                  value: _formatearFechaLarga(item.fecha),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.detalle ?? 'Sin detalle',
                        style: const TextStyle(height: 1.35),
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

  static Color _colorAccion(String accion) {
    final a = accion.toUpperCase();

    if (a.contains('VENTA')) return Colors.green;
    if (a.contains('COMPRA')) return Colors.blue;
    if (a.contains('MERMA')) return Colors.deepOrange;
    if (a.contains('GASTO')) return Colors.red;
    if (a.contains('USUARIO')) return Colors.purple;
    if (a.contains('CAJA')) return Colors.teal;
    if (a.contains('PRODUCTO')) return Colors.indigo;
    if (a.contains('CLIENTE')) return Colors.orange;

    return Colors.blueGrey;
  }

  static IconData _iconoAccion(String accion) {
    final a = accion.toUpperCase();

    if (a.contains('VENTA')) return Icons.point_of_sale_outlined;
    if (a.contains('COMPRA')) return Icons.shopping_cart_outlined;
    if (a.contains('MERMA')) return Icons.warning_amber_rounded;
    if (a.contains('GASTO')) return Icons.money_off_outlined;
    if (a.contains('USUARIO')) return Icons.person_outline;
    if (a.contains('CAJA')) return Icons.account_balance_wallet_outlined;
    if (a.contains('PRODUCTO')) return Icons.inventory_2_outlined;
    if (a.contains('CLIENTE')) return Icons.people_alt_outlined;

    return Icons.history;
  }

  static String _moduloLegible(String tabla) {
    switch (tabla) {
      case 'ventas':
        return 'Ventas';
      case 'detalle_venta':
        return 'Detalle venta';
      case 'compras':
        return 'Compras';
      case 'detalle_compra':
        return 'Detalle compra';
      case 'productos':
        return 'Productos';
      case 'clientes':
        return 'Clientes';
      case 'proveedores':
        return 'Proveedores';
      case 'usuarios':
        return 'Usuarios';
      case 'cajas':
        return 'Caja';
      case 'gastos':
        return 'Gastos';
      case 'mermas':
        return 'Mermas';
      case 'creditos':
        return 'Créditos';
      case 'movimientos_inventario':
        return 'Inventario';
      default:
        return tabla;
    }
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

  static String _formatearFechaLarga(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year.toString();
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');
      final segundo = date.second.toString().padLeft(2, '0');

      return '$dia/$mes/$anio $hora:$minuto:$segundo';
    } catch (_) {
      return fecha;
    }
  }
}

class _AuditoriaPeriodoSelector extends StatelessWidget {
  final AuditoriaProvider provider;

  const _AuditoriaPeriodoSelector({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AuditoriaPeriodo>(
      segments: const [
        ButtonSegment(
          value: AuditoriaPeriodo.hoy,
          label: Text('Hoy'),
          icon: Icon(Icons.today_outlined),
        ),
        ButtonSegment(
          value: AuditoriaPeriodo.semana,
          label: Text('Semana'),
          icon: Icon(Icons.date_range_outlined),
        ),
        ButtonSegment(
          value: AuditoriaPeriodo.mes,
          label: Text('Mes'),
          icon: Icon(Icons.calendar_month_outlined),
        ),
        ButtonSegment(
          value: AuditoriaPeriodo.todo,
          label: Text('Todo'),
          icon: Icon(Icons.all_inclusive),
        ),
      ],
      selected: {provider.periodo},
      onSelectionChanged: (value) {
        context.read<AuditoriaProvider>().cambiarPeriodo(value.first);
      },
    );
  }
}

class _AuditoriaFiltros extends StatefulWidget {
  final AuditoriaProvider provider;

  const _AuditoriaFiltros({
    required this.provider,
  });

  @override
  State<_AuditoriaFiltros> createState() => _AuditoriaFiltrosState();
}

class _AuditoriaFiltrosState extends State<_AuditoriaFiltros> {
  late final TextEditingController buscarController;

  @override
  void initState() {
    super.initState();
    buscarController = TextEditingController(
      text: widget.provider.buscar,
    );
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: buscarController,
            decoration: InputDecoration(
              hintText: 'Buscar por detalle, usuario o acción...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: buscarController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        buscarController.clear();
                        context.read<AuditoriaProvider>().cambiarBusqueda('');
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) {
              setState(() {});
            },
            onSubmitted: (value) {
              context.read<AuditoriaProvider>().cambiarBusqueda(value);
            },
          ),
        ),

        const SizedBox(width: 12),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String?>(
            initialValue: provider.tabla,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Módulo',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ventas', child: Text('Ventas')),
              DropdownMenuItem(value: 'compras', child: Text('Compras')),
              DropdownMenuItem(value: 'productos', child: Text('Productos')),
              DropdownMenuItem(value: 'clientes', child: Text('Clientes')),
              DropdownMenuItem(value: 'proveedores', child: Text('Proveedores')),
              DropdownMenuItem(value: 'usuarios', child: Text('Usuarios')),
              DropdownMenuItem(value: 'cajas', child: Text('Caja')),
              DropdownMenuItem(value: 'gastos', child: Text('Gastos')),
              DropdownMenuItem(value: 'mermas', child: Text('Mermas')),
              DropdownMenuItem(value: 'creditos', child: Text('Créditos')),
            ],
            onChanged: (value) {
              context.read<AuditoriaProvider>().cambiarTabla(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              buscarController.clear();
              context.read<AuditoriaProvider>().limpiarFiltros();
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpiar'),
          ),
        ),
      ],
    );
  }
}

class _AuditoriaResumenCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AuditoriaResumenCard({
    required this.label,
    required this.value,
    required this.color,
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
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditoriaChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _AuditoriaChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
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

class _DetalleAuditoriaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetalleAuditoriaRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = color ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}