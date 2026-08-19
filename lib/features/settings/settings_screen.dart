import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/household_scope.dart';
import 'package:opennutritracker/features/household/presentation/household_settings_section.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/calculations_dialog.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/recipes/data/mealie_secure_storage.dart';
import 'package:opennutritracker/features/intake/data/mantel_secure_storage.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;
  late ProfileBloc _profileBloc;
  late HomeBloc _homeBloc;
  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;

  @override
  void initState() {
    _settingsBloc = locator<SettingsBloc>();
    _profileBloc = locator<ProfileBloc>();
    _homeBloc = locator<HomeBloc>();
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settingsLabel),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        bloc: _settingsBloc,
        builder: (context, state) {
          if (state is SettingsInitial) {
            _settingsBloc.add(LoadSettingsEvent());
          } else if (state is SettingsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoadedState) {
            return ListView(
              children: [
                const SizedBox(height: 16.0),
                // The household settings come first because they decide what
                // the rest of this screen — and the rest of the app — is even
                // showing: whose phone this is, and whether they see figures.
                HouseholdSettingsSection(
                  repository: locator<HouseholdRepository>(),
                  onChanged: () {
                    HouseholdScope.refreshed(context);
                    // And redraw Home, because the target that was just
                    // changed is the number on its ring. Home is built once
                    // and kept alive behind the tabs, so without this it goes
                    // on showing the old figure until the app is restarted —
                    // which looks exactly like the setting having been
                    // ignored, and on 19 August that is what it looked like.
                    _homeBloc.add(const LoadItemsEvent());
                    _diaryBloc.add(const LoadDiaryYearEvent());
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.ac_unit_outlined),
                  title: Text(S.of(context).settingsUnitsLabel),
                  onTap: () =>
                      _showUnitsDialog(context, state.usesImperialUnits),
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(S.of(context).settingsCalculationsLabel),
                  onTap: () => _showCalculationsDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: Text(S.of(context).exerciseMultiplierLabel),
                  onTap: () => _showExerciseMultiplierDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.nightlight_outlined),
                  title: Text(S.of(context).dayBoundaryLabel),
                  subtitle: _DayBoundarySubtitle(),
                  onTap: () => _showDayBoundaryDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(S.of(context).appleHealthLabel),
                  subtitle: _HealthStatusSubtitle(),
                  onTap: () => _showHealthDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(S.of(context).remindersLabel),
                  onTap: () => _showNotificationSettingsDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_medium_outlined),
                  title: Text(S.of(context).settingsThemeLabel),
                  onTap: () => _showThemeDialog(context, state.appTheme),
                ),
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(S.of(context).exportImportLabel),
                  onTap: () => _showExportImportDialog(context),
                ),
                _ApiKeyTile(
                  icon: Icons.image_search_outlined,
                  label: S.of(context).openAiApiKeyLabel,
                  configuredText: S.of(context).openAiApiKeyConfigured,
                  notSetText: S.of(context).openAiApiKeyNotSet,
                  hintText: 'sk-...',
                  getKey: () => SecureAppStorageProvider().getOpenAiApiKey(),
                  setKey: (k) => SecureAppStorageProvider().setOpenAiApiKey(k),
                  deleteKey: () => SecureAppStorageProvider().deleteOpenAiApiKey(),
                  hasKey: () => SecureAppStorageProvider().hasOpenAiApiKey(),
                ),
                _ApiKeyTile(
                  icon: Icons.smart_toy_outlined,
                  label: S.of(context).claudeApiKeyLabel,
                  configuredText: S.of(context).claudeApiKeyConfigured,
                  notSetText: S.of(context).claudeApiKeyNotSet,
                  hintText: 'sk-ant-...',
                  getKey: () => SecureAppStorageProvider().getClaudeApiKey(),
                  setKey: (k) => SecureAppStorageProvider().setClaudeApiKey(k),
                  deleteKey: () => SecureAppStorageProvider().deleteClaudeApiKey(),
                  hasKey: () => SecureAppStorageProvider().hasClaudeApiKey(),
                ),
                // Mealie is the recipe source of truth; FoodTracker mirrors it
                // one-way. Sync the pulled recipes from the Recipes tab.
                _ApiKeyTile(
                  icon: Icons.dns_outlined,
                  label: 'Mealie server URL',
                  configuredText: 'Configured',
                  notSetText: 'Not set',
                  hintText: 'http://100.71.40.51:9000',
                  obscure: false,
                  getKey: () => SecureAppStorageProvider().getMealieBaseUrl(),
                  setKey: (k) => SecureAppStorageProvider().setMealieBaseUrl(k),
                  deleteKey: () => SecureAppStorageProvider().setMealieBaseUrl(''),
                  hasKey: () => SecureAppStorageProvider()
                      .getMealieBaseUrl()
                      .then((v) => (v ?? '').isNotEmpty),
                ),
                _ApiKeyTile(
                  icon: Icons.key_outlined,
                  label: 'Mealie API token',
                  configuredText: 'Configured',
                  notSetText: 'Not set',
                  hintText: 'paste your Mealie API token',
                  getKey: () => SecureAppStorageProvider().getMealieToken(),
                  setKey: (k) => SecureAppStorageProvider().setMealieToken(k),
                  deleteKey: () => SecureAppStorageProvider().setMealieToken(''),
                  hasKey: () => SecureAppStorageProvider()
                      .getMealieToken()
                      .then((v) => (v ?? '').isNotEmpty),
                ),
                // Mantel logs meals by voice/chat; FoodTracker pulls them into
                // the diary. Base URL + actor are required; the token is only
                // needed if Mantel has one set for this actor (blank on tailnet).
                _ApiKeyTile(
                  icon: Icons.sync_alt_outlined,
                  label: 'Mantel server URL',
                  configuredText: 'Configured',
                  notSetText: 'Not set',
                  hintText: 'http://100.71.40.51:8770',
                  obscure: false,
                  getKey: () => SecureAppStorageProvider().getMantelBaseUrl(),
                  setKey: (k) => SecureAppStorageProvider().setMantelBaseUrl(k),
                  deleteKey: () => SecureAppStorageProvider().setMantelBaseUrl(''),
                  hasKey: () => SecureAppStorageProvider()
                      .getMantelBaseUrl()
                      .then((v) => (v ?? '').isNotEmpty),
                ),
                // There used to be an owner field here — a second
                // place to say whose phone this is, typed by hand, which
                // decided whose meals were pulled into the diary while the
                // household half used a different answer. It is gone. Whose
                // phone this is is asked once on first run and changed in the
                // household section above; the name this field held is now
                // written from that one choice.
                _ApiKeyTile(
                  icon: Icons.key_outlined,
                  label: 'Mantel intake token (optional)',
                  configuredText: 'Configured',
                  notSetText: 'Not set',
                  hintText: 'leave blank on the tailnet',
                  getKey: () =>
                      SecureAppStorageProvider().getMantelIntakeToken(),
                  setKey: (k) =>
                      SecureAppStorageProvider().setMantelIntakeToken(k),
                  deleteKey: () =>
                      SecureAppStorageProvider().setMantelIntakeToken(''),
                  hasKey: () => SecureAppStorageProvider()
                      .getMantelIntakeToken()
                      .then((v) => (v ?? '').isNotEmpty),
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_outlined),
                  title: const Text('Sync meals from Mantel'),
                  onTap: () => _syncFromMantel(context),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(S.of(context).settingsDisclaimerLabel),
                  onTap: () => _showDisclaimerDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(S.of(context).settingsReportErrorLabel),
                  onTap: () => _showReportErrorDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(S.of(context).settingsPrivacySettings),
                  onTap: () =>
                      _showPrivacyDialog(context, state.sendAnonymousData),
                ),
                ListTile(
                  leading: const Icon(Icons.error_outline_outlined),
                  title: Text(S.of(context).settingAboutLabel),
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: 32.0),
                AppBannerVersion(versionNumber: state.versionNumber)
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showUnitsDialog(BuildContext context, bool usesImperialUnits) async {
    SystemDropDownType selectedUnit = usesImperialUnits
        ? SystemDropDownType.imperial
        : SystemDropDownType.metric;
    final shouldUpdate = await showDialog<bool?>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(S.of(context).settingsUnitsLabel),
              content: Wrap(children: [
                Column(
                  children: [
                    DropdownButtonFormField(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        enabled: true,
                        filled: false,
                        labelText: S.of(context).settingsSystemLabel,
                      ),
                      onChanged: (value) {
                        selectedUnit = value ?? SystemDropDownType.metric;
                      },
                      items: [
                        DropdownMenuItem(
                            value: SystemDropDownType.metric,
                            child: Text(S.of(context).settingsMetricLabel)),
                        DropdownMenuItem(
                            value: SystemDropDownType.imperial,
                            child: Text(S.of(context).settingsImperialLabel))
                      ],
                    )
                  ],
                ),
              ]),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(S.of(context).dialogOKLabel))
              ]);
        });
    if (shouldUpdate == true) {
      _settingsBloc
          .setUsesImperialUnits(selectedUnit == SystemDropDownType.imperial);
      _settingsBloc.add(LoadSettingsEvent());

      // Update blocs
      _profileBloc.add(LoadProfileEvent());
      _homeBloc.add(LoadItemsEvent());
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }

  void _showCalculationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CalculationsDialog(
        settingsBloc: _settingsBloc,
        profileBloc: _profileBloc,
        homeBloc: _homeBloc,
        diaryBloc: _diaryBloc,
        calendarDayBloc: _calendarDayBloc,
      ),
    );
  }

  void _showExportImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExportImportDialog(),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _NotificationSettingsDialog(),
    );
  }

  /// Manual full sync of meals logged via Mantel. Bypasses any auto-sync — runs
  /// a fresh pull and reports plainly so it never feels broken when the
  /// foreground auto-sync already pulled everything.
  Future<void> _syncFromMantel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!await SecureAppStorageProvider().hasMantelConfig()) {
      messenger.showSnackBar(const SnackBar(
        content:
            Text('Set the Mantel server URL and meal owner above first.'),
      ));
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Syncing meals from Mantel…')),
    );

    try {
      final result = await locator<MantelSyncService>().syncPending();
      final String message;
      if (!result.configured) {
        message = 'Set the Mantel server URL and meal owner above first.';
      } else if (result.synced > 0) {
        final failed = result.failed > 0 ? ' (${result.failed} failed)' : '';
        message = 'Synced ${result.synced} meal(s) from Mantel$failed.';
      } else if (result.failed > 0) {
        message = '${result.failed} meal(s) failed to sync — try again.';
      } else {
        message = 'Up to date — no new meals.';
      }
      if (result.hasNewEntries) {
        _homeBloc.add(const LoadItemsEvent());
        _diaryBloc.add(const LoadDiaryYearEvent());
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Mantel sync failed: $e')),
      );
    }
  }

  void _showThemeDialog(BuildContext context, AppThemeEntity currentAppTheme) {
    AppThemeEntity selectedTheme = currentAppTheme;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            title: Text(S.of(context).settingsThemeLabel),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile(
                      title:
                          Text(S.of(context).settingsThemeSystemDefaultLabel),
                      value: AppThemeEntity.system,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeLightLabel),
                      value: AppThemeEntity.light,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeDarkLabel),
                      value: AppThemeEntity.dark,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _settingsBloc.setAppTheme(selectedTheme);
                    _settingsBloc.add(LoadSettingsEvent());
                    setState(() {
                      // Update Theme
                      Provider.of<ThemeModeProvider>(context, listen: false)
                          .updateTheme(selectedTheme);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel)),
            ],
          );
        });
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return const DisclaimerDialog();
        });
  }

  void _showReportErrorDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsReportErrorLabel),
            content: Text(S.of(context).reportErrorDialogText),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _reportError(context);
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel))
            ],
          );
        });
  }

  Future<void> _reportError(BuildContext context) async {
    final reportUri =
        Uri.parse("mailto:${AppConst.reportErrorEmail}?subject=Report_Error");

    if (await canLaunchUrl(reportUri)) {
      launchUrl(reportUri);
    } else {
      // Cannot open email app, show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).errorOpeningEmail)));
      }
    }
  }

  void _showPrivacyDialog(
      BuildContext context, bool hasAcceptedAnonymousData) async {
    bool switchActive = hasAcceptedAnonymousData;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsPrivacySettings),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return SwitchListTile(
                  title: Text(S.of(context).sendAnonymousUserData),
                  value: switchActive,
                  onChanged: (bool value) {
                    setState(() {
                      switchActive = value;
                    });
                  },
                );
              },
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _settingsBloc.setHasAcceptedAnonymousData(switchActive);
                    _settingsBloc.add(LoadSettingsEvent());
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel))
            ],
          );
        });
  }

  void _showAboutDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
      showAboutDialog(
          context: context,
          applicationName: S.of(context).appTitle,
          applicationIcon: SizedBox(
              width: 40, child: Image.asset('assets/icon/ont_logo_square.png')),
          applicationVersion: packageInfo.version,
          applicationLegalese: S.of(context).appLicenseLabel,
          children: [
            TextButton(
                onPressed: () {
                  _launchSourceCodeUrl(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.code_outlined),
                    const SizedBox(width: 8.0),
                    Text(S.of(context).settingsSourceCodeLabel),
                  ],
                )),
            TextButton(
                onPressed: () {
                  _launchPrivacyPolicyUrl(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.policy_outlined),
                    const SizedBox(width: 8.0),
                    Text(S.of(context).privacyPolicyLabel),
                  ],
                ))
          ]);
    }
  }

  void _launchSourceCodeUrl(BuildContext context) async {
    final sourceCodeUri = Uri.parse(AppConst.sourceCodeUrl);
    _launchUrl(context, sourceCodeUri);
  }

  void _launchPrivacyPolicyUrl(BuildContext context) async {
    final sourceCodeUri = Uri.parse(URLConst.privacyPolicyURLEn);
    _launchUrl(context, sourceCodeUri);
  }

  void _launchUrl(BuildContext context, Uri url) async {
    if (await canLaunchUrl(url)) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Cannot open browser app, show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).errorOpeningBrowser)));
      }
    }
  }

  void _showExerciseMultiplierDialog(BuildContext context) async {
    final configRepo = locator<ConfigRepository>();
    double current = await configRepo.getExerciseMultiplier();

    if (!context.mounted) return;
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.of(context).exerciseMultiplierLabel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).exerciseMultiplierDescription),
                  const SizedBox(height: 16),
                  Text(
                    '${(current * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Slider(
                    min: 0,
                    max: 1.0,
                    divisions: 20,
                    value: current,
                    label: '${(current * 100).round()}%',
                    onChanged: (value) {
                      setDialogState(() => current = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context).dialogCancelLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(current),
                  child: Text(S.of(context).dialogOKLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await configRepo.setExerciseMultiplier(result);
      _homeBloc.add(LoadItemsEvent());
    }
  }

  void _showDayBoundaryDialog(BuildContext context) async {
    final configRepo = locator<ConfigRepository>();
    int current = await configRepo.getDayBoundaryHour();

    if (!context.mounted) return;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).dayBoundaryLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).dayBoundaryDescription),
              const SizedBox(height: 8),
              ...List.generate(7, (i) {
                final hour = i;
                final label = hour == 0 ? '12:00 AM' : '$hour:00 AM';
                return RadioListTile<int>(
                  title: Text(label),
                  value: hour,
                  groupValue: current,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).dialogCancelLabel),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await configRepo.setDayBoundaryHour(result);
      setState(() {}); // refresh subtitle
    }
  }

  void _showHealthDialog(BuildContext context) async {
    final healthRepo = locator<HealthRepository>();
    bool hasPerm = await healthRepo.hasPermission();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.of(context).appleHealthLabel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasPerm ? Icons.check_circle : Icons.cancel,
                        color: hasPerm ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(hasPerm
                          ? S.of(context).healthConnectedLabel
                          : S.of(context).healthNotConnectedLabel),
                    ],
                  ),
                  if (!hasPerm) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final result =
                            await healthRepo.requestPermission();
                        setDialogState(() => hasPerm = result);
                      },
                      child: Text(S.of(context).requestPermissionLabel),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context).dialogOKLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ApiKeyTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String configuredText;
  final String notSetText;
  final String hintText;
  final Future<String?> Function() getKey;
  final Future<void> Function(String) setKey;
  final Future<void> Function() deleteKey;
  final Future<bool> Function() hasKey;
  final bool obscure;

  const _ApiKeyTile({
    required this.icon,
    required this.label,
    required this.configuredText,
    required this.notSetText,
    required this.hintText,
    required this.getKey,
    required this.setKey,
    required this.deleteKey,
    required this.hasKey,
    this.obscure = true,
  });

  @override
  State<_ApiKeyTile> createState() => _ApiKeyTileState();
}

