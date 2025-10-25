import 'package:astral/state/app_state.dart';
import 'package:astral/utils/up.dart';
import 'package:astral/utils/version_util.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/widgets/home_box.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AboutHome extends StatefulWidget {
  const AboutHome({super.key});

  @override
  State<AboutHome> createState() => _AboutHomeState();
}

class _AboutHomeState extends State<AboutHome> {
  String version = '';
  
  @override
  void initState() {
    super.initState();
    easytierVersion().then((value) {
      setState(() {
        version = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return HomeBox(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 22,
              ), // 修改标题图标
              const SizedBox(width: 8),
              Text(
                LocaleKeys.about.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Icon(
                Icons.smartphone,
                size: 20,
                color: colorScheme.primary,
              ), // 软件版本图标
              Text(
                '${LocaleKeys.software_version.tr()}: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Builder(
                builder: (context) {
                  final currentVersion = AppInfoUtil.getVersion();
                  final latestVersion = AppState().baseState.latestVersion.watch(context);
                  final versionText = VersionUtil.getVersionDisplayText(
                    currentVersion,
                    latestVersion,
                  );
                  final hasNewVersion = VersionUtil.hasNewVersion(
                    currentVersion,
                    latestVersion,
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        versionText,
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                      if (hasNewVersion) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Icon(
                Icons.memory,
                size: 20,
                color: colorScheme.primary,
              ), // 内核版本图标
              Text(
                '${LocaleKeys.kernel_version.tr()}: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(version, style: TextStyle(color: colorScheme.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
