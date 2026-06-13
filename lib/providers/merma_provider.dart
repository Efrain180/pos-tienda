import 'package:flutter/material.dart';

import '../models/merma.dart';
import '../services/merma_service.dart';

class MermaProvider extends ChangeNotifier {
  final _service = MermaService();

  bool _cargando = false;
  List<Merma> _mermas = [];

  bool get cargando => _cargando;
  List<Merma> get mermas => _mermas;

  Future<void> cargarMermas() async {
    _cargando = true;
    notifyListeners();

    _mermas = await _service.obtenerMermas();

    _cargando = false;
    notifyListeners();
  }

  Future<void> registrarMerma(Merma merma) async {
    await _service.registrarMerma(merma);
    await cargarMermas();
  }
}