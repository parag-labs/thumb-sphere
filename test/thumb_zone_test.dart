import 'package:flutter_test/flutter_test.dart';
import 'package:thumb_sphere/core/thumb_zone.dart';

const w = 390.0;
const h = 844.0;

void main() {
  group('reachabilityAt', () {
    test('a point near the pivot is easier to reach than the top of the screen', () {
      final nearPivot = reachabilityAt(const Pt(340, 800), w, h, Hand.right);
      final topLeft = reachabilityAt(const Pt(20, 40), w, h, Hand.right);
      expect(nearPivot, greaterThan(topLeft));
    });

    test('scores are always within [0, 1]', () {
      for (var y = 0.0; y <= h; y += 120) {
        for (var x = 0.0; x <= w; x += 130) {
          final s = reachabilityAt(Pt(x, y), w, h, Hand.right);
          expect(s, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('handedness mirrors reachability across the screen', () {
      final rightBottomRight = reachabilityAt(const Pt(360, 820), w, h, Hand.right);
      final leftBottomLeft = reachabilityAt(const Pt(30, 820), w, h, Hand.left);
      expect(round3(rightBottomRight), round3(leftBottomLeft));
    });

    test('the top-left corner is hard for a right-handed grip', () {
      expect(zoneFor(reachabilityAt(const Pt(10, 20), w, h, Hand.right)), ReachZone.hard);
    });

    test('is deterministic', () {
      expect(reachabilityAt(const Pt(200, 600), w, h, Hand.right), reachabilityAt(const Pt(200, 600), w, h, Hand.right));
    });
  });

  group('zoneFor', () {
    test('maps the score range to zones in order', () {
      expect(zoneFor(0.9), ReachZone.easy);
      expect(zoneFor(0.6), ReachZone.ok);
      expect(zoneFor(0.35), ReachZone.stretch);
      expect(zoneFor(0.1), ReachZone.hard);
    });
  });

  group('arcPositions', () {
    test('returns one point per item, all on-screen-ish and in the lower half', () {
      final pts = arcPositions(5, w, h, Hand.right);
      expect(pts.length, 5);
      for (final p in pts) {
        expect(p.y, greaterThan(h * 0.4)); // primary actions live below the ambient band
      }
    });

    test('items sit in reachable zones (not hard)', () {
      for (final p in arcPositions(5, w, h, Hand.right)) {
        final z = zoneFor(reachabilityAt(p, w, h, Hand.right));
        expect(z == ReachZone.hard, isFalse, reason: 'nav items must be comfortably reachable');
      }
    });

    test('handles edge counts', () {
      expect(arcPositions(0, w, h, Hand.right), isEmpty);
      expect(arcPositions(1, w, h, Hand.right).length, 1);
    });

    test('is deterministic', () {
      expect(arcPositions(4, w, h, Hand.left), arcPositions(4, w, h, Hand.left));
    });
  });

  group('ambient band', () {
    test('the top 40% is ambient (no primary actions)', () {
      expect(isAmbient(const Pt(100, 100), h), isTrue);
      expect(isAmbient(const Pt(100, 800), h), isFalse);
    });
  });
}