class _ApiKeyTileState extends State<_ApiKeyTile> {
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final has = await widget.hasKey();
    if (mounted) setState(() => _hasKey = has);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.label),
      subtitle: Text(_hasKey ? widget.configuredText : widget.notSetText),
      onTap: () => _showApiKeyDialog(context),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.label),
          content: TextField(
            controller: controller,
            obscureText: widget.obscure,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            if (_hasKey)
              TextButton(
                onPressed: () => Navigator.of(context).pop('__clear__'),
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(S.of(context).buttonSaveLabel),
            ),
          ],
        );
      },
    );

    if (result == '__clear__') {
      await widget.deleteKey();
      _checkKey();
    } else if (result != null && result.trim().isNotEmpty) {
      await widget.setKey(result.trim());
      _checkKey();
    }
  }
}

class _DayBoundarySubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: locator<ConfigRepository>().getDayBoundaryHour(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final hour = snapshot.data!;
        final label = hour == 0 ? '12:00 AM' : '$hour:00 AM';
        return Text(label);
      },
    );
  }
}

class _HealthStatusSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: locator<HealthRepository>().hasPermission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Text(snapshot.data!
            ? S.of(context).healthConnectedLabel
            : S.of(context).healthNotConnectedLabel);
      },
    );
  }
}

