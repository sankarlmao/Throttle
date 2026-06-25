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
      child: const ThrottleApp(),
    ),
  );
}

class ThrottleApp extends StatelessWidget {
  const ThrottleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Throttle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF627254), // Tactical Olive Green
        scaffoldBackgroundColor: const Color(0xFF121412), // Stealth Matte Black
        cardColor: const Color(0xFF1A1D1A), // Gunmetal Card Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF627254),
          secondary: Color(0xFFC5B494), // Matte Sand
          background: Color(0xFF121412),
          surface: Color(0xFF1A1D1A),
          error: Color(0xFFB85C4C), // Matte Red
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1D1A),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1D1A),
          selectedItemColor: Color(0xFFC5B494), // Sand
          unselectedItemColor: Colors.white30,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF627254), // Tactical Green
            foregroundColor: Colors.white,
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
                backgroundColor: Color(0xFFD97724), // Tactical Orange
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
            activeIcon: Icon(Icons.speed, color: Color(0xFFC5B494)),
            label: 'Ride',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history, color: Color(0xFFC5B494)),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
