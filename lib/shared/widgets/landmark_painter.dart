import 'package:flutter/material.dart';

class EiffelTowerPainter extends CustomPainter {
  final Color color;

  EiffelTowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Eiffel Tower silhouette path
    final path = Path();

    // Left base arch leg
    path.moveTo(w * 0.15, h * 0.95);
    path.quadraticBezierTo(w * 0.25, h * 0.8, w * 0.35, h * 0.7);

    // Right base arch leg
    path.moveTo(w * 0.85, h * 0.95);
    path.quadraticBezierTo(w * 0.75, h * 0.8, w * 0.65, h * 0.7);

    // Connection base platform
    path.moveTo(w * 0.3, h * 0.7);
    path.lineTo(w * 0.7, h * 0.7);

    // Left middle leg
    path.moveTo(w * 0.35, h * 0.7);
    path.quadraticBezierTo(w * 0.42, h * 0.5, w * 0.45, h * 0.35);

    // Right middle leg
    path.moveTo(w * 0.65, h * 0.7);
    path.quadraticBezierTo(w * 0.58, h * 0.5, w * 0.55, h * 0.35);

    // Middle platform
    path.moveTo(w * 0.4, h * 0.35);
    path.lineTo(w * 0.6, h * 0.35);

    // Tapering top spire
    path.moveTo(w * 0.46, h * 0.35);
    path.lineTo(w * 0.49, h * 0.1);
    path.lineTo(w * 0.5, h * 0.05); // Peak tip
    path.lineTo(w * 0.51, h * 0.1);
    path.lineTo(w * 0.54, h * 0.35);

    // Cross brace diagonals
    // Base cross
    path.moveTo(w * 0.35, h * 0.95);
    path.lineTo(w * 0.4, h * 0.7);
    path.moveTo(w * 0.65, h * 0.95);
    path.lineTo(w * 0.6, h * 0.7);

