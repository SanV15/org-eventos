import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:org_eventos/app/bindings/main_binding.dart';
import 'package:org_eventos/app/ui/views/login_view.dart';
import 'package:org_eventos/app/ui/views/main_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/providers/auth_provider.dart';

class AuthController extends GetxController {
  final AuthProvider _provider = AuthProvider();

  final correoController = TextEditingController();
  final contraseniaController = TextEditingController();

  var isLoading = false.obs;
  var subiendoFoto = false.obs;

  // Datos reactivos del usuario logueado
  var nombreUsuario = ''.obs;
  var correoUsuario = ''.obs;
  var rolUsuario = ''.obs;
  var fotoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    verificarSesionActiva();
  }

  Future<void> verificarSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) return;

    if (!_tokenExpirado(token)) {
      await cargarPerfilLocal();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => MainView(), binding: MainBinding());
      });
    } else {
      await prefs.remove('jwt_token');
      await prefs.remove('user_nombre');
      await prefs.remove('user_correo');
      await prefs.remove('user_rol');
      await prefs.remove('user_foto');
    }
  }

  Future<void> cargarPerfilLocal() async {
    final prefs = await SharedPreferences.getInstance();
    nombreUsuario.value = prefs.getString('user_nombre') ?? '';
    correoUsuario.value = prefs.getString('user_correo') ?? '';
    rolUsuario.value = prefs.getString('user_rol') ?? '';
    fotoUrl.value = prefs.getString('user_foto') ?? '';
  }

  bool _tokenExpirado(String token) {
    final claims = _decodificarJwt(token);
    if (claims.isEmpty) return true;

    final exp = claims['exp'];
    if (exp == null) return false;

    final fechaExp = DateTime.fromMillisecondsSinceEpoch(
      (exp as num).toInt() * 1000,
    );
    return DateTime.now().isAfter(fechaExp);
  }

  Map<String, dynamic> _decodificarJwt(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return {};
      final payload = base64Url.normalize(partes[1]);
      final jsonStr = utf8.decode(base64Url.decode(payload));
      return jsonDecode(jsonStr);
    } catch (_) {
      return {};
    }
  }

  void login() async {
    if (correoController.text.isEmpty || contraseniaController.text.isEmpty) {
      Get.snackbar('Atención', 'Ingresa tu correo y contraseña');
      return;
    }

    try {
      isLoading(true);
      final token = await _provider.login(
        correoController.text.trim(),
        contraseniaController.text.trim(),
      );

      if (token != null) {
        final claims = _decodificarJwt(token);

        final nombre = claims['nombre_completo'] ?? 'Usuario';
        final correo = claims['email'] ?? correoController.text.trim();
        final rol =
            claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
            claims['role'] ??
            'Staff';
        final foto = claims['foto_url'] ?? '';

        nombreUsuario.value = nombre;
        correoUsuario.value = correo;
        rolUsuario.value = rol;
        fotoUrl.value = foto;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_nombre', nombre);
        await prefs.setString('user_correo', correo);
        await prefs.setString('user_rol', rol);
        await prefs.setString('user_foto', foto);

        Get.offAll(() => MainView(), binding: MainBinding());

        Get.snackbar(
          '¡Bienvenido, $nombre!',
          'Sesión iniciada como $rol',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('ERROR AL LOGUEAR: $e');
      Get.snackbar('Error', 'Credenciales incorrectas o problemas de conexión');
    } finally {
      isLoading(false);
    }
  }

  void mostrarOpcionesFoto() {
    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Actualizar foto de perfil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Tomar fotografía'),
                  onTap: () {
                    Get.back();
                    _procesarYSubirFoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Get.back();
                    _procesarYSubirFoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _procesarYSubirFoto(ImageSource origen) async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: origen,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (imagen == null) return;

    try {
      subiendoFoto(true);
      final nuevaUrl = await _provider.subirFotoPerfil(imagen.path);

      if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
        fotoUrl.value = nuevaUrl;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_foto', nuevaUrl);

        Get.snackbar(
          'Foto actualizada',
          'Tu imagen de perfil se guardó correctamente.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', 'No se pudo subir la imagen');
      }
    } catch (e) {
      print('ERROR AL SUBIR FOTO: $e');
      Get.snackbar('Error', 'Problema de conexión al subir la fotografía');
    } finally {
      subiendoFoto(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_nombre');
    await prefs.remove('user_correo');
    await prefs.remove('user_rol');
    await prefs.remove('user_foto');

    nombreUsuario.value = '';
    correoUsuario.value = '';
    rolUsuario.value = '';
    fotoUrl.value = '';
    correoController.clear();
    contraseniaController.clear();

    Get.offAll(() => LoginView());
  }

  @override
  void onClose() {
    correoController.dispose();
    contraseniaController.dispose();
    super.onClose();
  }
}
