import 'package:flutter/material.dart';

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
    );
  }
}

class ChoiceChipGroup extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option),
              selected: option == selected,
              onSelected: (_) => onSelected(option),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: option == selected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
            ),
          )
          .toList(),
    );
  }
}

class FilterChipGroup extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
  });

  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            final updated = [...selectedValues];
            if (value) {
              if (!updated.contains(option)) {
                updated.add(option);
              }
            } else {
              updated.remove(option);
            }
            onSelectionChanged(updated);
          },
          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
        );
      }).toList(),
    );
  }
}
