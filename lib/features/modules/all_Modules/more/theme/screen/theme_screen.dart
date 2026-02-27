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

    final List<_ColorEntry> colorEntries = [
      // Primary
      _ColorEntry('primary', colors.primary, colors.onPrimary, 'Main interactive elements: FAB, active buttons, highlights'),
      _ColorEntry('onPrimary', colors.onPrimary, colors.primary, 'Text/icons on primary color'),
      _ColorEntry('primaryContainer', colors.primaryContainer, colors.onPrimaryContainer, 'Selected cards, active state backgrounds'),
      _ColorEntry('onPrimaryContainer', colors.onPrimaryContainer, colors.primaryContainer, 'Text/icons on primaryContainer'),
      _ColorEntry('primaryFixed', colors.primaryFixed, colors.onPrimaryFixed, 'Fixed primary regardless of dark/light mode'),
      _ColorEntry('onPrimaryFixed', colors.onPrimaryFixed, colors.primaryFixed, 'Text/icons on primaryFixed'),
      _ColorEntry('primaryFixedDim', colors.primaryFixedDim, colors.onPrimaryFixedVariant, 'Slightly dimmer fixed primary'),
      _ColorEntry('onPrimaryFixedVariant', colors.onPrimaryFixedVariant, colors.primaryFixedDim, 'Text/icons on primaryFixedDim'),
      // Secondary
      _ColorEntry('secondary', colors.secondary, colors.onSecondary, 'Complementary accents, chips, filters'),
      _ColorEntry('onSecondary', colors.onSecondary, colors.secondary, 'Text/icons on secondary'),
      _ColorEntry('secondaryContainer', colors.secondaryContainer, colors.onSecondaryContainer, 'Container for secondary components'),
      _ColorEntry('onSecondaryContainer', colors.onSecondaryContainer, colors.secondaryContainer, 'Text/icons on secondaryContainer'),
      _ColorEntry('secondaryFixed', colors.secondaryFixed, colors.onSecondaryFixed, 'Fixed secondary regardless of mode'),
      _ColorEntry('onSecondaryFixed', colors.onSecondaryFixed, colors.secondaryFixed, 'Text/icons on secondaryFixed'),
      _ColorEntry('secondaryFixedDim', colors.secondaryFixedDim, colors.onSecondaryFixedVariant, 'Dimmer fixed secondary'),
      _ColorEntry('onSecondaryFixedVariant', colors.onSecondaryFixedVariant, colors.secondaryFixedDim, 'Text/icons on secondaryFixedDim'),
      // Tertiary
      _ColorEntry('tertiary', colors.tertiary, colors.onTertiary, 'Contrasting accents for balancing primary & secondary'),
      _ColorEntry('onTertiary', colors.onTertiary, colors.tertiary, 'Text/icons on tertiary'),
      _ColorEntry('tertiaryContainer', colors.tertiaryContainer, colors.onTertiaryContainer, 'Container for tertiary elements'),
      _ColorEntry('onTertiaryContainer', colors.onTertiaryContainer, colors.tertiaryContainer, 'Text/icons on tertiaryContainer'),
      _ColorEntry('tertiaryFixed', colors.tertiaryFixed, colors.onTertiaryFixed, 'Fixed tertiary regardless of mode'),
      _ColorEntry('onTertiaryFixed', colors.onTertiaryFixed, colors.tertiaryFixed, 'Text/icons on tertiaryFixed'),
      _ColorEntry('tertiaryFixedDim', colors.tertiaryFixedDim, colors.onTertiaryFixedVariant, 'Dimmer fixed tertiary'),
      _ColorEntry('onTertiaryFixedVariant', colors.onTertiaryFixedVariant, colors.tertiaryFixedDim, 'Text/icons on tertiaryFixedDim'),
      // Error
      _ColorEntry('error', colors.error, colors.onError, 'Error states, destructive actions'),
      _ColorEntry('onError', colors.onError, colors.error, 'Text/icons on error'),
      _ColorEntry('errorContainer', colors.errorContainer, colors.onErrorContainer, 'Background for error messages/banners'),
      _ColorEntry('onErrorContainer', colors.onErrorContainer, colors.errorContainer, 'Text/icons on errorContainer'),
      // Surface
      _ColorEntry('surface', colors.surface, colors.onSurface, 'Default background for Cards, Sheets, Dialogs'),
      _ColorEntry('onSurface', colors.onSurface, colors.surface, 'Primary text/icons on surface'),
      _ColorEntry('surfaceDim', colors.surfaceDim, colors.onSurface, 'Dimmer surface, used for inactive/disabled areas'),
      _ColorEntry('surfaceBright', colors.surfaceBright, colors.onSurface, 'Brighter surface for prominent containers'),
      _ColorEntry('surfaceContainerLowest', colors.surfaceContainerLowest, colors.onSurface, 'Lowest emphasis container surface'),
      _ColorEntry('surfaceContainerLow', colors.surfaceContainerLow, colors.onSurface, 'Low emphasis container surface'),
      _ColorEntry('surfaceContainer', colors.surfaceContainer, colors.onSurface, 'Default container surface'),
      _ColorEntry('surfaceContainerHigh', colors.surfaceContainerHigh, colors.onSurface, 'High emphasis container surface'),
      _ColorEntry('surfaceContainerHighest', colors.surfaceContainerHighest, colors.onSurface, 'Highest emphasis container (e.g. input fills)'),
      _ColorEntry('onSurfaceVariant', colors.onSurfaceVariant, colors.surfaceContainerHighest, 'Secondary text/icons on surface'),
      _ColorEntry('surfaceVariant', colors.surfaceVariant, colors.onSurfaceVariant, 'Subtle backgrounds, chip fills'),
      // Inverse
      _ColorEntry('inverseSurface', colors.inverseSurface, colors.onInverseSurface, 'Snackbars, tooltips (inverted surface)'),
      _ColorEntry('onInverseSurface', colors.onInverseSurface, colors.inverseSurface, 'Text/icons on inverseSurface'),
      _ColorEntry('inversePrimary', colors.inversePrimary, colors.primary, 'Primary color on inverse surface (dark/light action)'),
      // Outline
      _ColorEntry('outline', colors.outline, colors.surface, 'Borders, input field outlines, dividers'),
      _ColorEntry('outlineVariant', colors.outlineVariant, colors.onSurface, 'Subtle dividers, decorative borders'),
      // Scrim & Shadow
      _ColorEntry('scrim', colors.scrim, Colors.white, 'Modal barrier / overlay scrim color'),
      _ColorEntry('shadow', colors.shadow, Colors.white, 'Drop shadow color for elevated components'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Theme Inspector"),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          /// ── CONTROLS ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Theme Mode", style: textTheme.titleMedium),
                  DropdownButton<ThemeMode>(
                    value: themeState.themeMode,
                    isExpanded: true,
                    items: ThemeMode.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                        .toList(),
                    onChanged: (m) => notifier.changeMode(m!),
                  ),
                  const SizedBox(height: 8),
                  Text("Flex Scheme", style: textTheme.titleMedium),
                  DropdownButton<FlexScheme>(
                    value: themeState.scheme,
                    isExpanded: true,
                    items: FlexScheme.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (s) => notifier.changeScheme(s!),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Color newColor = themeState.customSeed ?? colors.primary;
                        await ColorPicker(
                          color: newColor,
                          onColorChanged: (c) => newColor = c,
                        ).showPickerDialog(context);
                        notifier.setCustomSeed(newColor);
                      },
                      child: const Text("Pick Seed Color"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text("Color Scheme  (${colorEntries.length} colors)",
              style: textTheme.titleLarge),
          const SizedBox(height: 8),

          /// ── COLOR GRID ──
          ...colorEntries.map((e) => _CompactColorTile(entry: e)),

          const SizedBox(height: 24),

          /// ── TYPOGRAPHY ──
          Text("Typography", style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Display Large", style: textTheme.displayLarge),
                  Text("Headline Medium", style: textTheme.headlineMedium),
                  Text("Title Large", style: textTheme.titleLarge),
                  Text("Body Large", style: textTheme.bodyLarge),
                  Text("Label Medium", style: textTheme.labelMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ColorEntry {
  final String name;
  final Color color;
  final Color textColor;
  final String description;

  const _ColorEntry(this.name, this.color, this.textColor, this.description);
}

class _CompactColorTile extends StatelessWidget {
  final _ColorEntry entry;

  const _CompactColorTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      height: 52,
      decoration: BoxDecoration(
        color: entry.color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.name,
              style: TextStyle(
                color: entry.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.description,
              style: TextStyle(
                color: entry.textColor.withOpacity(0.85),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: entry.textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${entry.color.value.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
              style: TextStyle(
                color: entry.textColor,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}