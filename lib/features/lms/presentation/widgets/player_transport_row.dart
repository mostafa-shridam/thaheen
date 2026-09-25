import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_play_button.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_skip_button.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Rewind / play / forward. A `Row`, so Arabic puts rewind on the right.
class PlayerTransportRow extends StatelessWidget {
  const PlayerTransportRow({
    super.key,
    required this.isPlaying,
    required this.isFinished,
    required this.onTogglePlay,
    required this.onRewind,
    required this.onForward,
  });

  final bool isPlaying;
  final bool isFinished;
  final VoidCallback onTogglePlay;
  final VoidCallback onRewind;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        PlayerSkipButton(
          icon: Icons.replay_10_rounded,
          tooltip: LocaleKeys.player_rewind.tr(),
          onPressed: onRewind,
        ),
        const SizedBox(width: 18),
        PlayerPlayButton(
          isPlaying: isPlaying,
          isFinished: isFinished,
          onPressed: onTogglePlay,
        ),
        const SizedBox(width: 18),
        PlayerSkipButton(
          icon: Icons.forward_10_rounded,
          tooltip: LocaleKeys.player_forward.tr(),
          onPressed: onForward,
        ),
      ],
    );
  }
}
