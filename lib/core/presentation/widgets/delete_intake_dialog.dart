import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Confirmation dialog for deleting a specific intake entry.
/// Displays the food name so the user knows exactly what will be deleted.
class DeleteIntakeDialog extends StatelessWidget {
  final IntakeEntity intake;

  const DeleteIntakeDialog({super.key, required this.intake});

  String _getDisplayName() {
    if (intake.isQuickAdd) {
      return intake.quickAddLabel ?? 'Quick add';
    }
    if (intake.isRecipe) {
      return intake.quickAddLabel ?? 'Recipe';
    }
    return intake.meal.name ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    final name = _getDisplayName();
    return AlertDialog(
      title: Text(S.of(context).deleteTimeDialogTitle),
      content: Text('Delete $name?'),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(S.of(context).dialogDeleteLabel)),
      ],
    );
  }
}
