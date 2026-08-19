import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/label_scan/data/guided_capture.dart';
import 'package:opennutritracker/features/label_scan/data/household_label_reader.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

/// Photographing a packet, one shot at a time.
///
/// This screen is only the driving. It asks for the front, then the nutrition
/// panel, then the ingredients, in that order, and it can be left at any point
/// — [GuidedCapture] has already written each shot down as it was taken, so
/// coming back picks up where it stopped rather than starting again.
///
/// It never saves a food. When the three shots are in it asks the Mac Mini to
/// read them and hands whatever comes back to [ConfirmFoodScreen] for a person
/// to look at; if nothing readable comes back it hands over an empty form and
/// says why. The saving is the same call either way.
class GuidedCaptureScreen extends StatefulWidget {
  final GuidedCapture capture;
  final HouseholdLabelReader reader;
  final HouseholdLogger logger;

  const GuidedCaptureScreen({
    super.key,
    required this.capture,
    required this.reader,
    required this.logger,
  });

  @override
  State<GuidedCaptureScreen> createState() => _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends State<GuidedCaptureScreen> {
  String? _captureId;
  List<CapturedShot> _taken = const [];
  LabelShot? _next;
  bool _busy = true;
  bool _resumed = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _open();
  }

  /// Pick up an unfinished capture if there is one, otherwise begin a new one.
  Future<void> _open() async {
    final unfinished = await widget.capture.unfinishedCapture();
    final id = unfinished ?? widget.capture.start();
    if (!mounted) return;
    setState(() {
      _captureId = id;
      _resumed = unfinished != null;
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    final id = _captureId!;
    final taken = await widget.capture.taken(id);
    final next = await widget.capture.nextShot(id);
    if (!mounted) return;
    setState(() {
      _taken = taken;
      _next = next;
      _busy = false;
    });
  }

  Future<void> _takeNext() async {
    setState(() => _busy = true);
    await widget.capture.takeNext(_captureId!);
    await _refresh();
  }

  Future<void> _retake(LabelShot shot) async {
    setState(() => _busy = true);
    await widget.capture.retake(_captureId!, shot);
    await _refresh();
  }

  /// Send the three photographs to be read, then hand the result to the form.
  Future<void> _read() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final id = _captureId!;
    final shots = await widget.capture.shotsForReading(id);
    if (shots == null) {
      await _refresh();
      return;
    }
    FoodDraft? draft;
    String? couldNotRead;
    try {
      draft = await widget.reader.read(shots);
    } on LabelUnreadable catch (e) {
      couldNotRead = e.message;
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = '${e.headline}, so the photographs '
            "can't be read yet. They're kept — try again in a moment.";
      });
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final navigator = Navigator.of(context);
    final saved = await navigator.push<String>(
      MaterialPageRoute(
        builder: (formContext) => Scaffold(
          appBar: AppBar(title: const Text('Check the numbers')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConfirmFoodScreen(
                logger: widget.logger,
                draft: draft,
                onSaved: (clientId) => Navigator.of(formContext).pop(clientId),
              ),
            ),
          ),
        ),
      ),
    );
    if (couldNotRead != null && mounted && saved == null) {
      setState(() => _problem =
          "The photographs couldn't be read ($couldNotRead). You can type the "
          "numbers in instead.");
    }
    if (saved != null) {
      await widget.capture.discard(id);
      if (mounted) navigator.pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _next == null && _captureId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Photograph a packet')),
      body: _captureId == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_resumed && _taken.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Carrying on from where you stopped — the photographs '
                        'you already took are still here.'),
                  ),
                for (final shot in LabelShot.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_taken.any((t) => t.shot == shot)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked),
                    title: Text(shot.instruction),
                    trailing: _taken.any((t) => t.shot == shot)
                        ? TextButton(
                            onPressed: _busy ? null : () => _retake(shot),
                            child: const Text('Retake'),
                          )
                        : null,
                  ),
                const SizedBox(height: 16),
                if (_problem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_problem!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                if (!done)
                  FilledButton.icon(
                    onPressed: _busy ? null : _takeNext,
                    icon: const Icon(Icons.photo_camera),
                    label: Text(_next!.instruction),
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : _read,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Read the packet'),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          await widget.capture.discard(_captureId!);
                          if (mounted) navigator.pop();
                        },
                  child: const Text('Throw these photographs away'),
                ),
              ],
            ),
    );
  }
}
