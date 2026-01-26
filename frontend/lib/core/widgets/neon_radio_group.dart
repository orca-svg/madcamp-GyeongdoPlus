import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NeonRadioOption<T> {
  final T value;
  final String label;
  final Color? color;

  const NeonRadioOption({
    required this.value,
    required this.label,
    this.color,
  });
}

class NeonRadioGroup<T> extends StatelessWidget {
  final T value;
  final List<NeonRadioOption<T>> options;
  final ValueChanged<T> onChanged;
  final double height;
  final double radius;

  const NeonRadioGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.height = 44,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.outlineLow),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: _NeonRadioItem<T>(
                option: opt,
                selected: opt.value == value,
                onTap: () => onChanged(opt.value),
                radius: radius - 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _NeonRadioItem<T> extends StatelessWidget {
  final NeonRadioOption<T> option;
  final bool selected;
  final VoidCallback onTap;
  final double radius;

  const _NeonRadioItem({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final color = option.color ?? AppColors.borderCyan;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.22),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
