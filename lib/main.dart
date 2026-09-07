import 'package:flutter/material.dart';
import 'core/thumb_zone.dart';

void main() => runApp(const ThumbSphereApp());

class ThumbSphereApp extends StatelessWidget {
  const ThumbSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThumbSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0A0B10)),
      home: const ThumbScreen(),
    );
  }
}

const _navItems = [
  (Icons.home_rounded, 'Home'),
  (Icons.chat_bubble_rounded, 'Chats'),
  (Icons.explore_rounded, 'Explore'),
  (Icons.favorite_rounded, 'Saved'),
  (Icons.person_rounded, 'You'),
];

class ThumbScreen extends StatefulWidget {
  const ThumbScreen({super.key});

  @override
  State<ThumbScreen> createState() => _ThumbScreenState();
}

class _ThumbScreenState extends State<ThumbScreen> {
  Hand _hand = Hand.right;
  bool _heatmap = false;
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              return Stack(
                children: [
                  if (_heatmap) Positioned.fill(child: CustomPaint(painter: _HeatmapPainter(_hand))),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: h * kAmbientTopFraction,
                    child: _Ambient(active: _navItems[_active].$2),
                  ),
                  Positioned(
                    top: h * kAmbientTopFraction,
                    left: 0,
                    right: 0,
                    bottom: h * 0.22,
                    child: const _Content(),
                  ),
                  ..._buildArcNav(w, h),
                  Positioned(
                    bottom: 12,
                    left: _hand == Hand.right ? 12 : null,
                    right: _hand == Hand.right ? null : 12,
                    child: _Controls(
                      hand: _hand,
                      heatmap: _heatmap,
                      onHand: () => setState(() => _hand = _hand == Hand.right ? Hand.left : Hand.right),
                      onHeatmap: () => setState(() => _heatmap = !_heatmap),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildArcNav(double w, double h) {
    final positions = arcPositions(_navItems.length, w, h, _hand, radiusFactor: 0.5);
    return [
      for (var i = 0; i < _navItems.length; i++)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          left: positions[i].x - 30,
          top: positions[i].y - 30,
          child: _NavBubble(
            icon: _navItems[i].$1,
            label: _navItems[i].$2,
            active: i == _active,
            onTap: () => setState(() => _active = i),
          ),
        ),
    ];
  }
}

class _Ambient extends StatelessWidget {
  const _Ambient({required this.active});
  final String active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1740), Color(0xFF0A0B10)]),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ThumbSphere', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 4),
              const Text('Ambient zone — glanceable only', style: TextStyle(color: Color(0xFF8891A6), fontSize: 12.5)),
              const Spacer(),
              Text(active, style: const TextStyle(color: Color(0xFFB9A7FF), fontSize: 26, fontWeight: FontWeight.w700)),
              const Text('Everything you can tap lives in the thumb arc below', style: TextStyle(color: Color(0xFF8891A6), fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        for (final t in ['Reachable list item', 'Swipe-friendly card', 'Comfortable tap target', 'One-handed row'])
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF141622), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x22FFFFFF))),
            child: Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: Color(0x337C6CFF), child: Icon(Icons.bolt, size: 16, color: Color(0xFFB9A7FF))),
                const SizedBox(width: 12),
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavBubble extends StatelessWidget {
  const _NavBubble({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? const LinearGradient(colors: [Color(0xFF7C6CFF), Color(0xFF34D9C8)]) : null,
          color: active ? null : const Color(0xFF181B2A),
          border: Border.all(color: active ? Colors.transparent : const Color(0x33FFFFFF)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: active ? 20 : 10, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.hand, required this.heatmap, required this.onHand, required this.onHeatmap});
  final Hand hand;
  final bool heatmap;
  final VoidCallback onHand;
  final VoidCallback onHeatmap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(hand == Hand.right ? Icons.back_hand : Icons.front_hand, hand == Hand.right ? 'Right' : 'Left', onHand),
        const SizedBox(width: 8),
        _pill(Icons.gradient, heatmap ? 'Heatmap on' : 'Heatmap', onHeatmap, on: heatmap),
      ],
    );
  }

  Widget _pill(IconData icon, String label, VoidCallback onTap, {bool on = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0x337C6CFF) : const Color(0xCC141622),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(children: [Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]),
      ),
    );
  }
}

/// Paints a translucent reachability heatmap: green where the thumb reaches easily, fading to
/// red where it can't. Purely illustrative of the model.
class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter(this.hand);
  final Hand hand;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 26.0;
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final s = reachabilityAt(Pt(x + cell / 2, y + cell / 2), size.width, size.height, hand);
        final color = Color.lerp(const Color(0xFFF87171), const Color(0xFF34D399), s)!.withOpacity(0.22);
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) => old.hand != hand;
}
