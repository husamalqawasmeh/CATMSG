import 'package:flutter/material.dart';
import '../models/cat_server.dart';
import '../models/cat_user.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import 'modals.dart';

class ChannelSidebar extends StatefulWidget {
  final CatBackendService backend;
  final VoidCallback? onItemSelected;

  const ChannelSidebar({
    super.key,
    required this.backend,
    this.onItemSelected,
  });

  @override
  State<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends State<ChannelSidebar> {
  final Set<String> _collapsedCategoryIds = {};

  @override
  Widget build(BuildContext context) {
    final backend = widget.backend;

    return Container(
      width: 248,
      color: CatTheme.channelSidebarBg,
      child: Column(
        children: [
          // Top Header (Server Banner or DM Header)
          _buildTopHeader(context, backend),

          // MeowCoins & Quests Quick Banner
          _buildQuestQuickBanner(context, backend),

          // Main Navigation List (Channels or DMs)
          Expanded(
            child: backend.navMode == NavMode.server
                ? _buildServerChannelsList(context, backend)
                : _buildDmsAndQuestsSidebar(context, backend),
          ),

          // Bottom Discord User Control Pod
          _buildUserControlPod(context, backend),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, CatBackendService backend) {
    if (backend.navMode == NavMode.server) {
      final server = backend.currentServer;
      return Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CatTheme.fromHex(server.bannerColorHex).withValues(alpha: 0.22),
              CatTheme.channelSidebarBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          children: [
            Text(server.iconEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                server.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CatTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: CatTheme.textSecondary,
              ),
              tooltip: 'Create Channel',
              onPressed: () {
                if (server.categories.isNotEmpty) {
                  CatModals.showCreateChannelDialog(
                    context,
                    backend,
                    defaultCategoryId: server.categories.first.id,
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Text('🐾', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text(
            'Direct Meows & Hub',
            style: TextStyle(
              color: CatTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestQuickBanner(
    BuildContext context,
    CatBackendService backend,
  ) {
    final claimable = backend.claimableQuestsCount;
    final completedCount = backend.quests.where((q) => q.isCompleted).length;
    final totalQuests = backend.quests.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          backend.openQuestsAndShop();
          widget.onItemSelected?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CatTheme.meowCoinGold.withValues(alpha: 0.18),
                CatTheme.purrple.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: claimable > 0
                  ? CatTheme.meowCoinGold
                  : Colors.white.withValues(alpha: 0.08),
              width: claimable > 0 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${backend.currentUser.meowCoins} MeowCoins',
                          style: const TextStyle(
                            color: CatTheme.meowCoinGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$completedCount/$totalQuests Quests',
                          style: const TextStyle(
                            color: CatTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      claimable > 0
                          ? '🎁 $claimable quest reward${claimable > 1 ? 's' : ''} ready to claim!'
                          : 'Complete daily cat quests & unlock stickers!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: claimable > 0
                            ? CatTheme.catnipMint
                            : CatTheme.textMuted,
                        fontSize: 11,
                        fontWeight:
                            claimable > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerChannelsList(
    BuildContext context,
    CatBackendService backend,
  ) {
    final server = backend.currentServer;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: server.categories.length,
      itemBuilder: (context, index) {
        final ChannelCategory category = server.categories[index];
        final isCollapsed = _collapsedCategoryIds.contains(category.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() {
                  if (isCollapsed) {
                    _collapsedCategoryIds.remove(category.id);
                  } else {
                    _collapsedCategoryIds.add(category.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_right_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: CatTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        category.name.toUpperCase(),
                        style: const TextStyle(
                          color: CatTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => CatModals.showCreateChannelDialog(
                        context,
                        backend,
                        defaultCategoryId: category.id,
                      ),
                      child: const Tooltip(
                        message: 'Add Channel to Category',
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: CatTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isCollapsed)
              ...category.channels.map((channel) {
                final isSelected = backend.navMode == NavMode.server &&
                    backend.selectedChannelId == channel.id;
                return _ChannelTile(
                  channel: channel,
                  isSelected: isSelected,
                  onTap: () {
                    backend.selectChannel(channel.id);
                    widget.onItemSelected?.call();
                  },
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildDmsAndQuestsSidebar(
    BuildContext context,
    CatBackendService backend,
  ) {
    final friends = backend.friendsList;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      children: [
        // Friends Tab Button
        _NavBannerTile(
          iconEmoji: '🐱',
          title: 'Cat Friends',
          subtitle: '${friends.length} friends in your litter',
          isSelected: backend.navMode == NavMode.dms &&
              backend.dmSubView == DmSubView.friends,
          accentColor: CatTheme.pawPink,
          onTap: () {
            backend.openDmsHome();
            widget.onItemSelected?.call();
          },
        ),
        const SizedBox(height: 6),

        // Quests & MeowCoin Shop Button
        _NavBannerTile(
          iconEmoji: '🪙',
          title: 'Quests & Emporium',
          subtitle: 'Earn MeowCoins & unlock stickers',
          isSelected: backend.navMode == NavMode.quests,
          accentColor: CatTheme.meowCoinGold,
          badgeCount: backend.claimableQuestsCount,
          onTap: () {
            backend.openQuestsAndShop();
            widget.onItemSelected?.call();
          },
        ),

        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              const Text(
                'DIRECT MEOWS',
                style: TextStyle(
                  color: CatTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  backend.openDmsHome();
                  widget.onItemSelected?.call();
                },
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 15,
                  color: CatTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        ...friends.map((CatUser friend) {
          final isSelected = backend.navMode == NavMode.dms &&
              backend.dmSubView == DmSubView.conversation &&
              backend.selectedDmUserId == friend.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: isSelected
                  ? CatTheme.pawPink.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  backend.openDmConversation(friend.id);
                  widget.onItemSelected?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: CatTheme.fromHex(
                              friend.avatarColorHex,
                            ).withValues(alpha: 0.25),
                            child: Text(
                              friend.avatarEmoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: friend.presence.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CatTheme.channelSidebarBg,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? CatTheme.textPrimary
                                    : CatTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              friend.customStatus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CatTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUserControlPod(
    BuildContext context,
    CatBackendService backend,
  ) {
    final user = backend.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: CatTheme.userPodBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Avatar + Status Picker Menu
          PopupMenuButton<CatPresence>(
            tooltip: 'Change Cat Presence Status',
            color: CatTheme.cardBg,
            onSelected: (presence) => backend.updatePresence(presence),
            itemBuilder: (context) => CatPresence.values
                .map(
                  (p) => PopupMenuItem<CatPresence>(
                    value: p,
                    child: Row(
                      children: [
                        Text(p.iconEmoji),
                        const SizedBox(width: 8),
                        Text(
                          p.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CatTheme.fromHex(user.avatarColorHex)
                      .withValues(alpha: 0.28),
                  child: Text(
                    user.avatarEmoji,
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: user.presence.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: CatTheme.userPodBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => CatModals.showEditProfileDialog(context, backend),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CatTheme.meowCoinGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: CatTheme.meowCoinGold,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          backend.isArabic ? '👑 المالك' : '👑 OWNER',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    user.presence.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: user.presence.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit Cat Profile & Badges',
            icon: const Icon(
              Icons.tune_rounded,
              size: 19,
              color: CatTheme.textSecondary,
            ),
            onPressed: () => CatModals.showEditProfileDialog(context, backend),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final CatChannel channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: isSelected
            ? CatTheme.pawPink.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Text(
                  channel.prefixEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? CatTheme.textPrimary
                          : CatTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBannerTile extends StatelessWidget {
  final String iconEmoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBannerTile({
    required this.iconEmoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: 0.18)
          : CatTheme.cardBg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Text(iconEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? CatTheme.textPrimary
                            : CatTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: CatTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CatTheme.tunaCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
