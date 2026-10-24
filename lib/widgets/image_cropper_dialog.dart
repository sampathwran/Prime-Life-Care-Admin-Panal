import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/web_file_utils.dart';

/// Interactive Image Cropper & Adjuster Dialog for Caregiver Profile Photos
class ImageCropperDialog extends StatefulWidget {
  final String imageSource; // base64 data URI or image URL
  final String title;
  final String fileName;
  final Function(String croppedBase64) onSave;

  const ImageCropperDialog({
    super.key,
    required this.imageSource,
    this.title = 'Crop & Adjust Profile Photo',
    this.fileName = 'caregiver-profile.jpg',
    required this.onSave,
  });

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  String? _errorMessage;

  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  bool _isCircular = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      Uint8List bytes;
      if (widget.imageSource.startsWith('data:image')) {
        final b64 = widget.imageSource.split(',').last;
        bytes = base64Decode(b64);
      } else {
        // If it's pure base64 without prefix
        bytes = base64Decode(widget.imageSource);
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load image for editing: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performCropAndSave() async {
    if (_decodedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      const outputSize = 500.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, outputSize, outputSize));

      // Background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, outputSize, outputSize), bgPaint);

      // Save canvas state
      canvas.save();

      // Center of canvas
      canvas.translate(outputSize / 2, outputSize / 2);

      // Apply zoom & pan (adjusted for output size vs viewport 260)
      const viewportSize = 260.0;
      final ratio = outputSize / viewportSize;
      canvas.translate(_panOffset.dx * ratio, _panOffset.dy * ratio);
      canvas.scale(_scale, _scale);

      // Center the decoded image
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();
      final baseScale = (outputSize / (imgW < imgH ? imgW : imgH));
      canvas.scale(baseScale, baseScale);
      canvas.translate(-imgW / 2, -imgH / 2);

      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImage(_decodedImage!, Offset.zero, paint);

      canvas.restore();

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outputSize.toInt(), outputSize.toInt());
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        final base64String = 'data:image/png;base64,${base64Encode(pngBytes)}';
        widget.onSave(base64String);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _downloadCurrent() {
    downloadWebFile(
      dataOrUrl: widget.imageSource,
      fileName: widget.fileName,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${widget.fileName}" to your computer...'),
        backgroundColor: AppTheme.emeraldGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.crop_rotate_rounded, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Text('Pan, zoom, and frame the member headshot', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_isLoading)
                const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                )
              else
                Column(
                  children: [
                    // Interactive Crop Viewport
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryBlue, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _panOffset += details.delta;
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Transformed Image
                              Transform.translate(
                                offset: _panOffset,
                                child: Transform.scale(
                                  scale: _scale,
                                  child: Center(
                                    child: RawImage(
                                      image: _decodedImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // Viewport framing mask
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropOverlayPainter(
                                    isCircular: _isCircular,
                                    maskColor: Colors.black.withOpacity(0.55),
                                    borderColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Zoom Slider & Controls
                    Row(
                      children: [
                        const Icon(Icons.zoom_out_rounded, size: 18, color: Colors.grey),
                        Expanded(
                          child: Slider(
                            value: _scale,
                            min: 0.8,
                            max: 3.5,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) => setState(() => _scale = val),
                          ),
                        ),
                        const Icon(Icons.zoom_in_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Reset to Center',
                          icon: const Icon(Icons.filter_center_focus_rounded, size: 20),
                          onPressed: () {
                            setState(() {
                              _scale = 1.0;
                              _panOffset = Offset.zero;
                            });
                          },
                        ),
                        IconButton(
                          tooltip: _isCircular ? 'Switch to Square Crop' : 'Switch to Circle Crop',
                          icon: Icon(_isCircular ? Icons.circle_outlined : Icons.crop_square_rounded, size: 20),
                          onPressed: () => setState(() => _isCircular = !_isCircular),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Action Buttons: Download, Cancel, Apply
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Download button
                  OutlinedButton.icon(
                    onPressed: _downloadCurrent,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _performCropAndSave,
                        icon: _isProcessing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Apply Crop & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dimmed mask overlay around circle or square viewport
class _CropOverlayPainter extends CustomPainter {
  final bool isCircular;
  final Color maskColor;
  final Color borderColor;

  _CropOverlayPainter({
    required this.isCircular,
    required this.maskColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addRect(rect);

    const margin = 15.0;
    final cropRect = Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin);

    final cropPath = Path();
    if (isCircular) {
      cropPath.addOval(cropRect);
    } else {
      cropPath.addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(12)));
    }

    final combinedPath = Path.combine(PathOperation.difference, path, cropPath);
    canvas.drawPath(combinedPath, Paint()..color = maskColor);

    // Border line
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isCircular) {
      canvas.drawOval(cropRect, borderPaint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(12)), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.isCircular != isCircular ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.borderColor != borderColor;
  }
}
