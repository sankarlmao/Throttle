import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ride_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => RideProvider(),
      child: const MotoTrackApp(),
    ),
  );
}

class MotoTrackApp extends StatelessWidget {
  const MotoTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF64B5F6),
        scaffoldBackgroundColor: const Color(0xFF111111),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64B5F6),
          secondary: Color(0xFFFF9800), // Amber
          background: Color(0xFF111111),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFF44336), // Red
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF64B5F6),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64B5F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Prevent switching tabs while actively riding to avoid disruption
    final isRiding = Provider.of<RideProvider>(context, listen: true).isRiding;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (isRiding && index != 0) {
            // Warn user if they try to leave the active ride tab
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot view history while a ride is active."),
                backgroundColor: Color(0xFFFF9800),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            activeIcon: Icon(Icons.speed, color: Color(0xFF64B5F6)),
            label: 'Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history, color: Color(0xFF64B5F6)),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
