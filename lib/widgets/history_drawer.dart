import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../blocs/chat_bloc.dart';
import '../blocs/chat_event.dart';
import '../blocs/chat_state.dart';
import '../models/conversation.dart';

class HistoryDrawer extends StatefulWidget {
  const HistoryDrawer({super.key});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────

  void _newChat() {
    context.read<ChatBloc>().add(const NewChatEvent());
    Navigator.of(context).pop();
  }

  void _open(Conversation c) {
    context.read<ChatBloc>().add(SelectChatEvent(c.id));
    Navigator.of(context).pop();
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  Future<void> _deleteChat(Conversation c) async {
    final bloc = context.read<ChatBloc>();
    final ok = await _confirm(
      title: 'Delete chat?',
      body: '"${c.title}" will be permanently deleted.',
      action: 'Delete',
    );
    if (ok) bloc.add(DeleteChatEvent(c.id));
  }

  Future<void> _deleteAll() async {
    final bloc = context.read<ChatBloc>();
    final ok = await _confirm(
      title: 'Delete all chats?',
      body: 'Your whole chat history will be permanently deleted.',
      action: 'Delete all',
    );
    if (ok) bloc.add(const ClearAllChatsEvent());
  }

  Future<void> _renameChat(Conversation c) async {
    final bloc = context.read<ChatBloc>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: c.title),
    );
    if (name != null && name.trim().isNotEmpty) {
      bloc.add(RenameChatEvent(c.id, name));
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
              child: Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: scheme.onPrimary,
                      size: 18.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Chat history',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _newChat,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New chat'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (p, c) =>
                    p.conversations != c.conversations ||
                    p.activeId != c.activeId ||
                    p.loaded != c.loaded,
                builder: (context, state) => _buildList(state, scheme),
              ),
            ),
            const Divider(height: 1),
            BlocSelector<ChatBloc, ChatState, bool>(
              selector: (s) => s.conversations.isNotEmpty,
              builder: (context, hasChats) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: TextButton.icon(
                  onPressed: hasChats ? _deleteAll : null,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Delete all chats'),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    alignment: Alignment.centerLeft,
                    minimumSize: Size.fromHeight(44.h),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ChatState state, ColorScheme scheme) {
    final q = _query.trim().toLowerCase();
    final items = state.conversations.where((c) {
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.messages.any((m) => m.text.toLowerCase().contains(q));
    }).toList();

    if (items.isEmpty) {
      final text = state.conversations.isEmpty
          ? 'No chats yet.\nYour conversations will show up here.'
          : 'No chats match "$_query".';
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Chats are sorted newest-first, so each date group is contiguous.
    final rows = <Object>[];
    String? lastGroup;
    for (final c in items) {
      final group = _groupOf(c.updatedAt);
      if (group != lastGroup) {
        rows.add(group);
        lastGroup = group;
      }
      rows.add(c);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 8.h),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row is String) {
          return Padding(
            padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 6.h),
            child: Text(
              row.toUpperCase(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final c = row as Conversation;
        return _ChatTile(
          conversation: c,
          selected: c.id == state.activeId,
          onTap: () => _open(c),
          onRename: () => _renameChat(c),
          onDelete: () => _deleteChat(c),
          confirmSwipe: () => _confirm(
            title: 'Delete chat?',
            body: '"${c.title}" will be permanently deleted.',
            action: 'Delete',
          ),
          onSwiped: () => context.read<ChatBloc>().add(DeleteChatEvent(c.id)),
        );
      },
    );
  }

  String _groupOf(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'Previous 7 days';
    return 'Older';
  }
}

class _ChatTile extends StatelessWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap, onRename, onDelete, onSwiped;
  final Future<bool> Function() confirmSwipe;

  const _ChatTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onSwiped,
    required this.confirmSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last =
        conversation.messages.isEmpty ? null : conversation.messages.last;
    final preview = last == null
        ? 'No messages'
        : last.text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Dismissible(
        key: ValueKey(conversation.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmSwipe(),
        onDismissed: (_) => onSwiped(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: scheme.onErrorContainer),
        ),
        child: ListTile(
          selected: selected,
          selectedTileColor: scheme.primary.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          contentPadding: EdgeInsets.only(left: 14.w, right: 2.w),
          onTap: onTap,
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp, color: scheme.onSurfaceVariant),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Chat options',
            icon: Icon(Icons.more_vert_rounded,
                size: 20, color: scheme.onSurfaceVariant),
            onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Rename'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: Text('Delete', style: TextStyle(color: scheme.error)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns its own controller so it is disposed safely with the dialog.
class _RenameDialog extends StatefulWidget {
  final String initial;

  const _RenameDialog({required this.initial});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
