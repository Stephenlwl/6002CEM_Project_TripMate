import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tripmate_application/services/activity_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'theme_colors.dart';
// Pages
import 'pages/trip_list_page.dart';
import 'pages/auth_page.dart';
import 'pages/packing_list_page.dart';
import 'pages/schedule_page.dart';
import 'pages/map_page.dart';
import 'pages/trip_detail_page.dart';

// Services
import 'services/trip_service.dart';
import 'model/trip_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TripMateApp());
}

class TripMateApp extends StatelessWidget {
  const TripMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripService()),
        ChangeNotifierProvider(create: (_) => ActivityService()),
      ],
      child: MaterialApp(
        title: 'TripMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor:  AppColors.white,
          primaryColor: const Color(0xFFCADEFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFCADEFC),
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC3BEF0),
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => FirebaseAuth.instance.currentUser == null
              ? const AuthPage()
              : const TripListPage(),
          '/tripDetail': (context) {
            final trip = ModalRoute.of(context)!.settings.arguments as Trip;
            return TripDetailPage(trip: trip);
          },
          '/packing': (context) {
            final trip = ModalRoute.of(context)!.settings.arguments as Trip;
            return PackingListPage(trip: trip);
          },
          '/schedule': (context) {
            final trip = ModalRoute.of(context)!.settings.arguments as Trip;
            return SchedulePage(trip: trip);
          },
          '/map': (context) {
            final trip = ModalRoute.of(context)!.settings.arguments as Trip;
            return MapPage(trip: trip);
          },
        },
      ),
    );
  }
}
