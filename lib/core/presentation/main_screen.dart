import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/quick_add/presentation/quick_add_screen_arguments.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/plan/presentation/plan_page.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/recipes/recipes_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPageIndex = 0;

  /// The Plan tab's own state, held here because the tab's app bar is built
  /// out here rather than by the page — and the calendar in that bar is how
  /// the week is chosen.
  final _plan = GlobalKey<PlanPageState>();

  late List<Widget> _bodyPages;
  late List<PreferredSizeWidget> _appbarPages;

  @override
  void didChangeDependencies() {
    _bodyPages = [
      const HomePage(),
      const DiaryPage(),
      PlanPage(key: _plan),
      const RecipesPage(),
      const ProfilePage(),
    ];
    _appbarPages = [
      const HomeAppbar(),
      MainAppbar(title: S.of(context).diaryLabel, iconData: Icons.book),
      MainAppbar(
          title: PlanPage.label,
          iconData: Icons.calendar_month,
          leadingTooltip: 'Choose a week',
          onLeadingPressed: () => _plan.currentState?.pickWeek()),
      MainAppbar(
          title: S.of(context).recipesLabel,
          iconData: Icons.restaurant_menu),
      MainAppbar(
          title: S.of(context).profileLabel, iconData: Icons.account_circle),
    ];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appbarPages[_selectedPageIndex],
      body: _bodyPages[_selectedPageIndex],
      floatingActionButton: _selectedPageIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_quick_add',
                  onPressed: () => _onQuickAddPressed(context),
                  tooltip: S.of(context).quickAddLabel,
                  child: const Icon(Icons.bolt),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'fab_add_item',
                  onPressed: () => _onFabPressed(context),
                  tooltip: S.of(context).addLabel,
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : _selectedPageIndex == 3
              ? const RecipesPageFab()
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: _setPage,
        destinations: [
          NavigationDestination(
              icon: _selectedPageIndex == 0
                  ? const Icon(Icons.home)
                  : const Icon(Icons.home_outlined),
              label: S.of(context).homeLabel),
          NavigationDestination(
              icon: _selectedPageIndex == 1
                  ? const Icon(Icons.book)
                  : const Icon((Icons.book_outlined)),
              label: S.of(context).diaryLabel),
          NavigationDestination(
              icon: _selectedPageIndex == 2
                  ? const Icon(Icons.calendar_month)
                  : const Icon(Icons.calendar_month_outlined),
              label: PlanPage.label),
          NavigationDestination(
              icon: _selectedPageIndex == 3
                  ? const Icon(Icons.restaurant_menu)
                  : const Icon(Icons.restaurant_menu_outlined),
              label: S.of(context).recipesLabel),
          NavigationDestination(
              icon: _selectedPageIndex == 4
                  ? const Icon(Icons.account_circle)
                  : const Icon(Icons.account_circle_outlined),
              label: S.of(context).profileLabel),
        ],
      ),
    );
  }

  void _setPage(int selectedIndex) {
    setState(() {
      _selectedPageIndex = selectedIndex;
    });
  }

  void _onQuickAddPressed(BuildContext context) {
    Navigator.of(context).pushNamed(
      NavigationOptions.quickAddRoute,
      arguments: QuickAddScreenArguments(DateTime.now()),
    );
  }

  void _onFabPressed(BuildContext context) async {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // Keeps the sheet below the status bar. Without it the heading sat on
        // top of the clock, because a scroll-controlled sheet is free to take
        // the whole screen and this one is now tall enough to want it.
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0))),
        builder: (BuildContext context) {
          return AddItemBottomSheet(day: DateTime.now());
        });
  }
}
