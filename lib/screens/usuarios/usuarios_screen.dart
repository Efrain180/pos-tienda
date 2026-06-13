import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usuario_provider.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();
    final usuarios = provider.usuarios;

    final activos = usuarios.where((u) => u.activo).length;
    final inactivos = usuarios.where((u) => !u.activo).length;

    return Container(
      color: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Usuarios / Empleados',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _UsuarioResumenCard(
                  label: 'Usuarios',
                  value: usuarios.length.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _UsuarioResumenCard(
                  label: 'Activos',
                  value: activos.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _UsuarioResumenCard(
                  label: 'Inactivos',
                  value: inactivos.toString(),
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _mostrarFormularioUsuario(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Nuevo usuario'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: provider.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : usuarios.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay usuarios registrados',
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
                                        flex: 3,
                                        child: Text(
                                          'Empleado',
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
                                          'Rol',
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
                                      SizedBox(width: 58),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Expanded(
                                  child: ListView.separated(
                                    itemCount: usuarios.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final usuario = usuarios[index];

                                      final colorEstado = usuario.activo
                                          ? Colors.green
                                          : Colors.red;

                                      return Container(
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
                                            color: usuario.activo
                                                ? Colors.grey.withOpacity(0.10)
                                                : Colors.red.withOpacity(0.18),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 19,
                                              backgroundColor: colorEstado
                                                  .withOpacity(0.12),
                                              child: Icon(
                                                usuario.activo
                                                    ? Icons.person_outline
                                                    : Icons.person_off_outlined,
                                                color: colorEstado,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                usuario.nombre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                usuario.usuario,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: _UsuarioChip(
                                                  texto: usuario.rolNombre ??
                                                      'Sin rol',
                                                  color: _colorRol(
                                                    usuario.rolNombre,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: _UsuarioChip(
                                                  texto: usuario.activo
                                                      ? 'Activo'
                                                      : 'Inactivo',
                                                  color: colorEstado,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 58,
                                              child: IconButton(
                                                tooltip: 'Editar',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                onPressed: () =>
                                                    _mostrarFormularioUsuario(
                                                  context,
                                                  usuarioEditar: usuario,
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
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorRol(String? rol) {
    switch (rol) {
      case 'Administrador':
        return Colors.purple;
      case 'Encargado':
        return Colors.blue;
      case 'Cajero':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _mostrarFormularioUsuario(
    BuildContext context, {
    Usuario? usuarioEditar,
  }) {
    final provider = context.read<UsuarioProvider>();

    final nombreController = TextEditingController(
      text: usuarioEditar?.nombre ?? '',
    );
    final usuarioController = TextEditingController(
      text: usuarioEditar?.usuario ?? '',
    );
    final passwordController = TextEditingController();

    int? rolId = usuarioEditar?.rolId ??
        (provider.roles.isNotEmpty ? provider.roles.first['id'] as int : null);

    bool activo = usuarioEditar?.activo ?? true;
    bool mostrarPassword = false;

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
                      usuarioEditar == null
                          ? Icons.person_add_alt_1_outlined
                          : Icons.edit_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      usuarioEditar == null
                          ? 'Nuevo usuario'
                          : 'Editar usuario',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nombreController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
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
                              controller: usuarioController,
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: rolId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Rol',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: provider.roles.map((rol) {
                                return DropdownMenuItem<int>(
                                  value: rol['id'] as int,
                                  child: Text(rol['nombre'].toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => rolId = value);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: passwordController,
                        obscureText: !mostrarPassword,
                        decoration: InputDecoration(
                          labelText: usuarioEditar == null
                              ? 'Contraseña'
                              : 'Nueva contraseña opcional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              mostrarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                mostrarPassword = !mostrarPassword;
                              });
                            },
                          ),
                        ),
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
                        child: Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            title: const Text(
                              'Usuario activo',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              activo
                                  ? 'Este empleado puede iniciar sesión.'
                                  : 'Este empleado no podrá iniciar sesión.',
                            ),
                            value: activo,
                            onChanged: (value) {
                              setState(() => activo = value);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.18),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'El rol define qué módulos podrá ver y usar este empleado.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
                    final usuario = usuarioController.text.trim();
                    final password = passwordController.text.trim();

                    if (nombre.isEmpty || usuario.isEmpty || rolId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completa nombre, usuario y rol'),
                        ),
                      );
                      return;
                    }

                    if (usuarioEditar == null && password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La contraseña es obligatoria'),
                        ),
                      );
                      return;
                    }

                    final usuarioId =
                        context.read<AuthProvider>().usuarioActual!.id!;

                    try {
                      if (usuarioEditar == null) {
                        await provider.crearUsuario(
                          nombre: nombre,
                          usuario: usuario,
                          password: password,
                          rolId: rolId!,
                          usuarioId: usuarioId,
                        );
                      } else {
                        await provider.actualizarUsuario(
                          id: usuarioEditar.id!,
                          nombre: nombre,
                          usuario: usuario,
                          password: password.isEmpty ? null : password,
                          rolId: rolId!,
                          activo: activo,
                          usuarioId: usuarioId,
                        );
                      }

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
      },
    );
  }
}

class _UsuarioResumenCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _UsuarioResumenCard({
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

class _UsuarioChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _UsuarioChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
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