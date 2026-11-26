import 'package:get/get.dart';
import '../controllers/tareas_controller.dart';
import '../controllers/walkie_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Controladores disponibles mientras el usuario esté en el flujo principal
    Get.lazyPut<TareasController>(() => TareasController(), fenix: true);
    Get.lazyPut<WalkieController>(() => WalkieController(), fenix: true);
  }
}
