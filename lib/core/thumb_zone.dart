/// The thumb-reach model — the deterministic core of ThumbSphere. It scores how comfortably a
/// point on the screen can be reached by the thumb of a one-handed grip, and lays navigation
/// items out along the natural thumb arc. Pure Dart (with a tiny local `Pt` value type), so the
/// ergonomics are unit-testable and reproducible.
library;

import 'dart:math' as math;

/// A minimal 2D point so the core needs no Flutter dependency.
class Pt {
  const Pt(this.x, this.y);
  final double x;
  final double y;

  @override
  bool operator ==(Object other) => other is Pt && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
  @override
  String toString() => 'Pt($x, $y)';
}

enum Hand { left, right }

/// A coarse reach classification, easiest → hardest.
enum ReachZone { easy, ok, stretch, hard }

/// The thumb pivot: the base of the thumb, near a bottom corner of the screen. For a right hand
/// it's the bottom-right; for a left hand the bottom-left. Sits slightly inset and below the
/// bottom edge, matching where the thumb actually roots.
Pt thumbPivot(double width, double height, Hand hand) {
  final x = hand == Hand.right ? width * 0.86 : width * 0.14;
  return Pt(x, height * 1.02);
}

/// The comfortable thumb-arc radius for a screen — roughly 62% of the diagonal-ish reach. Beyond
/// this the thumb has to stretch or the grip must shift.
double comfortRadius(double width, double height) {
  return math.sqrt(width * width + height * height) * 0.62;
}

/// Reachability of a point in [0, 1], where 1 is the easiest thumb reach and 0 is unreachable
/// without shifting grip. It falls off with distance from the pivot, and points *above* the
/// pivot's comfortable arc (the top of the screen) score lowest. Deterministic.
double reachabilityAt(Pt p, double width, double height, Hand hand) {
  final pivot = thumbPivot(width, height, hand);
  final dx = p.x - pivot.x;
  final dy = p.y - pivot.y;
  final dist = math.sqrt(dx * dx + dy * dy);
  final r = comfortRadius(width, height);
  // Linear-ish falloff, clamped. Distance beyond the comfort radius drops toward 0 fast.
  final score = 1 - (dist / r);
  return score.clamp(0.0, 1.0).toDouble();
}

/// Classify a reachability score into a zone.
ReachZone zoneFor(double score) {
  if (score >= 0.72) return ReachZone.easy;
  if (score >= 0.5) return ReachZone.ok;
  if (score >= 0.28) return ReachZone.stretch;
  return ReachZone.hard;
}

/// Lay `count` items out along the thumb arc, at [radiusFactor] × the comfort radius from the
/// pivot, sweeping across the reachable span. Returns screen points, ordered from the outer edge
/// inward, so a curved bottom navigation follows the thumb's natural sweep.
List<Pt> arcPositions(int count, double width, double height, Hand hand, {double radiusFactor = 0.42}) {
  if (count <= 0) return const [];
  final pivot = thumbPivot(width, height, hand);
  final radius = comfortRadius(width, height) * radiusFactor;

  // Sweep angles: for a right hand the arc sweeps from the left (far) up toward the pivot side.
  // Angles are measured from the positive x-axis, going up the screen (negative y).
  final startDeg = hand == Hand.right ? 200.0 : 340.0;
  final endDeg = hand == Hand.right ? 268.0 : 272.0;

  final out = <Pt>[];
  for (var i = 0; i < count; i++) {
    final t = count == 1 ? 0.5 : i / (count - 1);
    final deg = startDeg + (endDeg - startDeg) * t;
    final rad = deg * math.pi / 180.0;
    out.add(Pt(pivot.x + math.cos(rad) * radius, pivot.y + math.sin(rad) * radius));
  }
  return out;
}

/// The fraction of the screen height that is "ambient only" (status/content, no primary
/// actions). The design reserves the top ~40% for ambient use.
const double kAmbientTopFraction = 0.4;

/// True if a point lies in the ambient (non-interactive) top band.
bool isAmbient(Pt p, double height) => p.y < height * kAmbientTopFraction;

/// Round for stable test comparisons.
double round3(double v) => (v * 1000).roundToDouble() / 1000;
