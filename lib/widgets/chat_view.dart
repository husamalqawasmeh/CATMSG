import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cat_message.dart';
import '../models/cat_user.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import 'modals.dart';

class ChatView extends StatefulWidget {
  final CatBackendService backend;
  final bool isCompact;
  final VoidCallback onOpenLeftDrawer;
  final VoidCallback onToggleRightPanel;

  const ChatView({
    super.key,
    required this.backend,
    required this.isCompact,
    required this.onOpenLeftDrawer,
    required this.onToggleRightPanel,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showStickerPicker = false;
  bool _showSearchBar = false;

  @override
  void dispose() {
    _msgController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend({String? stickerId}) {
    final text = _msgController.text;
    if (text.trim().isEmpty && stickerId == null) return;

    widget.backend.sendMessage(
      content: text,
      stickerId: stickerId,
    );
    _msgController.clear();
    if (stickerId != null) {
      setState(() => _showStickerPicker = false);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final backend = widget.backend;
    final isDm = backend.navMode == NavMode.dms &&
        backend.dmSubView == DmSubView.conversation;
    final messages = backend.activeMessages;

    return Container(
      color: CatTheme.chatFeedBg,
      child: Column(
        children: [
          // Top Discord Channel / DM Header
          _buildTopHeader(context, backend, isDm),

          // Optional Search Filter Bar
          if (_showSearchBar) _buildSearchBar(backend),

          // Message Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildWelcomeBanner(backend, isDm);
                }
                final msg = messages[index - 1];
                return _MessageTile(
                  message: msg,
                  currentUserId: backend.currentUser.id,
                  onToggleReaction: (emoji) =>
                      backend.toggleReaction(msg.id, emoji),
                  onReply: () => backend.setReplyingTo(msg),
                  onTogglePin: () => backend.togglePinMessage(msg.id),
                );
              },
            ),
          ),

          // Expandable Cat Sticker Picker Drawer
          if (_showStickerPicker) _buildStickerPickerDrawer(backend),

          // Replying To Banner
          if (backend.replyingToMessage != null)
            _buildReplyingBanner(backend, backend.replyingToMessage!),

          // Bottom Message Composer Bar
          _buildComposerBar(backend, isDm),
        ],
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    CatBackendService backend,
    bool isDm,
  ) {
    final dmPartner = backend.currentDmPartner;
    final channel = backend.currentChannel;
    final pinnedCount = backend.activeMessages.where((m) => m.isPinned).length;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CatTheme.chatFeedBg,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          if (widget.isCompact)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: CatTheme.textPrimary),
              onPressed: widget.onOpenLeftDrawer,
            ),
          if (isDm && dmPartner != null) ...[
            Text(dmPartner.avatarEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              dmPartner.displayName,
              style: const TextStyle(
                color: CatTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: dmPartner.presence.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dmPartner.presence.shortLabel,
                style: TextStyle(
                  color: dmPartner.presence.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Text(channel.prefixEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              channel.name,
              style: const TextStyle(
                color: CatTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
            if (!widget.isCompact && channel.topic.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 18,
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: Text(
                  channel.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CatTheme.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ],
          if (isDm) const Spacer(),

          // MeowCoins Quick Pill
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: backend.openQuestsAndShop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CatTheme.meowCoinGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CatTheme.meowCoinGold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '${backend.currentUser.meowCoins}',
                    style: const TextStyle(
                      color: CatTheme.meowCoinGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Pinned Messages Button
          IconButton(
            tooltip: 'Pinned Messages ($pinnedCount)',
            icon: Badge(
              isLabelVisible: pinnedCount > 0,
              label: Text('$pinnedCount'),
              backgroundColor: CatTheme.pawPink,
              child: const Icon(
                Icons.push_pin_outlined,
                size: 20,
                color: CatTheme.textSecondary,
              ),
            ),
            onPressed: () =>
                CatModals.showPinnedMessagesModal(context, backend),
          ),

          // Search Messages Toggle
          IconButton(
            tooltip: 'Search Messages',
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
              size: 21,
              color: _showSearchBar
                  ? CatTheme.pawPink
                  : CatTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  backend.setSearchQuery('');
                }
              });
            },
          ),

          // Toggle Member List / Right Sidebar
          IconButton(
            tooltip: 'Toggle Cat Members Sidebar',
            icon: const Icon(
              Icons.people_alt_outlined,
              size: 21,
              color: CatTheme.textSecondary,
            ),
            onPressed: widget.onToggleRightPanel,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CatBackendService backend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CatTheme.channelSidebarBg,
      child: TextField(
        controller: _searchController,
        onChanged: backend.setSearchQuery,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: CatTheme.pawPink,
          ),
          hintText: 'Filter messages by keyword or cat name...',
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    backend.setSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(CatBackendService backend, bool isDm) {
    final dmPartner = backend.currentDmPartner;
    final channel = backend.currentChannel;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CatTheme.pawPink.withValues(alpha: 0.12),
            CatTheme.purrple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: CatTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isDm && dmPartner != null
                  ? dmPartner.avatarEmoji
                  : channel.prefixEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDm && dmPartner != null
                      ? 'Direct Meow with ${dmPartner.displayName}'
                      : 'Welcome to #${channel.name}!',
                  style: const TextStyle(
                    color: CatTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDm && dmPartner != null
                      ? 'This is the start of your cozy direct conversation with @${dmPartner.username}. Send a message or sticker to earn MeowCoins!'
                      : (channel.topic.isNotEmpty
                          ? channel.topic
                          : 'This is the very beginning of the #${channel.name} scratching post.'),
                  style: const TextStyle(
                    color: CatTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerPickerDrawer(CatBackendService backend) {
    final unlockedIds = backend.currentUser.unlockedStickerIds;

    return Container(
      height: 176,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CatTheme.channelSidebarBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🏷️ CAT STICKERS & EMOTES',
                style: TextStyle(
                  color: CatTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: backend.openQuestsAndShop,
                icon: const Text('🪙', style: TextStyle(fontSize: 13)),
                label: Text(
                  'Unlock More (${backend.currentUser.meowCoins} Coins)',
                  style: const TextStyle(
                    color: CatTheme.meowCoinGold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CatSticker.catalog.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final sticker = CatSticker.catalog[index];
                final isUnlocked = unlockedIds.contains(sticker.id);
                final bgColor = CatTheme.fromHex(sticker.bgHex);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (isUnlocked) {
                      _handleSend(stickerId: sticker.id);
                    } else {
                      backend.unlockSticker(sticker);
                    }
                  },
                  child: Container(
                    width: 132,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: isUnlocked ? 0.22 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnlocked
                            ? bgColor.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sticker.artEmoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          sticker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CatTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isUnlocked)
                          const Text(
                            'Tap to Send',
                            style: TextStyle(
                              color: CatTheme.catnipMint,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 11,
                                color: CatTheme.meowCoinGold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '🪙 ${sticker.priceCoins}',
                                style: const TextStyle(
                                  color: CatTheme.meowCoinGold,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyingBanner(
    CatBackendService backend,
    CatMessage replyTarget,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CatTheme.cardBg,
        border: Border(
          top: BorderSide(color: CatTheme.pawPink.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 17, color: CatTheme.pawPink),
          const SizedBox(width: 8),
          Text(
            'Replying to @${replyTarget.senderName}',
            style: const TextStyle(
              color: CatTheme.pawPink,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyTarget.content.isNotEmpty
                  ? replyTarget.content
                  : '[Cat Sticker]',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CatTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 17),
            onPressed: () => backend.setReplyingTo(null),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerBar(CatBackendService backend, bool isDm) {
    final hint = isDm && backend.currentDmPartner != null
        ? 'Meow at @${backend.currentDmPartner!.displayName}...'
        : 'Meow in #${backend.currentChannel.name}...';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      color: CatTheme.chatFeedBg,
      child: Row(
        children: [
          // Toggle Cat Stickers Button
          IconButton(
            tooltip: 'Send Cat Sticker / Emote',
            style: IconButton.styleFrom(
              backgroundColor: _showStickerPicker
                  ? CatTheme.pawPink.withValues(alpha: 0.25)
                  : CatTheme.chatInputBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Text('🏷️', style: TextStyle(fontSize: 18)),
            onPressed: () {
              setState(() => _showStickerPicker = !_showStickerPicker);
            },
          ),
          const SizedBox(width: 8),

          // Quick Cat Paw Emoji Insert
          IconButton(
            tooltip: 'Insert Paw & Cat Emotes',
            style: IconButton.styleFrom(
              backgroundColor: CatTheme.chatInputBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Text('🐾', style: TextStyle(fontSize: 18)),
            onPressed: () {
              _msgController.text = '${_msgController.text} 🐾😺';
              _msgController.selection = TextSelection.fromPosition(
                TextPosition(offset: _msgController.text.length),
              );
            },
          ),
          const SizedBox(width: 8),

          // Text Input Field
          Expanded(
            child: TextField(
              controller: _msgController,
              onSubmitted: (_) => _handleSend(),
              style: const TextStyle(
                color: CatTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: CatTheme.pawPink,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _handleSend,
            icon: const Icon(Icons.send_rounded, size: 17),
            label: const Text(
              'Meow',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatefulWidget {
  final CatMessage message;
  final String currentUserId;
  final ValueChanged<String> onToggleReaction;
  final VoidCallback onReply;
  final VoidCallback onTogglePin;

  const _MessageTile({
    required this.message,
    required this.currentUserId,
    required this.onToggleReaction,
    required this.onReply,
    required this.onTogglePin,
  });

  @override
  State<_MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<_MessageTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final sticker = CatSticker.byId(msg.stickerId);
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovering
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: msg.isPinned
              ? Border.all(
                  color: CatTheme.meowCoinGold.withValues(alpha: 0.35),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Reference Connector
            if (msg.replyToSenderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Row(
                  children: [
                    const Text(
                      '╭── ↩️ ',
                      style: TextStyle(
                        color: CatTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '@${msg.replyToSenderName}: ',
                      style: const TextStyle(
                        color: CatTheme.pawPink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        msg.replyToPreview ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CatTheme.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: CatTheme.fromHex(msg.senderAvatarHex)
                      .withValues(alpha: 0.25),
                  child: Text(
                    msg.senderAvatar,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
                const SizedBox(width: 12),

                // Message Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender Name + Badge + Timestamp + Action Buttons
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            msg.senderName,
                            style: TextStyle(
                              color: CatTheme.fromHex(msg.senderRoleColorHex),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          if (msg.senderBadge != null &&
                              msg.senderBadge!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CatTheme.purrple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      CatTheme.purrple.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                msg.senderBadge!,
                                style: const TextStyle(
                                  color: CatTheme.textPrimary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: CatTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (msg.isPinned)
                            const Text(
                              '📌 Pinned',
                              style: TextStyle(
                                color: CatTheme.meowCoinGold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),

                      if (msg.content.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          msg.content,
                          style: const TextStyle(
                            color: CatTheme.textPrimary,
                            fontSize: 14,
                            height: 1.38,
                          ),
                        ),
                      ],

                      // Custom Cat Sticker Card
                      if (sticker != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: 210,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CatTheme.fromHex(sticker.bgHex)
                                    .withValues(alpha: 0.32),
                                CatTheme.cardBg,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CatTheme.fromHex(sticker.bgHex)
                                  .withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                sticker.artEmoji,
                                style: const TextStyle(fontSize: 38),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sticker.caption,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: CatTheme.fromHex(sticker.bgHex),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Cat Reactions Bar + Quick Action Buttons
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...msg.reactions.entries.map((entry) {
                            final emoji = entry.key;
                            final userIds = entry.value;
                            final hasReacted =
                                userIds.contains(widget.currentUserId);

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onToggleReaction(emoji),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hasReacted
                                      ? CatTheme.pawPink.withValues(alpha: 0.22)
                                      : CatTheme.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasReacted
                                        ? CatTheme.pawPink
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${userIds.length}',
                                      style: TextStyle(
                                        color: hasReacted
                                            ? CatTheme.pawPink
                                            : CatTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Add Reaction Popup Button
                          PopupMenuButton<String>(
                            tooltip: 'React with Cat Emoji',
                            color: CatTheme.cardBg,
                            onSelected: widget.onToggleReaction,
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Wrap(
                                  spacing: 8,
                                  children: CatMessage.reactionPalette
                                      .map(
                                        (emoji) => InkWell(
                                          onTap: () {
                                            Navigator.pop(context, emoji);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CatTheme.cardBg.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '+ 🐾',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: CatTheme.textMuted,
                                ),
                              ),
                            ),
                          ),

                          // Reply Action
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onReply,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.reply_rounded,
                                    size: 14,
                                    color: CatTheme.textMuted,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Reply',
                                    style: TextStyle(
                                      color: CatTheme.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Pin Action
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onTogglePin,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              child: Text(
                                msg.isPinned ? 'Unpin' : 'Pin',
                                style: const TextStyle(
                                  color: CatTheme.textMuted,
                                  fontSize: 11.5,
                                ),
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
          ],
        ),
      ),
    );
  }
}