    // Middle cross
    path.moveTo(w * 0.42, h * 0.7);
    path.lineTo(w * 0.48, h * 0.35);
    path.moveTo(w * 0.58, h * 0.7);
    path.lineTo(w * 0.52, h * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SagradaFamiliaPainter extends CustomPainter {
  final Color color;

  SagradaFamiliaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path();

    // Four main vertical spires
    // Spire 1 (Far Left)
    path.moveTo(w * 0.2, h * 0.9);
    path.lineTo(w * 0.25, h * 0.4);
    path.lineTo(w * 0.28, h * 0.3);
    path.lineTo(w * 0.31, h * 0.4);
    path.lineTo(w * 0.36, h * 0.9);

    // Spire 2 (Center-Left taller)
    path.moveTo(w * 0.32, h * 0.9);
    path.lineTo(w * 0.37, h * 0.2);
    path.lineTo(w * 0.4, h * 0.1);
    path.lineTo(w * 0.43, h * 0.2);
    path.lineTo(w * 0.48, h * 0.9);

    // Spire 3 (Center-Right taller)
    path.moveTo(w * 0.52, h * 0.9);
    path.lineTo(w * 0.57, h * 0.2);
    path.lineTo(w * 0.6, h * 0.1);
    path.lineTo(w * 0.63, h * 0.2);
    path.lineTo(w * 0.68, h * 0.9);

    // Spire 4 (Far Right)
    path.moveTo(w * 0.64, h * 0.9);
    path.lineTo(w * 0.69, h * 0.4);
    path.lineTo(w * 0.72, h * 0.3);
    path.lineTo(w * 0.75, h * 0.4);
    path.lineTo(w * 0.8, h * 0.9);

    // Connecting cathedral body & portals
    path.moveTo(w * 0.1, h * 0.9);
    path.lineTo(w * 0.9, h * 0.9);

    // Archway portal 1
    path.moveTo(w * 0.32, h * 0.9);
    path.quadraticBezierTo(w * 0.4, h * 0.7, w * 0.48, h * 0.9);

    // Archway portal 2
    path.moveTo(w * 0.52, h * 0.9);
    path.quadraticBezierTo(w * 0.6, h * 0.7, w * 0.68, h * 0.9);

    // Spires cross highlights
    path.moveTo(w * 0.28, h * 0.3);
    path.lineTo(w * 0.28, h * 0.25);
    path.moveTo(w * 0.26, h * 0.27);
    path.lineTo(w * 0.3, h * 0.27);

    path.moveTo(w * 0.4, h * 0.1);
    path.lineTo(w * 0.4, h * 0.04);
    path.moveTo(w * 0.38, h * 0.07);
    path.lineTo(w * 0.42, h * 0.07);

    path.moveTo(w * 0.6, h * 0.1);
    path.lineTo(w * 0.6, h * 0.04);
    path.moveTo(w * 0.58, h * 0.07);
    path.lineTo(w * 0.62, h * 0.07);

    path.moveTo(w * 0.72, h * 0.3);
    path.lineTo(w * 0.72, h * 0.25);
    path.moveTo(w * 0.7, h * 0.27);
    path.lineTo(w * 0.74, h * 0.27);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BigBenPainter extends CustomPainter {
  final Color color;

  BigBenPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path();

    // Left vertical tower edge
    path.moveTo(w * 0.35, h * 0.95);
    path.lineTo(w * 0.35, h * 0.4);

    // Right vertical tower edge
    path.moveTo(w * 0.65, h * 0.95);
    path.lineTo(w * 0.65, h * 0.4);

    // Base connector horizontal lines
    path.moveTo(w * 0.35, h * 0.8);
    path.lineTo(w * 0.65, h * 0.8);
    path.moveTo(w * 0.35, h * 0.6);
    path.lineTo(w * 0.65, h * 0.6);

    // Clock section box
    path.moveTo(w * 0.3, h * 0.4);
    path.lineTo(w * 0.7, h * 0.4);
    path.lineTo(w * 0.7, h * 0.22);
    path.lineTo(w * 0.3, h * 0.22);
    path.lineTo(w * 0.3, h * 0.4);

    // Clock Face circle outline
    canvas.drawCircle(Offset(w * 0.5, h * 0.31), w * 0.14, paint);

    // Clock hands details
    path.moveTo(w * 0.5, h * 0.31);
    path.lineTo(w * 0.5, h * 0.24); // Minute hand
    path.moveTo(w * 0.5, h * 0.31);
    path.lineTo(w * 0.56, h * 0.34); // Hour hand

    // Pyramid roof spires
    path.moveTo(w * 0.3, h * 0.22);
    path.lineTo(w * 0.5, h * 0.05); // Top spire point
    path.lineTo(w * 0.7, h * 0.22);

    // Vertical top needle
    path.moveTo(w * 0.5, h * 0.05);
    path.lineTo(w * 0.5, h * 0.01);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PagodaPainter extends CustomPainter {
  final Color color;
  PagodaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Pagoda tier 1 (Bottom base)
    path.moveTo(w * 0.1, h * 0.9);
    path.lineTo(w * 0.9, h * 0.9);
    path.lineTo(w * 0.8, h * 0.7);
    path.lineTo(w * 0.2, h * 0.7);
    path.close();

    // Pagoda tier 2
    path.moveTo(w * 0.2, h * 0.7);
    path.quadraticBezierTo(w * 0.1, h * 0.68, w * 0.15, h * 0.64);
    path.moveTo(w * 0.8, h * 0.7);
    path.quadraticBezierTo(w * 0.9, h * 0.68, w * 0.85, h * 0.64);
    
    path.moveTo(w * 0.25, h * 0.7);
    path.lineTo(w * 0.75, h * 0.7);
    path.lineTo(w * 0.68, h * 0.45);
    path.lineTo(w * 0.32, h * 0.45);
    path.close();

    // Pagoda tier 3
    path.moveTo(w * 0.32, h * 0.45);
    path.quadraticBezierTo(w * 0.22, h * 0.43, w * 0.27, h * 0.39);
    path.moveTo(w * 0.68, h * 0.45);
    path.quadraticBezierTo(w * 0.78, h * 0.43, w * 0.73, h * 0.39);

    path.moveTo(w * 0.35, h * 0.45);
    path.lineTo(w * 0.65, h * 0.45);
    path.lineTo(w * 0.58, h * 0.22);
    path.lineTo(w * 0.42, h * 0.22);
    path.close();

    // Pagoda tip
    path.moveTo(w * 0.42, h * 0.22);
    path.quadraticBezierTo(w * 0.35, h * 0.20, w * 0.38, h * 0.17);
    path.moveTo(w * 0.58, h * 0.22);
    path.quadraticBezierTo(w * 0.65, h * 0.20, w * 0.62, h * 0.17);

    path.moveTo(w * 0.5, h * 0.22);
    path.lineTo(w * 0.5, h * 0.05);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TajMahalPainter extends CustomPainter {
  final Color color;
  TajMahalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.15, h * 0.9);
    path.lineTo(w * 0.85, h * 0.9);
    path.lineTo(w * 0.85, h * 0.82);
    path.lineTo(w * 0.15, h * 0.82);
    path.close();

    path.moveTo(w * 0.3, h * 0.82);
    path.lineTo(w * 0.7, h * 0.82);
    path.lineTo(w * 0.7, h * 0.48);
    path.lineTo(w * 0.3, h * 0.48);
    path.close();

    // Center Dome
    path.moveTo(w * 0.38, h * 0.48);
    path.cubicTo(w * 0.35, h * 0.3, w * 0.45, h * 0.2, w * 0.5, h * 0.15);
    path.cubicTo(w * 0.55, h * 0.2, w * 0.65, h * 0.3, w * 0.62, h * 0.48);

    path.moveTo(w * 0.5, h * 0.15);
    path.lineTo(w * 0.5, h * 0.08);

    // Left Minaret
    path.moveTo(w * 0.18, h * 0.82);
    path.lineTo(w * 0.18, h * 0.3);
    path.moveTo(w * 0.14, h * 0.3);
    path.lineTo(w * 0.22, h * 0.3);
    path.lineTo(w * 0.18, h * 0.24);
    path.lineTo(w * 0.14, h * 0.3);

    // Right Minaret
    path.moveTo(w * 0.82, h * 0.82);
    path.lineTo(w * 0.82, h * 0.3);
    path.moveTo(w * 0.78, h * 0.3);
    path.lineTo(w * 0.86, h * 0.3);
    path.lineTo(w * 0.82, h * 0.24);
    path.lineTo(w * 0.78, h * 0.3);

    // Entrance Arch
    path.moveTo(w * 0.42, h * 0.82);
    path.lineTo(w * 0.42, h * 0.6);
    path.quadraticBezierTo(w * 0.5, h * 0.52, w * 0.58, h * 0.6);
    path.lineTo(w * 0.58, h * 0.82);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StBasilsPainter extends CustomPainter {
  final Color color;
  StBasilsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.1, h * 0.9);
    path.lineTo(w * 0.9, h * 0.9);

    // Center Tower
    path.moveTo(w * 0.42, h * 0.9);
    path.lineTo(w * 0.42, h * 0.45);
    path.lineTo(w * 0.58, h * 0.45);
    path.lineTo(w * 0.58, h * 0.9);

    path.moveTo(w * 0.42, h * 0.45);
    path.cubicTo(w * 0.38, h * 0.32, w * 0.46, h * 0.22, w * 0.5, h * 0.18);
    path.cubicTo(w * 0.54, h * 0.22, w * 0.62, h * 0.32, w * 0.58, h * 0.45);
    path.moveTo(w * 0.5, h * 0.18);
    path.lineTo(w * 0.5, h * 0.1);

    // Left tower
    path.moveTo(w * 0.22, h * 0.9);
    path.lineTo(w * 0.22, h * 0.6);
    path.lineTo(w * 0.38, h * 0.6);
    path.lineTo(w * 0.38, h * 0.9);

    path.moveTo(w * 0.22, h * 0.6);
    path.cubicTo(w * 0.18, h * 0.5, w * 0.26, h * 0.42, w * 0.3, h * 0.38);
    path.cubicTo(w * 0.34, h * 0.42, w * 0.42, h * 0.5, w * 0.38, h * 0.6);
    path.moveTo(w * 0.3, h * 0.38);
    path.lineTo(w * 0.3, h * 0.32);

    // Right tower
    path.moveTo(w * 0.62, h * 0.9);
    path.lineTo(w * 0.62, h * 0.6);
    path.lineTo(w * 0.78, h * 0.6);
    path.lineTo(w * 0.78, h * 0.9);

    path.moveTo(w * 0.62, h * 0.6);
    path.cubicTo(w * 0.58, h * 0.5, w * 0.66, h * 0.42, w * 0.7, h * 0.38);
    path.cubicTo(w * 0.74, h * 0.42, w * 0.82, h * 0.5, w * 0.78, h * 0.6);
    path.moveTo(w * 0.7, h * 0.38);
    path.lineTo(w * 0.7, h * 0.32);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PetronasTowersPainter extends CustomPainter {
  final Color color;
  PetronasTowersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.15, h * 0.95);
    path.lineTo(w * 0.22, h * 0.9);
    path.lineTo(w * 0.22, h * 0.18);
    path.lineTo(w * 0.28, h * 0.18);
    path.lineTo(w * 0.28, h * 0.9);
    path.lineTo(w * 0.35, h * 0.95);

    path.moveTo(w * 0.25, h * 0.18);
    path.lineTo(w * 0.25, h * 0.05);

    path.moveTo(w * 0.65, h * 0.95);
    path.lineTo(w * 0.72, h * 0.9);
    path.lineTo(w * 0.72, h * 0.18);
    path.lineTo(w * 0.78, h * 0.18);
    path.lineTo(w * 0.78, h * 0.9);
    path.lineTo(w * 0.85, h * 0.95);

    path.moveTo(w * 0.75, h * 0.18);
    path.lineTo(w * 0.75, h * 0.05);

    // Sky Bridge
    path.moveTo(w * 0.28, h * 0.5);
    path.lineTo(w * 0.72, h * 0.5);
    path.moveTo(w * 0.28, h * 0.53);
    path.lineTo(w * 0.72, h * 0.53);

    path.moveTo(w * 0.05, h * 0.95);
    path.lineTo(w * 0.95, h * 0.95);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PalmAndOasisPainter extends CustomPainter {
  final Color color;
  PalmAndOasisPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.05, h * 0.9);
    path.quadraticBezierTo(w * 0.4, h * 0.8, w * 0.95, h * 0.9);

    // Palm tree
    path.moveTo(w * 0.35, h * 0.85);
    path.quadraticBezierTo(w * 0.3, h * 0.6, w * 0.35, h * 0.35);

    path.moveTo(w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.2, h * 0.38, w * 0.1, h * 0.48);
    path.moveTo(w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.2, h * 0.28, w * 0.15, h * 0.22);
    path.moveTo(w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.38, h * 0.2, w * 0.42, h * 0.18);
    path.moveTo(w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.5, h * 0.3, w * 0.55, h * 0.4);
    path.moveTo(w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.45, h * 0.42, w * 0.48, h * 0.52);

    // Minaret
    path.moveTo(w * 0.72, h * 0.87);
    path.lineTo(w * 0.72, h * 0.4);
    path.moveTo(w * 0.68, h * 0.4);
    path.lineTo(w * 0.76, h * 0.4);
    path.lineTo(w * 0.72, h * 0.3);
    path.lineTo(w * 0.68, h * 0.4);

    // Spire Crescent
    path.moveTo(w * 0.72, h * 0.3);
    path.lineTo(w * 0.72, h * 0.2);
    path.addOval(Rect.fromCircle(center: Offset(w * 0.72, h * 0.16), radius: 6));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
