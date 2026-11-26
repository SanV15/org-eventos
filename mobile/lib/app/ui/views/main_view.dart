import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:org_eventos/app/ui/views/catalogo_proveedores_view.dart';
import 'package:org_eventos/app/ui/views/catalogo_servicios_view.dart';
import 'package:org_eventos/app/ui/views/check_in_proveedores_view.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/tareas_controller.dart';
import 'agenda_del_dia_view.dart';
import 'eventos_view.dart';
import 'mis_tareas_view.dart';
import 'walkie_view.dart';


class MainNavigationController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  var indiceSeleccionado = 0.obs;

  void cambiarPestana(int indice) {
    indiceSeleccionado.value = indice;
  }

  void abrirMenu() {
    scaffoldKey.currentState?.openDrawer();
  }
}

class MainView extends StatelessWidget {
  final MainNavigationController navCtrl = Get.put(MainNavigationController());
  final AuthController authCtrl = Get.find<AuthController>();
  final TareasController tareasCtrl = Get.put(TareasController());

  late final List<Widget> _pantallas = [
    AgendaDelDiaView(),
    MisTareasView(),
    const WalkieView(),
  ];

  MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: navCtrl.scaffoldKey,
      drawer: _construirDrawer(),
      body: Obx(
        () => IndexedStack(
          index: navCtrl.indiceSeleccionado.value,
          children: _pantallas,
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: navCtrl.indiceSeleccionado.value,
          onDestinationSelected: navCtrl.cambiarPestana,
          backgroundColor: Colors.white,
          elevation: 3,
          indicatorColor: Colors.blueAccent.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today, color: Colors.blueAccent),
              label: 'Agenda Hoy',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: Colors.blueAccent),
              label: 'Itinerario',
            ),
            NavigationDestination(
              icon: Icon(Icons.cell_tower_outlined),
              selectedIcon: Icon(Icons.cell_tower, color: Colors.blueAccent),
              label: 'Walkie-Talkie',
            ),
          ],
        ),
      ),
    );
  }

Widget _construirDrawer() {
  return Drawer(
    child: Obx(() {
      final nombre = authCtrl.nombreUsuario.value.isNotEmpty
          ? authCtrl.nombreUsuario.value
          : 'Personal Operativo';
      final correo = authCtrl.correoUsuario.value;
      final rol = authCtrl.rolUsuario.value;
      final urlFoto = authCtrl.fotoUrl.value;
      final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

      final esGestor = rol == 'Administrador' || rol == 'Coordinador';

      return Column(
        children: [
          // ── Encabezado fijo (sin cambios) ──
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            currentAccountPicture: GestureDetector(
              onTap: () => authCtrl.mostrarOpcionesFoto(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage:
                        urlFoto.isNotEmpty ? NetworkImage(urlFoto) : null,
                    onBackgroundImageError:
                        urlFoto.isNotEmpty ? (_, __) {} : null,
                    child: urlFoto.isEmpty
                        ? Text(
                            inicial,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            accountName: Row(
              children: [
                Flexible(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (rol.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rol,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            accountEmail: Text(correo),
          ),

          // ── Menú con scroll ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Agenda de Hoy'),
                  selected: navCtrl.indiceSeleccionado.value == 0,
                  onTap: () {
                    navCtrl.cambiarPestana(0);
                    Get.back();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Itinerario Operativo'),
                  selected: navCtrl.indiceSeleccionado.value == 1,
                  onTap: () {
                    navCtrl.cambiarPestana(1);
                    Get.back();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cell_tower_outlined),
                  title: const Text('Walkie-Talkie en Vivo'),
                  selected: navCtrl.indiceSeleccionado.value == 2,
                  onTap: () {
                    navCtrl.cambiarPestana(2);
                    Get.back();
                  },
                ),

                if (esGestor) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.event_note_outlined,
                        color: Colors.blueAccent),
                    title: const Text(
                      'Gestión de Cronogramas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Asignar hitos y ver evidencias',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      Get.to(() => const EventosView());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined,
                        color: Colors.blueAccent),
                    title: const Text(
                      'Catálogo de Proveedores',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Servicios, tarifas y disponibilidad',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Get.back();
                      Get.to(() => const CatalogoProveedoresView());
                    },
                  ),
                ],

                ListTile(
                  leading: const Icon(Icons.how_to_reg_outlined,
                      color: Colors.blueAccent),
                  title: const Text(
                    'Check-in de Proveedores',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Control de llegada y entrega en sitio',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => const CheckinProveedoresView());
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.room_service_outlined,
                      color: Colors.blueAccent),
                  title: const Text(
                    'Servicios de la Empresa',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Catálogo interno, descripciones y tarifas',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => CatalogoServiciosView());
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Mi Perfil'),
                  subtitle: Text('Rol asignado: $rol'),
                  onTap: () {
                    Get.back();
                    _mostrarDialogoPerfil();
                  },
                ),
              ],
            ),
          ),

          // ── Cerrar sesión fijo abajo ──
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Get.back();
                authCtrl.logout();
              },
            ),
          ),
        ],
      );
    }),
  );
  }
  void _mostrarDialogoPerfil() {
    Get.defaultDialog(
      title: 'Perfil de Usuario',
      content: Obx(() {
        final nombre = authCtrl.nombreUsuario.value.isNotEmpty
            ? authCtrl.nombreUsuario.value
            : 'Personal Operativo';
        final correo = authCtrl.correoUsuario.value;
        final rol = authCtrl.rolUsuario.value;
        final urlFoto = authCtrl.fotoUrl.value;
        final subiendo = authCtrl.subiendoFoto.value;
        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

        return Column(
          children: [
            GestureDetector(
              onTap: subiendo ? null : () => authCtrl.mostrarOpcionesFoto(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.blueAccent.withOpacity(0.15),
                    backgroundImage: urlFoto.isNotEmpty
                        ? NetworkImage(urlFoto)
                        : null,
                    onBackgroundImageError: urlFoto.isNotEmpty
                        ? (_, __) {}
                        : null,
                    child: urlFoto.isEmpty
                        ? Text(
                            inicial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          )
                        : null,
                  ),
                  if (subiendo)
                    const CircularProgressIndicator(color: Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: subiendo ? null : () => authCtrl.mostrarOpcionesFoto(),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(subiendo ? 'Subiendo...' : 'Cambiar fotografía'),
            ),
            const SizedBox(height: 6),
            Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Text(correo, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Chip(
              label: Text(rol),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
            ),
          ],
        );
      }),
      textConfirm: 'Cerrar',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }
}
