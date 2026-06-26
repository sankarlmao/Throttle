import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';

class PaddockScreen extends StatelessWidget {
  const PaddockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        // Calculate dynamic stats
        final double gpLevelProgress = (provider.lifetimeDistanceKm % 50.0) / 50.0;
        final int gpLevel = 1 + (provider.lifetimeDistanceKm / 50.0).floor();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              "Rider Paddock",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note, color: Color(0xFFFF5722)),
                onPressed: () => _showCustomizeSheet(context, provider),
                tooltip: "Edit Profile",
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Racer Card (Inspired by the rightmost reference photo)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E221E), Color(0xFF0F110F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Giant Helmet Custom Painter
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: provider.helmetColor.withOpacity(0.05),
                                  border: Border.all(
                                    color: provider.helmetColor.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(110, 110),
                                painter: _RiderHelmetPainter(
                                  helmetColor: provider.helmetColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Rider Flag & Name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCountryFlag(provider.riderCountry),
                            const SizedBox(width: 10),
                            Text(
                              provider.riderName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "THROTTLE RACING TEAM · ${provider.currentClass.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 16),

                        // GP Points & Stats Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildRacerStat("TOTAL POINTS", "${provider.riderPoints} PTS", const Color(0xFFFF5722)),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildRacerStat("AVERAGE SPEED", "${provider.avgSpeedKmh.toStringAsFixed(1)} km/h", Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Career Progression Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161916),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "GP CAREER LEVEL",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              "LVL $gpLevel",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: gpLevelProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ride ${((1.0 - gpLevelProgress) * 50).toStringAsFixed(1)} more km to level up",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.3),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Grid of Career Standing details
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildPaddockGridCard("SPRINT STATUS", "P2 (+3 PTS)", Icons.electric_bolt, const Color(0xFFFFD54F)),
                      _buildPaddockGridCard("MAIN RACE STATUS", "P2 (+7 PTS)", Icons.flag_rounded, const Color(0xFF81C784)),
                      _buildPaddockGridCard("LIFETIME ODO", "${provider.lifetimeDistanceKm.toStringAsFixed(1)} KM", Icons.motorcycle, Colors.white70),
                      _buildPaddockGridCard("GP STANDINGS", "#14 WORLD", Icons.emoji_events, const Color(0xFF64B5F6)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Customize Button
                  ElevatedButton.icon(
                    onPressed: () => _showCustomizeSheet(context, provider),
                    icon: const Icon(Icons.tune),
                    label: const Text("CUSTOMIZE RACER PROFILE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.helmetColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountryFlag(String country) {
    if (country.toLowerCase() == "indonesia") {
      return Container(
        width: 24,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Column(
          children: [
            Expanded(child: Container(color: Colors.red)),
            Expanded(child: Container(color: Colors.white)),
          ],
        ),
      );
    } else if (country.toLowerCase() == "united kingdom") {
      // simple representation
      return const Text("🇬🇧", style: TextStyle(fontSize: 20));
    } else if (country.toLowerCase() == "italy") {
      return Container(
        width: 24,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(child: Container(color: Colors.green)),
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: Colors.red)),
          ],
        ),
      );
    } else if (country.toLowerCase() == "spain") {
      return Container(
        width: 24,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Column(
          children: [
            Expanded(flex: 1, child: Container(color: Colors.red)),
            Expanded(flex: 2, child: Container(color: Colors.yellow)),
            Expanded(flex: 1, child: Container(color: Colors.red)),
          ],
        ),
      );
    } else if (country.toLowerCase() == "usa") {
      return const Text("🇺🇸", style: TextStyle(fontSize: 20));
    } else {
      return const Text("🏁", style: TextStyle(fontSize: 20));
    }
  }

  Widget _buildRacerStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaddockGridCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161916),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Customize profile dialog sheet
  void _showCustomizeSheet(BuildContext context, RideProvider provider) {
    final nameController = TextEditingController(text: provider.riderName);
    String selectedCountry = provider.riderCountry;
    Color selectedColor = provider.helmetColor;

    final List<Map<String, dynamic>> countries = [
      {"name": "Indonesia", "flag": "🇮🇩"},
      {"name": "United Kingdom", "flag": "🇬🇧"},
      {"name": "Italy", "flag": "🇮🇹"},
      {"name": "Spain", "flag": "🇪🇸"},
      {"name": "USA", "flag": "🇺🇸"},
    ];

    final List<Color> helmetColors = [
      const Color(0xFFFF5722), // MotoGP Orange
      const Color(0xFFE10600), // F1 Red
      const Color(0xFF76FF03), // Kawasaki Lime Green
      const Color(0xFF2979FF), // Yamaha Blue
      const Color(0xFFFFEA00), // Ducati Yellow
      const Color(0xFF757575), // Carbon Gray
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161916),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "CUSTOMIZE GP PROFILE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Rider Name Input
                  const Text(
                    "RIDER NAME",
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      fillColor: Colors.white.withOpacity(0.04),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: selectedColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Country Selection
                  const Text(
                    "REPRESENTING COUNTRY",
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: countries.map((c) {
                      final isSelected = selectedCountry == c["name"];
                      return GestureDetector(
                        onTap: () {
                          setStateSheet(() {
                            selectedCountry = c["name"];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.white10,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "${c["flag"]} ${c["name"].substring(0, 3).toUpperCase()}",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Helmet Color Selection
                  const Text(
                    "TEAM COLOR (HELMET & BIKE)",
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: helmetColors.map((color) {
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setStateSheet(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // Save Profile Button
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        provider.updateRiderProfile(
                          name: name,
                          color: selectedColor,
                          country: selectedCountry,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("GP profile updated successfully"),
                            backgroundColor: selectedColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "SAVE CHANGES",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Draw a beautiful F1/MotoGP racing helmet
class _RiderHelmetPainter extends CustomPainter {
  final Color helmetColor;

  _RiderHelmetPainter({required this.helmetColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2.2;

    // 1. Helmet Outer Shell (Glossy Finish)
    final Paint shellPaint = Paint()
      ..color = helmetColor
      ..style = PaintingStyle.fill;
    
    // Draw base helmet shape
    final Path shellPath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy - 5), radius: radius),
        -pi * 0.9,
        pi * 1.8,
        true,
      )
      ..lineTo(cx + radius * 0.8, cy + radius * 0.6)
      ..lineTo(cx + radius * 0.45, cy + radius * 0.9) // chin bar right
      ..lineTo(cx - radius * 0.45, cy + radius * 0.9) // chin bar left
      ..lineTo(cx - radius * 0.8, cy + radius * 0.6)
      ..close();
    canvas.drawPath(shellPath, shellPaint);

    // 2. Carbon Fiber/Dark Aero Spoiler & Bottom Trim
    final Paint trimPaint = Paint()
      ..color = const Color(0xFF1E211E)
      ..style = PaintingStyle.fill;
    
    // Bottom Trim
    final Path trimPath = Path()
      ..moveTo(cx - radius * 0.5, cy + radius * 0.8)
      ..lineTo(cx + radius * 0.5, cy + radius * 0.8)
      ..lineTo(cx + radius * 0.42, cy + radius * 0.94)
      ..lineTo(cx - radius * 0.42, cy + radius * 0.94)
      ..close();
    canvas.drawPath(trimPath, trimPaint);

    // Rear Aero Spoiler
    final Path spoilerPath = Path()
      ..moveTo(cx - radius * 0.85, cy - radius * 0.2)
      ..quadraticBezierTo(cx - radius, cy - radius * 0.6, cx - radius * 0.4, cy - radius * 0.8)
      ..lineTo(cx - radius * 0.6, cy - radius * 0.4)
      ..close();
    canvas.drawPath(spoilerPath, trimPaint);

    // 3. Helmet Graphic Accent Stripes
    final Paint stripePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Path stripePath = Path()
      ..moveTo(cx + radius * 0.2, cy - radius * 0.85)
      ..quadraticBezierTo(cx + radius * 0.6, cy - radius * 0.5, cx + radius * 0.75, cy + radius * 0.2)
      ..lineTo(cx + radius * 0.62, cy + radius * 0.25)
      ..quadraticBezierTo(cx + radius * 0.5, cy - radius * 0.35, cx + radius * 0.1, cy - radius * 0.75)
      ..close();
    canvas.drawPath(stripePath, stripePaint);

    // 4. Large Dark Racing Visor
    final Paint visorPaint = Paint()
      ..color = const Color(0xFF121212)
      ..style = PaintingStyle.fill;
    
    final Path visorPath = Path()
      ..moveTo(cx - radius * 0.72, cy - radius * 0.1)
      ..quadraticBezierTo(cx, cy - radius * 0.25, cx + radius * 0.72, cy - radius * 0.1) // visor top
      ..quadraticBezierTo(cx + radius * 0.78, cy + radius * 0.2, cx + radius * 0.6, cy + radius * 0.38)
      ..quadraticBezierTo(cx, cy + radius * 0.48, cx - radius * 0.6, cy + radius * 0.38) // visor bottom
      ..quadraticBezierTo(cx - radius * 0.78, cy + radius * 0.2, cx - radius * 0.72, cy - radius * 0.1)
      ..close();
    canvas.drawPath(visorPath, visorPaint);

    // Visor border trim
    final Paint visorBorder = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(visorPath, visorBorder);

    // Visor tear-off peg pivots
    final Paint pegPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - radius * 0.65, cy + radius * 0.15), 3, pegPaint);
    canvas.drawCircle(Offset(cx + radius * 0.65, cy + radius * 0.15), 3, pegPaint);

    // 5. Visor Reflection/Glare Highlight (gives it that premium glass/shiny visor look)
    final Paint reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final Path reflectionPath = Path()
      ..moveTo(cx - radius * 0.5, cy - radius * 0.05)
      ..quadraticBezierTo(cx, cy - radius * 0.15, cx + radius * 0.5, cy - radius * 0.05)
      ..lineTo(cx + radius * 0.4, cy + radius * 0.05)
      ..quadraticBezierTo(cx, cy - radius * 0.05, cx - radius * 0.4, cy + radius * 0.05)
      ..close();
    canvas.drawPath(reflectionPath, reflectionPaint);

    // 6. Chin ventilation intake grill (Racing detail)
    final Paint grillPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 8, cy + radius * 0.6, cx + 8, cy + radius * 0.76),
        const Radius.circular(2),
      ),
      grillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiderHelmetPainter oldDelegate) {
    return oldDelegate.helmetColor != helmetColor;
  }
}
