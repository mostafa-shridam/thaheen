import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Filter box above the course list.
///
/// Stateless on purpose: the text lives in the controller its parent owns, so
/// typing never rebuilds anything above this field.
class CourseSearchField extends StatelessWidget {
  const CourseSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: LocaleKeys.courses_searchHint.tr(),
        hintStyle: theme.textTheme.bodySmall,
        // `prefixIcon` is direction-aware: it renders on the right in Arabic.
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: theme.palette.textSecondary,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: theme.palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: theme.palette.border),
        ),
      ),
    );
  }
}
