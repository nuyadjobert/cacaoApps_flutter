import 'package:cacao_apps/modules/scan/config/supported_area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('SupportedArea.contains', () {
    test('accepts the configured default center', () {
      expect(SupportedArea.contains(SupportedArea.defaultCenter), isTrue);
    });

    test('accepts a point on the boundary', () {
      expect(SupportedArea.contains(SupportedArea.boundary.first), isTrue);
    });

    test('rejects a point outside the polygon but inside its bounding box', () {
      const point = LatLng(7.835, 125.64);

      expect(SupportedArea.bounds.contains(point), isTrue);
      expect(SupportedArea.contains(point), isFalse);
    });

    test('rejects a distant point', () {
      expect(
        SupportedArea.contains(const LatLng(7.9, 125.8)),
        isFalse,
      );
    });
  });
}
