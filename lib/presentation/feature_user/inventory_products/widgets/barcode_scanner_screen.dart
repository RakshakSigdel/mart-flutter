import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/core.dart';

/// Opens the camera scanner in a bottom sheet and returns the first barcode.
Future<String?> showBarcodeScannerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.62,
      child: BarcodeScannerScreen(),
    ),
  );
}

/// Camera scanner content hosted by [showBarcodeScannerSheet].
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasDetectedBarcode = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasDetectedBarcode) return;

    String? value;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        value = rawValue;
        break;
      }
    }
    if (value == null) return;

    setState(() => _hasDetectedBarcode = true);
    await _controller.stop();
    await SystemSound.play(SystemSoundType.alert);
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorderRadius.radiusXL,
      child: Scaffold(
        backgroundColor: AppColors.accent,
        appBar: AppBar(
          title: const Text('Scan barcode'),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: AppBorderRadius.radiusL,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
              child: Text(
                _hasDetectedBarcode
                    ? 'Barcode detected'
                    : 'Place the barcode inside the frame',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textInverse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
