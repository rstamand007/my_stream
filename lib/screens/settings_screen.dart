import 'package:flutter/material.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: l10n.playback,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.speed_rounded,
                title: l10n.playbackSpeed,
                subtitle: '1.0x',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.skip_next_rounded,
                title: l10n.skipForward,
                subtitle: '30s',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.skip_previous_rounded,
                title: l10n.skipBackward,
                subtitle: '10s',
                onTap: () {},
              ),
            ],
          ),

          _buildSection(
            context,
            title: l10n.downloads,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.download_rounded,
                title: l10n.autoDownload,
                subtitle: l10n.autoDownloadSubtitle,
                trailing: Switch(value: false, onChanged: (value) {}),
              ),
              _buildSettingTile(
                context,
                icon: Icons.high_quality_rounded,
                title: l10n.downloadQuality,
                subtitle: 'High',
                onTap: () {},
              ),
            ],
          ),

          _buildSection(
            context,
            title: l10n.appearance,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.palette_rounded,
                title: l10n.theme,
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primary,
                  ),
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      themeProvider.setThemeMode(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.themeSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.themeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.themeDark),
                    ),
                  ],
                ),
              ),
              _buildSettingTile(
                context,
                icon: Icons.language_rounded,
                title: l10n.language,
                trailing: DropdownButton<String>(
                  value: localeProvider.locale?.languageCode ?? 'en',
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primary,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      localeProvider.setLocale(Locale(newValue));
                    }
                  },
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                  ],
                ),
              ),
            ],
          ),

          _buildSection(
            context,
            title: l10n.about,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.info_outline_rounded,
                title: l10n.version,
                subtitle: '1.0.0',
              ),
              _buildSettingTile(
                context,
                icon: Icons.code_rounded,
                title: l10n.licenses,
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }
}
