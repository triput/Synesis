// ==============================================================================
// File: lib/ui/settings/account_color_picker.dart
// Description: Curated account accent swatches and custom RGB color dialog.
// Component: UI / Settings
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:flutter/material.dart';

class AccountColorPicker extends StatelessWidget {
  const AccountColorPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  static const List<Color> curatedSwatches = <Color>[
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFBE185D),
    Color(0xFFC2410C),
    Color(0xFF4D7C0F),
    Color(0xFF0369A1),
    Color(0xFFB45309),
  ];

  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final Color swatch in curatedSwatches)
          _ColorSwatch(
            color: swatch,
            selected: value.toARGB32() == swatch.toARGB32(),
            onTap: () => onChanged(swatch),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final Color? selected = await showAccountColorPickerDialog(
              context,
              initialColor: value,
            );
            if (selected != null) {
              onChanged(selected);
            }
          },
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Custom'),
        ),
      ],
    );
  }
}

Future<Color?> showAccountColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
}) {
  Color selectedColor = initialColor;
  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (
          BuildContext context,
          StateSetter setDialogState,
        ) {
          return AlertDialog(
            title: const Text('Custom account color'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RgbSlider(
                    label: 'Red',
                    value: _channel(selectedColor, 16),
                    activeColor: Colors.red,
                    onChanged: (int channel) {
                      setDialogState(
                        () => selectedColor = _replaceChannel(
                          selectedColor,
                          16,
                          channel,
                        ),
                      );
                    },
                  ),
                  _RgbSlider(
                    label: 'Green',
                    value: _channel(selectedColor, 8),
                    activeColor: Colors.green,
                    onChanged: (int channel) {
                      setDialogState(
                        () => selectedColor = _replaceChannel(
                          selectedColor,
                          8,
                          channel,
                        ),
                      );
                    },
                  ),
                  _RgbSlider(
                    label: 'Blue',
                    value: _channel(selectedColor, 0),
                    activeColor: Colors.blue,
                    onChanged: (int channel) {
                      setDialogState(
                        () => selectedColor = _replaceChannel(
                          selectedColor,
                          0,
                          channel,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selectedColor),
                child: const Text('Use color'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Account color',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}

class _RgbSlider extends StatelessWidget {
  const _RgbSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: activeColor,
            label: value.toString(),
            onChanged: (double next) => onChanged(next.round()),
          ),
        ),
        SizedBox(width: 32, child: Text(value.toString())),
      ],
    );
  }
}

int _channel(Color color, int shift) => (color.toARGB32() >> shift) & 0xFF;

Color _replaceChannel(Color color, int shift, int value) {
  final int argb = color.toARGB32();
  final int replaced = (argb & ~(0xFF << shift)) | (value << shift);
  return Color(replaced);
}
