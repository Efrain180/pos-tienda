import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/caja/caja_screen.dart';
import '../screens/clientes/clientes_screen.dart';
import '../screens/compras/compras_screen.dart';
import '../screens/configuracion/configuracion_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/productos/productos_screen.dart';
import '../screens/proveedores/proveedores_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/ventas/ventas_screen.dart';
import 'app_sidebar.dart';
import '../screens/usuarios/usuarios_screen.dart';
import '../screens/auditoria/auditoria_screen.dart';
import '../screens/mermas/mermas_screen.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;

  late final List<_MenuItem> _allItems = [
    _MenuItem(
      item: SidebarItem(icon: Icons.dashboard, label: 'Informacion'),
      screen: const DashboardScreen(),
      permiso: null,
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.point_of_sale, label: 'Ventas'),
      screen: const VentasScreen(),
      permiso: 'REALIZAR_VENTA',
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.inventory_2, label: 'Productos'),
      screen: const ProductosScreen(),
      permiso: 'EDITAR_PRODUCTO',
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.shopping_cart, label: 'Compras'),
      screen: const ComprasScreen(),
      permiso: 'REGISTRAR_COMPRA',
    ),
    _MenuItem(
  item: SidebarItem(
    icon: Icons.delete_outline,
    label: 'Mermas',
  ),
  screen: const MermasScreen(),
  permiso: 'REGISTRAR_MERMA',
),
    _MenuItem(
      item: SidebarItem(icon: Icons.people, label: 'Clientes'),
      screen: const ClientesScreen(),
      permiso: 'CREAR_CLIENTE',
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.local_shipping, label: 'Proveedores'),
      screen: const ProveedoresScreen(),
      permiso: 'REGISTRAR_COMPRA',
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.attach_money, label: 'Caja'),
      screen: const CajaScreen(),
      permiso: 'REALIZAR_VENTA',
    ),
    _MenuItem(
      item: SidebarItem(icon: Icons.bar_chart, label: 'Reportes'),
      screen: const ReportesScreen(),
      permiso: 'VER_GANANCIAS',
    ),
    _MenuItem(
  item: SidebarItem(icon: Icons.admin_panel_settings, label: 'Usuarios'),
  screen: const UsuariosScreen(),
  permiso: 'ADMIN_USUARIOS',
),
_MenuItem(
  item: SidebarItem(
    icon: Icons.history,
    label: 'Auditoría',
  ),
  screen: const AuditoriaScreen(),
  permiso: 'VER_AUDITORIA',
),
    _MenuItem(
      item: SidebarItem(icon: Icons.settings, label: 'Configuración'),
      screen: const ConfiguracionScreen(),
      permiso: 'ADMIN_CONFIGURACION',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final visibleItems = _allItems.where((menu) {
      if (menu.permiso == null) return true;
      return auth.tienePermiso(menu.permiso!);
    }).toList();

    final currentIndex =
        _selectedIndex >= visibleItems.length ? 0 : _selectedIndex;

    final currentItem = visibleItems[currentIndex];

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            items: visibleItems.map((e) => e.item).toList(),
            selectedIndex: currentIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    currentItem.item.label,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: currentItem.screen,
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

class _MenuItem {
  final SidebarItem item;
  final Widget screen;
  final String? permiso;

  _MenuItem({
    required this.item,
    required this.screen,
    required this.permiso,
  });
}