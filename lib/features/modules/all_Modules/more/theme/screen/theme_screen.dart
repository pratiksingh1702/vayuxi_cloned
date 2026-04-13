import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/theme_controller.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final previewAccent = themeState.customSeed ?? colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Appearance Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            'Display',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outlineVariant.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeState.themeMode,
                  onChanged: (v) => notifier.changeMode(v!),
                  title: const Text('Light'),
                  subtitle: const Text('Always use light appearance'),
                ),
                Divider(
                    height: 1, color: colors.outlineVariant.withOpacity(0.6)),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeState.themeMode,
                  onChanged: (v) => notifier.changeMode(v!),
                  title: const Text('Dark'),
                  subtitle: const Text('Always use dark appearance'),
                ),
                Divider(
                    height: 1, color: colors.outlineVariant.withOpacity(0.6)),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeState.themeMode,
                  onChanged: (v) => notifier.changeMode(v!),
                  title: const Text('System default'),
                  subtitle: const Text('Match your device setting'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Color Style',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outlineVariant.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.palette_rounded, color: colors.primary),
                  title: const Text('Color scheme'),
                  subtitle: Text(_schemeLabel(themeState.scheme)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final selected = await _showSchemeSelector(
                      context,
                      current: themeState.scheme,
                    );
                    if (selected != null) {
                      notifier.changeScheme(selected);
                    }
                  },
                ),
                Divider(
                    height: 1, color: colors.outlineVariant.withOpacity(0.6)),
                ListTile(
                  leading: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: previewAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                  ),
                  title: const Text('Accent color'),
                  subtitle: Text(
                    themeState.customSeed == null
                        ? 'Using scheme default'
                        : _hex(themeState.customSeed!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Color draft = themeState.customSeed ?? colors.primary;
                          final picked = await ColorPicker(
                            color: draft,
                            onColorChanged: (c) => draft = c,
                            pickersEnabled: const {
                              ColorPickerType.wheel: true,
                              ColorPickerType.accent: true,
                              ColorPickerType.primary: false,
                            },
                          ).showPickerDialog(context);
                          if (picked) {
                            notifier.setCustomSeed(draft);
                          }
                        },
                        child: const Text('Pick'),
                      ),
                      TextButton(
                        onPressed: themeState.customSeed == null
                            ? null
                            : notifier.clearCustomSeed,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Live Preview',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _ThemeDemoCard(
            schemeName: _schemeLabel(themeState.scheme),
            accentColor: previewAccent,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.secondaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colors.outlineVariant.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your appearance settings are saved offline and applied at app startup.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Mode';
    }
  }

  String _schemeLabel(FlexScheme scheme) {
    final raw = scheme.name;
    return raw.substring(0, 1).toUpperCase() + raw.substring(1);
  }

  String _hex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  Future<FlexScheme?> _showSchemeSelector(
    BuildContext context, {
    required FlexScheme current,
  }) {
    return showModalBottomSheet<FlexScheme>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Text('Choose Scheme', style: textTheme.titleMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: FlexScheme.values.length,
                  itemBuilder: (context, index) {
                    final item = FlexScheme.values[index];
                    final selected = item == current;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color:
                            selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                      title: Text(_schemeLabel(item)),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeDemoCard extends StatelessWidget {
  const _ThemeDemoCard({
    required this.schemeName,
    required this.accentColor,
  });

  final String schemeName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Premium Preview',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DemoMiniTile(
                  title: 'Scheme',
                  value: schemeName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DemoMiniTile(
                  title: 'Accent',
                  value:
                      '#${accentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.67,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoMiniTile extends StatelessWidget {
  const _DemoMiniTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
