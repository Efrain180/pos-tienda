import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'providers/categoria_provider.dart';
import 'providers/marca_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/proveedor_provider.dart';
import 'providers/compra_provider.dart';
import 'providers/venta_provider.dart';
import 'providers/configuracion_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/credito_provider.dart';
import 'providers/caja_provider.dart';
import 'providers/reporte_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/auditoria_provider.dart';
import 'providers/merma_provider.dart';

import 'widgets/app_layout.dart';
import 'screens/login/login_screen.dart';
import 'screens/setup/setup_inicial_screen.dart';
import 'services/setup_service.dart';
import 'providers/licencia_provider.dart';
import 'services/licencia_service.dart';
import 'screens/licencia/licencia_vencida_screen.dart';
import 'services/premium_guard_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoriaProvider()..cargarCategorias()),
        ChangeNotifierProvider(create: (_) => MarcaProvider()..cargarMarcas()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()..cargarProductos()),
        ChangeNotifierProvider(create: (_) => ProveedorProvider()..cargarProveedores()),
        ChangeNotifierProvider(create: (_) => CompraProvider()..cargarCompras()),
        ChangeNotifierProvider(create: (_) => VentaProvider()..cargarVentas()),
        ChangeNotifierProvider(create: (_) => ConfiguracionProvider()..cargarConfiguracion()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()..cargarClientes()),
        ChangeNotifierProvider(create: (_) => CreditoProvider()),
        ChangeNotifierProvider(create: (_) => CajaProvider()..cargarCaja()),
        ChangeNotifierProvider(create: (_) => ReporteProvider()..cargarReportes()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()..cargarUsuarios()),
        ChangeNotifierProvider(create: (_) => AuditoriaProvider()..cargarAuditoria()),
        ChangeNotifierProvider(create: (_) => MermaProvider()..cargarMermas()),
        ChangeNotifierProvider(
  create: (_) => LicenciaProvider()..cargarLicencia(),
),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppInicio(),
      ),
    );
  }
}

class AppInicio extends StatelessWidget {
  const AppInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SetupService().sistemaYaConfigurado(),
      builder: (context, setupSnapshot) {
        if (!setupSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final configurado = setupSnapshot.data ?? false;

if (!configurado) {
  return const SetupInicialScreen();
}

return FutureBuilder(
  future: PremiumGuardService()
      .verificarPremiumOnlineYActualizarLocal(),
  builder: (context, premiumSnapshot) {
    if (premiumSnapshot.connectionState ==
        ConnectionState.waiting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: LicenciaService().licenciaVencida(),
      builder: (context, licenciaSnapshot) {
        if (!licenciaSnapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final vencida = licenciaSnapshot.data ?? false;

        if (vencida) {
          return const LicenciaVencidaScreen();
        }

        return Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.autenticado) {
              return const AppLayout();
            }

            return const LoginScreen();
          },
        );
      },
    );
  },
);
      },
    );
  }
}