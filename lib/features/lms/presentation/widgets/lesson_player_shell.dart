import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Scaffold used for every non-playing state of the lesson screen — loading,
/// error, and locked — so they all share one chrome.
class LessonPlayerShell extends StatelessWidget {
  const LessonPlayerShell({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            title ?? LocaleKeys.app_name.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(child: child),
      );
}
