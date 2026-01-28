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
  bool _submitting = false;

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
                      '서버 연결이 어려운 경우, 코드 "TEST"를 입력하면 오프라인 모드로 로비를 테스트할 수 있습니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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
                        LengthLimitingTextInputFormatter(12), // RELAXED LIMIT
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
                      title: _submitting ? '참여 중...' : '참여',
                      height: 56,
                      borderRadius: 16,
                      onPressed: _submitting ? null : () => _join(context),
                      leading: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
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
    if (_submitting) return;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      debugPrint('[ROOM] join fail/error=EMPTY_CODE');
      showAppSnackBar(context, message: '방 코드를 입력하세요', isError: true);
      return;
    }
    final valid = RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(code);
    if (!valid) {
      debugPrint('[ROOM] join fail/error=INVALID_CODE_FORMAT');
      showAppSnackBar(
        context,
        message: '방 코드는 4~12자 영문/숫자여야 합니다',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    final success = await ref
        .read(roomProvider.notifier)
        .joinRoom(myName: _nameCtrl.text, code: code);
    if (!context.mounted) return;
    if (success) {
      ref.read(gamePhaseProvider.notifier).toLobby();
      Navigator.of(context).pop();
    } else {
      final roomState = ref.read(roomProvider);
      showAppSnackBar(
        context,
        message: roomState.errorMessage ?? '방 참여에 실패했습니다',
        isError: true,
      );
    }
    setState(() => _submitting = false);
  }
}
