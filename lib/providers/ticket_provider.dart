import 'package:flutter/material.dart';

import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _service = TicketService();

  Future<Map<String, dynamic>> obtenerTicketVenta(int ventaId) {
    return _service.obtenerTicketVenta(ventaId);
  }
}