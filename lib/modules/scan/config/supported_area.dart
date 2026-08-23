import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

abstract final class SupportedArea {
  static const LatLng defaultCenter =
      LatLng(7.748893528858868, 125.71679490516968);
  static const double minZoom = 12;
  static const double initialZoom = 16;
  static const double maxZoom = 17;

  static const List<LatLng> boundary = [
    LatLng(7.806560861082189, 125.63986102045375),
    LatLng(7.7956762095560865, 125.63196459707926),
    LatLng(7.794995909431882, 125.66320696782175),
    LatLng(7.741929100320352, 125.64020434320918),
    LatLng(7.743630063488939, 125.68655291518975),
    LatLng(7.722537635330425, 125.67693987803823),
    LatLng(7.68608165649672, 125.68385925522492),
    LatLng(7.671187109483628, 125.70077199774289),
    LatLng(7.680133924592561, 125.7221384442543),
    LatLng(7.66464738677233, 125.72361706165712),
    LatLng(7.6526771983407205, 125.74031302153712),
    LatLng(7.652043473116281, 125.7484123382937),
    LatLng(7.683939805531676, 125.76134282642398),
    LatLng(7.682813265212966, 125.77782564636436),
    LatLng(7.691332653669563, 125.78493031018593),
    LatLng(7.7033721590568724, 125.77945971904207),
    LatLng(7.70808359287765, 125.77164314928795),
    LatLng(7.727444436605209, 125.76759349090968),
    LatLng(7.741435502048624, 125.75246835983998),
    LatLng(7.752139988193796, 125.73589958976596),
    LatLng(7.763325284000295, 125.72782762483625),
    LatLng(7.811671196718009, 125.72624964672997),
    LatLng(7.827604881331258, 125.70919534486183),
    LatLng(7.823215663004752, 125.70694976062417),
    LatLng(7.830551043241702, 125.69462939311539),
    LatLng(7.842360795049566, 125.66801254185408),
    LatLng(7.823328174293252, 125.63906132053842),
    LatLng(7.808920959985727, 125.64199646739989),
  ];

  static final LatLngBounds bounds = LatLngBounds.fromPoints(boundary);

  static bool contains(LatLng point) {
    var isInside = false;

    for (var index = 0, previous = boundary.length - 1;
        index < boundary.length;
        previous = index++) {
      final currentPoint = boundary[index];
      final previousPoint = boundary[previous];

      if (_isOnSegment(point, previousPoint, currentPoint)) {
        return true;
      }

      final crossesLatitude = (currentPoint.latitude > point.latitude) !=
          (previousPoint.latitude > point.latitude);
      if (!crossesLatitude) continue;

      final intersectionLongitude =
          (previousPoint.longitude - currentPoint.longitude) *
                  (point.latitude - currentPoint.latitude) /
                  (previousPoint.latitude - currentPoint.latitude) +
              currentPoint.longitude;
      if (point.longitude < intersectionLongitude) {
        isInside = !isInside;
      }
    }

    return isInside;
  }

  static bool _isOnSegment(LatLng point, LatLng start, LatLng end) {
    const epsilon = 1e-10;
    final crossProduct = (point.latitude - start.latitude) *
            (end.longitude - start.longitude) -
        (point.longitude - start.longitude) * (end.latitude - start.latitude);
    if (crossProduct.abs() > epsilon) return false;

    return point.latitude >=
            (start.latitude < end.latitude ? start.latitude : end.latitude) -
                epsilon &&
        point.latitude <=
            (start.latitude > end.latitude ? start.latitude : end.latitude) +
                epsilon &&
        point.longitude >=
            (start.longitude < end.longitude
                    ? start.longitude
                    : end.longitude) -
                epsilon &&
        point.longitude <=
            (start.longitude > end.longitude
                    ? start.longitude
                    : end.longitude) +
                epsilon;
  }
}
