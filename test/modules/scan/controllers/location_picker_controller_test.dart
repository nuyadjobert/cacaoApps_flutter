import 'package:cacao_apps/modules/scan/config/supported_area.dart';
import 'package:cacao_apps/modules/scan/controllers/location_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('manual selection accepts and retains a supported coordinate', () {
    final controller = LocationPickerController();

    final confirmed = controller.confirmManualLocation(
      SupportedArea.defaultCenter,
    );

    expect(confirmed, isTrue);
    expect(controller.pickedLatLng, SupportedArea.defaultCenter);
    expect(controller.needsManualPick, isFalse);
    expect(controller.isManuallyPicked, isTrue);
  });

  test('manual selection rejects a coordinate outside the polygon', () {
    final controller = LocationPickerController();

    final confirmed = controller.confirmManualLocation(
      const LatLng(7.9, 125.8),
    );

    expect(confirmed, isFalse);
    expect(controller.pickedLatLng, isNull);
    expect(controller.needsManualPick, isTrue);
    expect(controller.error, isNotNull);
  });
}
