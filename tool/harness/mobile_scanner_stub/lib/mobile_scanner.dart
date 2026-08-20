/// The scanner screen's side of the barcode plugin, and nothing behind it.
///
/// Every name here exists because `lib/features/scanner/scanner_screen.dart`
/// mentions it. If that screen grows a new call, this file needs the matching
/// name or the simulator build stops compiling — which is the right failure,
/// because a stand-in that has quietly fallen behind is worse than none.
library;

import 'package:flutter/material.dart';

enum TorchState { off, on, auto, unavailable }

enum BarcodeType { unknown, product, text, url }

class Barcode {
  const Barcode({this.rawValue, this.type = BarcodeType.unknown});

  final String? rawValue;
  final BarcodeType type;
}

class BarcodeCapture {
  const BarcodeCapture({this.barcodes = const []});

  final List<Barcode> barcodes;
}

class MobileScannerState {
  const MobileScannerState({this.torchState = TorchState.unavailable});

  final TorchState torchState;
}

class MobileScannerController extends ValueNotifier<MobileScannerState> {
  MobileScannerController() : super(const MobileScannerState());

  Future<void> toggleTorch() async {}

  Future<void> switchCamera() async {}
}

/// Where the camera would be. Says so, rather than showing a black rectangle
/// that could be mistaken for a camera that has failed.
class MobileScanner extends StatelessWidget {
  const MobileScanner({super.key, this.controller, this.onDetect});

  final MobileScannerController? controller;
  final void Function(BarcodeCapture)? onDetect;

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'There is no camera on a simulator, so there is nothing to scan '
            'here. On a phone this is the viewfinder.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
