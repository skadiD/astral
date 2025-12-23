import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/utils/up.dart';

class UpdateSettingsPage extends StatelessWidget {
  const UpdateSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.update_settings.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _checkForUpdates(context),
            tooltip: LocaleKeys.check_update.tr(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(LocaleKeys.update_settings.tr()),
                  subtitle: Text(LocaleKeys.update_behavior_desc.tr()),
                  leading: const Icon(Icons.system_update),
                ),

                const Divider(),

                SwitchListTile(
                  title: Text(LocaleKeys.join_beta.tr()),
                  subtitle: Text(LocaleKeys.join_beta_desc.tr()),
                  value: Aps().beta.watch(context),
                  onChanged: (value) {
                    Aps().setBeta(value);
                  },
                ),

                if (!Aps().beta.watch(context))
                  SwitchListTile(
                    title: Text(LocaleKeys.auto_update.tr()),
                    subtitle: Text(LocaleKeys.auto_update_desc.tr()),
                    value: Aps().autoCheckUpdate.watch(context),
                    onChanged: (value) {
                      Aps().setAutoCheckUpdate(value);
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(LocaleKeys.download_acceleration.tr()),
                  subtitle: Text(LocaleKeys.download_acceleration_desc.tr()),
                  leading: const Icon(Icons.speed),
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: LocaleKeys.download_acceleration.tr(),
                      hintText: LocaleKeys.download_acceleration_hint.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                    ),
                    initialValue: Aps().downloadAccelerate.watch(context),
                    onChanged: (value) {
                      Aps().setDownloadAccelerate(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(LocaleKeys.update_operations.tr()),
                  subtitle: Text(LocaleKeys.update_operations_desc.tr()),
                  leading: const Icon(Icons.update),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(LocaleKeys.check_update.tr()),
                  subtitle: Text(LocaleKeys.check_update_available.tr()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _checkForUpdates(context),
                ),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(LocaleKeys.version_info.tr()),
                  subtitle: Text(LocaleKeys.version_info_desc.tr()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showVersionInfo(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(LocaleKeys.update_description.tr()),
                  subtitle: Text(LocaleKeys.update_description_desc.tr()),
                  leading: const Icon(Icons.help_outline),
                ),

                const Divider(),

                ListTile(
                  title: Text(LocaleKeys.beta_version.tr()),
                  subtitle: Text(LocaleKeys.beta_version_desc.tr()),
                  leading: const Icon(Icons.science),
                ),

                ListTile(
                  title: Text(LocaleKeys.auto_update_title.tr()),
                  subtitle: Text(LocaleKeys.auto_update_info_desc.tr()),
                  leading: const Icon(Icons.auto_awesome),
                ),

                ListTile(
                  title: Text(LocaleKeys.download_acceleration_title.tr()),
                  subtitle: Text(
                    LocaleKeys.download_acceleration_info_desc.tr(),
                  ),
                  leading: const Icon(Icons.speed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    final updateChecker = UpdateChecker(owner: 'ldoubil', repo: 'astral');
    if (context.mounted) {
      updateChecker.checkForUpdates(context);
    }
  }

  void _showVersionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LocaleKeys.version_info.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${LocaleKeys.current_version.tr()}: ${AppInfoUtil.getVersion()}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${LocaleKeys.update_channel.tr()}: ${Aps().beta.value ? "Beta" : "Stable"}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.close.tr()),
              ),
            ],
          ),
    );
  }
}
