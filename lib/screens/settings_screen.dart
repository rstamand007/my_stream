import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'Playback',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.speed_rounded,
                title: 'Default Playback Speed',
                subtitle: '1.0x',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.skip_next_rounded,
                title: 'Skip Forward',
                subtitle: '30 seconds',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: Icons.skip_previous_rounded,
                title: 'Skip Backward',
                subtitle: '15 seconds',
                onTap: () {},
              ),
            ],
          ),

          _buildSection(
            context,
            title: 'Downloads',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.download_rounded,
                title: 'Auto Download',
                subtitle: 'Automatically download new episodes',
                trailing: Switch(value: false, onChanged: (value) {}),
              ),
              _buildSettingTile(
                context,
                icon: Icons.high_quality_rounded,
                title: 'Download Quality',
                subtitle: 'High',
                onTap: () {},
              ),
            ],
          ),

          _buildSection(
            context,
            title: 'Appearance',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.dark_mode_rounded,
                title: 'Theme',
                subtitle: 'Dark',
                onTap: () {},
              ),
            ],
          ),

          _buildSection(
            context,
            title: 'About',
            children: [
              _buildSettingTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _buildSettingTile(
                context,
                icon: Icons.code_rounded,
                title: 'Open Source Licenses',
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
