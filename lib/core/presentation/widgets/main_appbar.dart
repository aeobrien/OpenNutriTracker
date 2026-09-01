import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData iconData;

  /// What tapping the icon on the left does, when it does anything.
  ///
  /// The icon sits in the slot a back button sits in, so on every tab it reads
  /// as something to press. On four of them it is a picture and pressing it is
  /// harmless. On the Plan tab it is a calendar on a screen about dates, and
  /// Aidan pressed it on 1 September 2026 expecting to choose a week: *"There
  /// is a calendar button in the top left but tapping it does nothing."*
  ///
  /// Left null the icon stays exactly what it was — a picture. Given
  /// something, it becomes a real button with a tooltip, so what it does can
  /// be found out without pressing it.
  final VoidCallback? onLeadingPressed;

  /// What the icon is for, read out and shown on a long press. Required
  /// alongside [onLeadingPressed] for the same reason: an unlabelled icon in
  /// that slot is normally a back button, and this one is not.
  final String? leadingTooltip;

  const MainAppbar({
    super.key,
    required this.title,
    required this.iconData,
    this.onLeadingPressed,
    this.leadingTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onLeadingPressed == null
          ? Icon(iconData)
          : IconButton(
              onPressed: onLeadingPressed,
              tooltip: leadingTooltip,
              icon: Icon(iconData),
            ),
      title: Text(title),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(NavigationOptions.settingsRoute);
            },
            icon: const Icon(Icons.settings_outlined))
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
