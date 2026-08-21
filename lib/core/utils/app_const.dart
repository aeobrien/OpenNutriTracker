import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

class AppConst {
  static const userAgentAppName = "OpenNutriTracker";
  static const platformNameAndroid = "Android";
  static const platformNameIOS = "iOS";
  static const reportErrorEmail = "opennutritracker-dev@pm.me";
  static const sourceCodeUrl =
      "https://github.com/simonoppowa/OpenNutriTracker";

  /// The version, with the build number after it.
  ///
  /// Every build of this app has been 1.0.0, so the version on its own could
  /// never tell one copy from another. On 21 August 2026 that cost an exchange
  /// about which build was on the phone that nobody could settle by looking at
  /// it. The build number is the part that changes, so it is the part shown.
  static Future<String> getVersionNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final build = packageInfo.buildNumber;
    return build.isEmpty
        ? packageInfo.version
        : '${packageInfo.version} ($build)';
  }

  static String getPlatformName() {
    if (Platform.isAndroid) {
      return platformNameAndroid;
    } else if (Platform.isIOS) {
      return platformNameIOS;
    } else {
      return "";
    }
  }

  static Future<String> getUserAgentString() async {
    final versionNumber = await getVersionNumber();
    final platformVersion = getPlatformName();
    return '$userAgentAppName - $platformVersion - Version $versionNumber - $sourceCodeUrl';
  }
}
