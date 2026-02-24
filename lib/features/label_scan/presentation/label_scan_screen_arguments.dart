import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class LabelScanScreenArguments {
  final DateTime day;
  final IntakeTypeEntity? intakeType;

  const LabelScanScreenArguments({required this.day, this.intakeType});
}
