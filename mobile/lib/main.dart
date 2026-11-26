import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/bloc/notificaciones/notificaciones_bloc.dart';
import 'app/bloc/notificaciones/notificaciones_event.dart';
import 'app/ui/views/login_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bypass de certificados SSL locales
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacionesBloc = Get.put(
      NotificacionesBloc()..add(InicializarNotificacionesEvent()),
      permanent: true,
    );

    return BlocProvider.value(
      value: notificacionesBloc,
      child: GetMaterialApp(
        title: 'OrgEventos Staff',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        initialBinding: InitialBinding(),
        home: LoginView(),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
