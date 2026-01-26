import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/room_provider.dart';

class RoomJoinScreen extends ConsumerStatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  ConsumerState<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends ConsumerState<RoomJoinScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('방 참여하기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Center(
              child: GlowCard(
                glow: false,
                borderColor: AppColors.outlineLow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '방 코드로 참여',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이번 단계에서는 WS 없이도 로비 UI를 확인할 수 있도록 오프라인 참여만 제공합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: '방 코드',
                        hintText: '예: ABCD12',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _join(context),
                      decoration: const InputDecoration(
                        labelText: '닉네임(선택)',
                        hintText: '예: 김선수',
                      ),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      variant: GradientButtonVariant.joinRoom,
                      title: '참여',
                      height: 56,
                      borderRadius: 16,
                      onPressed: () => _join(context),
                      leading: const Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      showAppSnackBar(context, message: '방 코드를 입력하세요', isError: true);
      return;
    }

    ref
        .read(roomProvider.notifier)
        .joinRoom(myName: _nameCtrl.text, code: code);
    ref.read(gamePhaseProvider.notifier).toLobby();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
