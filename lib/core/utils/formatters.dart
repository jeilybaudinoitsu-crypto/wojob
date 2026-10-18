import 'package:intl/intl.dart';

String formatTimeOfDay(DateTime? dt, String fallback) {
  if (dt == null) return fallback;
  return DateFormat.Hm().format(dt);
}

String formatDateTime(DateTime dt) {
  return DateFormat('dd MMM yyyy HH:mm').format(dt);
}

String formatDateShort(DateTime dt) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dt);
}

String weekdayLabel(String dbValue) {
  switch (dbValue) {
    case 'L':
      return 'Lunes';
    case 'M':
      return 'Martes';
    case 'Mi':
      return 'Miércoles';
    case 'J':
      return 'Jueves';
    case 'V':
      return 'Viernes';
    case 'S':
      return 'Sábado';
    case 'D':
      return 'Domingo';
    default:
      return dbValue;
  }
}

String formatCoordinates(double lat, double lng) {
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
