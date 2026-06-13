import 'package:flutter/material.dart';

import 'views/categorias_view.dart';
import 'views/marcas_view.dart';
import 'views/productos_view.dart';

class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Productos'),
              Tab(text: 'Categorías'),
              Tab(text: 'Marcas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ProductosView(),
                CategoriasView(),
                MarcasView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}