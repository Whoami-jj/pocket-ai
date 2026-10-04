import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../blocs/chat_bloc.dart';
import '../blocs/chat_event.dart';
import '../blocs/chat_state.dart';
import '../blocs/theme_cubit.dart';
import '../models/message_model.dart';
import '../widgets/history_drawer.dart';

const _suggestions = <({IconData icon, String label, String prompt})>[
  (
    icon: Icons.wb_sunny_outlined,
    label: 'Weather in Lahore',
    prompt: "What's the weather in Lahore?",
  ),
  (
    icon: Icons.cloud_outlined,
    label: 'Weather in London',
    prompt: "What's the weather in London?",
  ),
  (
    icon: Icons.calculate_outlined,
    label: '45 × 12',
    prompt: "What's 45 * 12?",
  ),
  (
    icon: Icons.functions_rounded,
    label: '(18 + 7) ^ 2',
    prompt: 'Calculate (18 + 7) ^ 2',
  ),
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  String? _lastActiveId;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const LoadChatsEvent());
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final bloc = context.read<ChatBloc>();
    if (bloc.state.isLoading) return;
    final text = (preset ?? _text.text).trim();
    if (text.isEmpty) return;
    bloc.add(SendMessageEvent(text));
    if (preset == null) {
      _text.clear();
      _focus.requestFocus();
    }
  }

  void _scrollToEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(scheme, isDark),
      drawer: const HistoryDrawer(),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 1.0,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.16 : 0.09),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(child: _buildMessages(scheme)),
                _buildComposer(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme scheme, bool isDark) {
    return AppBar(
      titleSpacing: 4.w,
      title: Row(
        children: [
          _GradientIcon(size: 38.w, radius: 12.r, iconSize: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'PocketAI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        'Gemini · weather & math tools',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        BlocSelector<ChatBloc, ChatState, bool>(
          selector: (s) => s.activeId != null,
          builder: (context, inChat) {
            if (!inChat) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () =>
                  context.read<ChatBloc>().add(const NewChatEvent()),
            );
          },
        ),
        IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () =>
              context.read<ThemeCubit>().toggle(Theme.of(context).brightness),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }

  Widget _buildMessages(ColorScheme scheme) {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (p, c) =>
          p.activeId != c.activeId ||
          p.messages.length != c.messages.length ||
          p.isActiveLoading != c.isActiveLoading,
      listener: (_, state) {
        final switched = state.activeId != _lastActiveId;
        _lastActiveId = state.activeId;
        _scrollToEnd(jump: switched);
      },
      builder: (context, state) {
        if (state.messages.isEmpty && !state.isActiveLoading) {
          return _EmptyState(onPick: _send);
        }
        final count = state.messages.length + (state.isActiveLoading ? 1 : 0);
        return ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          itemCount: count,
          itemBuilder: (context, i) {
            if (i == state.messages.length) return const _TypingBubble();
            return _Appear(child: _Bubble(message: state.messages[i]));
          },
        );
      },
    );
  }

  Widget _buildComposer(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 12.h),
        child: Container(
          padding: EdgeInsets.fromLTRB(18.w, 4.h, 6.w, 4.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.enter): () =>
                        _send(),
                  },
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Ask about weather or math…',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: scheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (p, c) => p.isLoading != c.isLoading,
                  builder: (context, state) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _text,
                      builder: (_, value, __) => _SendButton(
                        enabled:
                            value.text.trim().isNotEmpty && !state.isLoading,
                        onTap: _send,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  final double size, radius, iconSize;

  const _GradientIcon({
    required this.size,
    required this.radius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.auto_awesome, color: scheme.onPrimary, size: iconSize),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _EmptyState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: scheme.onPrimary,
                size: 34.w,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Hi, I'm PocketAI",
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            Text(
              'I can look up live weather and solve maths.\nTry one of these:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _suggestions)
                  _SuggestionChip(
                    icon: s.icon,
                    label: s.label,
                    onTap: () => onPick(s.prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.w, color: scheme.primary),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.sender == Sender.user;
    final isError = message.isError;
    final fg = isError
        ? scheme.onErrorContainer
        : (isUser ? scheme.onPrimary : scheme.onSurface);
    final maxWidth = math.min(MediaQuery.sizeOf(context).width * 0.78, 520.0);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      decoration: BoxDecoration(
        gradient: (isUser && !isError)
            ? LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isError
            ? scheme.errorContainer
            : (isUser ? null : scheme.surfaceContainerHigh),
        border: (!isUser && !isError)
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6))
            : null,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
          bottomLeft: Radius.circular(isUser ? 18.r : 4.r),
          bottomRight: Radius.circular(isUser ? 4.r : 18.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.tool != null) ...[
            _ToolBadge(tool: message.tool!),
            SizedBox(height: 8.h),
          ],
          SelectableText(
            message.text,
            style: TextStyle(fontSize: 14.sp, height: 1.4, color: fg),
          ),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              TimeOfDay.fromDateTime(message.createdAt).format(context),
              style: TextStyle(
                fontSize: 10.sp,
                color: fg.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _GradientIcon(size: 28.w, radius: 14.r, iconSize: 15.w),
            SizedBox(width: 8.w),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _ToolBadge extends StatelessWidget {
  final String tool;

  const _ToolBadge({required this.tool});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon) = switch (tool) {
      'weather' => ('Weather tool', Icons.cloud_outlined),
      'calculate' => ('Calculator tool', Icons.calculate_outlined),
      _ => ('Tool', Icons.build_outlined),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: scheme.primary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _wave(int i) {
    final t = (_c.value - i * 0.18) % 1.0;
    return (math.sin(t * 2 * math.pi) + 1) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          _GradientIcon(size: 28.w, radius: 14.r, iconSize: 15.w),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(18.r),
              ),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.3 + 0.7 * _wave(i)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabled
            ? LinearGradient(colors: [scheme.primary, scheme.tertiary])
            : null,
        color: enabled ? null : scheme.surfaceContainerHighest,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 20.w,
            color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Appear extends StatelessWidget {
  final Widget child;

  const _Appear({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: c),
      ),
      child: child,
    );
  }
}