class _NotificationSettingsDialog extends StatefulWidget {
  const _NotificationSettingsDialog();

  @override
  State<_NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<_NotificationSettingsDialog> {
  final _configRepo = locator<ConfigRepository>();
  final _notifService = locator<NotificationService>();

  static const _slots = ['breakfast', 'lunch', 'dinner', 'snack'];

  final Map<String, bool> _enabled = {};
  final Map<String, TimeOfDay> _times = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    for (final slot in _slots) {
      _enabled[slot] = await _configRepo.getNotifEnabled(slot);
      final hour = await _configRepo.getNotifHour(slot);
      final minute = await _configRepo.getNotifMinute(slot);
      _times[slot] = TimeOfDay(hour: hour, minute: minute);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'breakfast':
        return S.of(context).breakfastLabel;
      case 'lunch':
        return S.of(context).lunchLabel;
      case 'dinner':
        return S.of(context).dinnerLabel;
      case 'snack':
        return S.of(context).snackLabel;
      default:
        return slot;
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _onToggle(String slot, bool value) async {
    setState(() => _enabled[slot] = value);
    await _configRepo.setNotifEnabled(slot, value);
    if (value) {
      final time = _times[slot]!;
      await _notifService.scheduleMealReminder(slot, time.hour, time.minute);
    } else {
      await _notifService.cancelMealReminder(slot);
    }
  }

  Future<void> _onTimeTap(String slot) async {
    final current = _times[slot]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _times[slot] = picked);
      await _configRepo.setNotifTime(slot, picked.hour, picked.minute);
      if (_enabled[slot] == true) {
        await _notifService.scheduleMealReminder(
            slot, picked.hour, picked.minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).remindersLabel),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _slots.map((slot) {
                final isOn = _enabled[slot] ?? false;
                final time = _times[slot] ?? const TimeOfDay(hour: 12, minute: 0);
                return SwitchListTile(
                  title: Text(_slotLabel(slot)),
                  subtitle: isOn
                      ? GestureDetector(
                          onTap: () => _onTimeTap(slot),
                          child: Text(
                            _formatTime(time),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : null,
                  value: isOn,
                  onChanged: (val) => _onToggle(slot, val),
                );
              }).toList(),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
