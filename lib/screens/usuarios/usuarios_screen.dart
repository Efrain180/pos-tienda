import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/auth_provider.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Usuarios / Empleados',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormularioUsuario(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo usuario'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: provider.usuarios.isEmpty
                        ? const Center(child: Text('No hay usuarios'))
                        : ListView.separated(
                            itemCount: provider.usuarios.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final usuario = provider.usuarios[index];

                              return ListTile(
                                leading: Icon(
                                  usuario.activo
                                      ? Icons.person
                                      : Icons.person_off,
                                ),
                                title: Text(usuario.nombre),
                                subtitle: Text(
                                  'Usuario: ${usuario.usuario} | Rol: ${usuario.rolNombre ?? 'Sin rol'}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        usuario.activo ? 'Activo' : 'Inactivo',
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _mostrarFormularioUsuario(
                                        context,
                                        usuarioEditar: usuario,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
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
              title: Text(
                usuarioEditar == null ? 'Nuevo usuario' : 'Editar usuario',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: !mostrarPassword,
                        decoration: InputDecoration(
                          labelText: usuarioEditar == null
                              ? 'Contraseña'
                              : 'Nueva contraseña opcional',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              mostrarPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                mostrarPassword = !mostrarPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: rolId,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Usuario activo'),
                        value: activo,
                        onChanged: (value) {
                          setState(() => activo = value);
                        },
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
                ElevatedButton(
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
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}