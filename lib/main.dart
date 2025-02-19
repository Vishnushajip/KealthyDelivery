import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_delivery/Pages/Cod_page.dart/COD.dart';
import 'package:kealthy_delivery/Pages/Login/SplashScreen.dart';
import 'package:kealthy_delivery/Services/Database_Listener.dart';
import 'package:kealthy_delivery/Services/Location_exit.dart';
import 'Services/Location_Permission.dart';
import 'Riverpod/Request_Overlay.dart';
import 'Services/background_service.dart';
import 'Services/fcm.dart';
import 'Services/location_updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await requestPermissions();
  await NotificationService.instance.initialize();
  final permissionService = PermissionService();
  permissionService.requestPermissions();
  final listenForOrderAssignments = PermissionService();
  listenForOrderAssignments.listenForOrderAssignments();
  DatabaseListener().listenForOrderStatusChanges();
  final overlayService = RequestOverlay();
  // ignore: non_constant_identifier_names
  final LocationpermissionService = LocationPermissionService();
  final isPermissionGranted =
      await LocationpermissionService.requestPermissions();

  if (!isPermissionGranted) {
    SystemNavigator.pop();
    return;
  }
  final isOverlayGranted = await overlayService.requestOverlay();
  if (!isOverlayGranted) {
    SystemNavigator.pop();
  } else {
    final container = ProviderContainer();
    try {
      container.read(paymentProvider);

      print("Data prefetched successfully.");
    } catch (e) {
      print("Error prefetching addresses: $e");
    }
    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final overlayService = RequestOverlay();
      final isOverlayGranted = await overlayService.requestOverlay();
      if (!isOverlayGranted) {
        SystemNavigator.pop();
      }
      if (navigatorKey.currentContext != null) {
        final locationServiceChecker =
            LocationServiceChecker(navigatorKey.currentContext!);
        locationServiceChecker.startChecking();
      } else {
        SystemNavigator.pop();
      }
      LocationUpdater locationUpdater = LocationUpdater();
      await locationUpdater.startLocationUpdates();
    });
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Kealthy Delivery',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}
