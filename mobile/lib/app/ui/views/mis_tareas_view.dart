import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/ui/views/widgets/tareas/lista_tareas_pestana_widget.dart';
import '../../controllers/tareas_controller.dart';
import 'main_view.dart';

class MisTareasView extends StatelessWidget {
  final TareasController controller = Get.isRegistered<TareasController>()
      ? Get.find<TareasController>()
      : Get.put(TareasController());

  MisTareasView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Get.find<MainNavigationController>().abrirMenu(),
          ),
          title: const Text(
            'Itinerario Operativo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          elevation: 0.5,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'En progreso'),
              Tab(text: 'Completadas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              ListaTareasPestanaWidget(
                lista: controller.tareasPendientes,
                mensajeVacio: 'No hay tareas pendientes',
                controller: controller,
              ),
              ListaTareasPestanaWidget(
                lista: controller.tareasEnProgreso,
                mensajeVacio: 'No hay tareas en progreso',
                controller: controller,
              ),
              ListaTareasPestanaWidget(
                lista: controller.tareasCompletadas,
                mensajeVacio: 'No hay tareas completadas',
                controller: controller,
              ),
              ListaTareasPestanaWidget(
                lista: controller.tareasCanceladas,
                mensajeVacio: 'No hay tareas canceladas',
                controller: controller,
              ),
            ],
          );
        }),
      ),
    );
  }
}
