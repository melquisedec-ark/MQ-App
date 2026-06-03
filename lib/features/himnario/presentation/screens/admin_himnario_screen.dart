import 'package:flutter/material.dart';

import '../../../../presentation/views_admin/crud_catalogs/catalog_panel_screen.dart';
import '../../../../presentation/views_admin/crud_hymns/hymn_list_screen.dart';

/// Pantalla unificada para administrar el himnario.
///
/// Reune en una sola pantalla con [TabBar] (2 tabs):
/// - **Himnos**: lista editable de himnos con búsqueda y FAB de crear.
///   Reusa [HymnListScreen].
/// - **Catálogos**: panel con sub-tabs (Categorías, Países, Pistas, Fondos).
///   Reusa [CatalogPanelScreen].
///
/// En el AppBar, un [PopupMenuButton] expone opciones de Importar / Exportar /
/// Acerca de catálogos.
class AdminHimnarioScreen extends StatefulWidget {
  const AdminHimnarioScreen({super.key});

  @override
  State<AdminHimnarioScreen> createState() => _AdminHimnarioScreenState();
}

class _AdminHimnarioScreenState extends State<AdminHimnarioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar himnario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Atrás',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (value) {
              // TODO(D8): wire up to importer/exporter when implemented.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Acción: $value (próximamente)')),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload_rounded),
                  title: Text('Importar'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download_rounded),
                  title: Text('Exportar'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Acerca de catálogos'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.library_music_rounded), text: 'Himnos'),
            Tab(icon: Icon(Icons.category_rounded), text: 'Catálogos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HymnListScreen(),
          CatalogPanelScreen(),
        ],
      ),
    );
  }
}
