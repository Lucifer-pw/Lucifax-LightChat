import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

class AvatarCropperPage extends StatefulWidget {
  final File imageFile;

  const AvatarCropperPage({super.key, required this.imageFile});

  @override
  State<AvatarCropperPage> createState() => _AvatarCropperPageState();
}

class _AvatarCropperPageState extends State<AvatarCropperPage> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  int _rotationQuarterTurns = 0;
  bool _isProcessing = false;

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _cropAndSave() async {
    setState(() => _isProcessing = true);
    try {
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.pop(context, widget.imageFile);
        return;
      }

      // Capture high-resolution crop
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (!mounted) return;
        Navigator.pop(context, widget.imageFile);
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File('${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await croppedFile.writeAsBytes(buffer);

      if (!mounted) return;
      Navigator.pop(context, croppedFile);
    } catch (e) {
      debugPrint('[AvatarCropper] Error cropping image: $e');
      if (mounted) {
        Navigator.pop(context, widget.imageFile);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cropSize = screenSize.width * 0.85;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Pangkas Foto Profil', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_rounded, color: Colors.white),
            tooltip: 'Putar 90°',
            onPressed: _rotateImage,
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
            tooltip: 'Reset Zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Geser dan cubit untuk mengatur posisi foto',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const Spacer(),

          // Crop Area Container
          Center(
            child: SizedBox(
              width: cropSize,
              height: cropSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // RepaintBoundary capturing the exact circular viewport
                  ClipOval(
                    child: RepaintBoundary(
                      key: _cropKey,
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: _rotationQuarterTurns,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Circular guide overlay with border and grid
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CropGuidePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  label: const Text('Batal', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _cropAndSave,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    _isProcessing ? 'Menyimpan...' : 'Gunakan Foto',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Circle border
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, borderPaint);

    // Rule of thirds subtle grid lines inside circle
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Vertical lines
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), gridPaint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), gridPaint);

    // Horizontal lines
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), gridPaint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), gridPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
