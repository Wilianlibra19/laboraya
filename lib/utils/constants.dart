import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const accent = Color(0xFF03A9F4);
  static const background = Color(0xFFF5F5F5);
  static const white = Colors.white;
  static const black = Colors.black87;
  static const grey = Color(0xFF9E9E9E);
  static const greyLight = Color(0xFFE0E0E0);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const urgent = Color(0xFFFFD700);
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 50.0;
}

class JobStatus {
  static const available = 'available';
  static const accepted = 'accepted';
  static const completed = 'completed';
}

class DocumentType {
  static const cv = 'cv';
  static const dni = 'dni';
  static const certificate = 'certificate';
  static const license = 'license';
  static const workPhoto = 'workPhoto';
}

class CategoryIcons {
  static const Map<String, IconData> icons = {
    'Construcción': Icons.construction,
    'Limpieza': Icons.cleaning_services,
    'Mudanza': Icons.local_shipping,
    'Carga': Icons.inventory_2,
    'Jardinería': Icons.yard,
    'Reparto': Icons.delivery_dining,
    'Técnico': Icons.build,
    'Otros': Icons.work,
  };
}
