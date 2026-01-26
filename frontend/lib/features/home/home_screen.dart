import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/delta_chip.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/room_provider.dart';
import '../room/room_create_screen.dart';
import '../room/room_join_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Intentionally always false (this stage): keep legacy widgets without deleting them.
    final bool showLegacy = DateTime.now().millisecondsSinceEpoch < 0;
    final phase = ref.watch(gamePhaseProvider);
    final bottomPad = (phase == GamePhase.offGame)
        ? AppDimens.bottomBarHOff
        : AppDimens.bottomBarHIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad + 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '방 시작하기',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        variant: GradientButtonVariant.createRoom,
                        title: '방 만들기',
                        height: 56,
                        borderRadius: 16,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RoomCreateScreen(),
                            ),
                          );
                        },
                        leading: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        title: '방 참여하기',
                        height: 56,
                        borderRadius: 16,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RoomJoinScreen(),
                            ),
                          );
                        },
                        leading: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '방 생성/참여 후 로비에서 규칙을 수정할 수 있어요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showLegacy) ...[
                  const SizedBox(height: 26),
                  GlowCard(
                    glowColor: AppColors.purple.withOpacity(0.35),
                    borderColor: AppColors.borderCyan.withOpacity(0.55),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '환영합니다',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.titleLarge,
                            children: const [
                              TextSpan(text: '김선수'),
                              TextSpan(
                                text: ' 님',
                                style: TextStyle(color: AppColors.borderCyan),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '시즌 12 • 다이아몬드 II',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    variant: GradientButtonVariant.createRoom,
                    title: '방 만들기',
                    onPressed: () =>
                        _showCreateRoomSheet(context: context, ref: ref),
                    leading: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    variant: GradientButtonVariant.joinRoom,
                    title: '방 참여하기',
                    onPressed: () =>
                        _showJoinRoomSheet(context: context, ref: ref),
                    leading: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('최근 활동', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _activityCard(
                    title: '승리!',
                    subtitle: '랭크 매치 • 2분 전',
                    delta: 25,
                    detail: 'K/D/A: 12/3/8',
                  ),
                  const SizedBox(height: 12),
                  _activityCard(
                    title: '승리!',
                    subtitle: '랭크 매치 • 2일 전',
                    delta: 25,
                    detail: 'K/D/A: 12/3/8',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateRoomSheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final controller = TextEditingController(text: '김선수');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _RoomSheet(
            title: '방 만들기',
            primaryTitle: '만들기',
            primaryVariant: GradientButtonVariant.createRoom,
            onPrimary: () {
              ref
                  .read(roomProvider.notifier)
                  .createRoom(myName: controller.text);
              Navigator.of(context).pop();
              ref.read(gamePhaseProvider.notifier).toLobby();
            },
            child: TextField(
              key: const Key('createRoomNameField'),
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: '닉네임',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJoinRoomSheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final codeController = TextEditingController();
    final nameController = TextEditingController(text: '김선수');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _RoomSheet(
            title: '방 참여하기',
            primaryTitle: '참여',
            primaryVariant: GradientButtonVariant.joinRoom,
            onPrimary: () {
              ref
                  .read(roomProvider.notifier)
                  .joinRoom(
                    myName: nameController.text,
                    code: codeController.text.toUpperCase(),
                  );
              Navigator.of(context).pop();
              ref.read(gamePhaseProvider.notifier).toLobby();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('joinRoomCodeField'),
                  controller: codeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '방 코드',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('joinRoomNameField'),
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activityCard({
    required String title,
    required String subtitle,
    required int delta,
    required String detail,
  }) {
    return GlowCard(
      glowColor: AppColors.borderCyan.withOpacity(0.12),
      borderColor: AppColors.borderCyan.withOpacity(0.55),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.borderCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderCyan.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DeltaChip(delta: delta.toDouble(), suffix: ' LP'),
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final String primaryTitle;
  final GradientButtonVariant primaryVariant;
  final VoidCallback onPrimary;

  const _RoomSheet({
    required this.title,
    required this.child,
    required this.primaryTitle,
    required this.primaryVariant,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlowCard(
          glow: true,
          glowColor: AppColors.borderCyan.withOpacity(0.12),
          borderColor: AppColors.borderCyan.withOpacity(0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface2.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.outlineLow.withOpacity(0.9),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: child,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      variant: primaryVariant,
                      title: primaryTitle,
                      onPressed: onPrimary,
                      leading: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
