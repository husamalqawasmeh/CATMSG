import 'package:flutter/material.dart';
import '../models/cat_message.dart';
import '../models/cat_quest.dart';
import '../models/cat_user.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import 'modals.dart';

class FriendsDashboardView extends StatefulWidget {
  final CatBackendService backend;
  final bool isCompact;
  final VoidCallback onOpenLeftDrawer;

  const FriendsDashboardView({
    super.key,
    required this.backend,
    required this.isCompact,
    required this.onOpenLeftDrawer,
  });

  @override
  State<FriendsDashboardView> createState() => _FriendsDashboardViewState();
}

class _FriendsDashboardViewState extends State<FriendsDashboardView> {
  String _tab = 'online'; // 'online', 'all', 'add'
  final TextEditingController _addFriendController = TextEditingController();

  @override
  void dispose() {
    _addFriendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = widget.backend;
    final allFriends = backend.friendsList;
    final onlineFriends = allFriends
        .where((u) => u.presence != CatPresence.stray)
        .toList();

    final displayedFriends = _tab == 'online' ? onlineFriends : allFriends;

    return Container(
      color: CatTheme.chatFeedBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Friends Header Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Row(
              children: [
                if (widget.isCompact)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: widget.onOpenLeftDrawer,
                  ),
                const Text('🐾', style: TextStyle(fontSize: 19)),
                const SizedBox(width: 8),
                const Text(
                  'Cat Friends',
                  style: TextStyle(
                    color: CatTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                _TabPill(
                  label: 'Online (${onlineFriends.length})',
                  isSelected: _tab == 'online',
                  onTap: () => setState(() => _tab = 'online'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: 'All Cats (${allFriends.length})',
                  isSelected: _tab == 'all',
                  onTap: () => setState(() => _tab = 'all'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: '+ Add Cat Friend',
                  isSelected: _tab == 'add',
                  accentColor: CatTheme.catnipMint,
                  onTap: () => setState(() => _tab = 'add'),
                ),
              ],
            ),
          ),

          if (_tab == 'add')
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CatTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CatTheme.catnipMint.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADD A CAT FRIEND BY USERNAME',
                      style: TextStyle(
                        color: CatTheme.catnipMint,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter an existing cat\'s name (like Biscuit) or type any new cat name to invite them to your litter!',
                      style: TextStyle(
                        color: CatTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addFriendController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Biscuit, Luna, WhiskersMcGee...',
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                backend.addFriendByUsername(val);
                                _addFriendController.clear();
                                setState(() => _tab = 'all');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: CatTheme.catnipMint,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            final text = _addFriendController.text;
                            if (text.trim().isNotEmpty) {
                              backend.addFriendByUsername(text);
                              _addFriendController.clear();
                              setState(() => _tab = 'all');
                            }
                          },
                          icon: const Icon(Icons.pets_rounded, size: 17),
                          label: const Text(
                            'Send Boop Request',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: displayedFriends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final friend = displayedFriends[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CatTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor:
                                CatTheme.fromHex(friend.avatarColorHex)
                                    .withValues(alpha: 0.25),
                            child: Text(
                              friend.avatarEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: friend.presence.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CatTheme.cardBg,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  friend.displayName,
                                  style: const TextStyle(
                                    color: CatTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '@${friend.username}',
                                  style: const TextStyle(
                                    color: CatTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (friend.equippedBadge != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CatTheme.purrple
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      friend.equippedBadge!,
                                      style: const TextStyle(
                                        color: CatTheme.textPrimary,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${friend.presence.iconEmoji} ${friend.presence.shortLabel} • ${friend.customStatus}',
                              style: const TextStyle(
                                color: CatTheme.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Inspect Cat Profile',
                        onPressed: () => CatModals.showUserProfileModal(
                          context,
                          backend,
                          friend,
                        ),
                        icon: const Icon(
                          Icons.badge_outlined,
                          color: CatTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: CatTheme.pawPink,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => backend.openDmConversation(friend.id),
                        icon: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Direct Meow',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuestsAndShopView extends StatelessWidget {
  final CatBackendService backend;
  final bool isCompact;
  final VoidCallback onOpenLeftDrawer;

  const QuestsAndShopView({
    super.key,
    required this.backend,
    required this.isCompact,
    required this.onOpenLeftDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final user = backend.currentUser;
    final quests = backend.quests;
    final completedQuests = quests.where((q) => q.isCompleted).length;

    return Container(
      color: CatTheme.chatFeedBg,
      child: Column(
        children: [
          // Top Header Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Row(
              children: [
                if (isCompact)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: onOpenLeftDrawer,
                  ),
                const Text('🪙', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Cat Quests & MeowCoin Emporium',
                  style: TextStyle(
                    color: CatTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CatTheme.meowCoinGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: CatTheme.meowCoinGold),
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        '${user.meowCoins} MeowCoins',
                        style: const TextStyle(
                          color: CatTheme.meowCoinGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CatTheme.meowCoinGold.withValues(alpha: 0.22),
                        CatTheme.pawPink.withValues(alpha: 0.18),
                        CatTheme.purrple.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CatTheme.meowCoinGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: CatTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '🏆🐱',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Paws & Whisker Quests',
                              style: TextStyle(
                                color: CatTheme.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Chat in Cat Houses, react with paws, reply to friends, and send Cat Stickers to earn MeowCoins! Spend your coins below on exclusive stickers and royal badges.',
                              style: TextStyle(
                                color: CatTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: quests.isEmpty
                                          ? 0
                                          : completedQuests / quests.length,
                                      minHeight: 8,
                                      backgroundColor: CatTheme.serverRailBg,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        CatTheme.meowCoinGold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$completedQuests / ${quests.length} Completed',
                                  style: const TextStyle(
                                    color: CatTheme.meowCoinGold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  '🎯 ACTIVE CAT QUESTS',
                  style: TextStyle(
                    color: CatTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Quests List
                ...quests.map((quest) => _QuestCard(
                      quest: quest,
                      onClaim: () => backend.claimQuestReward(quest.id),
                    )),

                const SizedBox(height: 28),
                const Text(
                  '🛍️ MEOWCOIN EMPORIUM — UNLOCK CAT STICKERS',
                  style: TextStyle(
                    color: CatTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: CatSticker.catalog.map((sticker) {
                    final isOwned =
                        user.unlockedStickerIds.contains(sticker.id);
                    final color = CatTheme.fromHex(sticker.bgHex);

                    return Container(
                      width: 215,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CatTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOwned
                              ? CatTheme.catnipMint.withValues(alpha: 0.5)
                              : color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sticker.artEmoji,
                            style: const TextStyle(fontSize: 34),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sticker.name,
                            style: const TextStyle(
                              color: CatTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sticker.caption,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: isOwned
                                ? OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: CatTheme.catnipMint,
                                    ),
                                    label: const Text(
                                      'Unlocked',
                                      style: TextStyle(
                                        color: CatTheme.catnipMint,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: CatTheme.meowCoinGold,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () =>
                                        backend.unlockSticker(sticker),
                                    icon: const Text(
                                      '🪙',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    label: Text(
                                      'Unlock (${sticker.priceCoins})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),
                const Text(
                  '👑 ROYAL PROFILE BADGES (DISPLAYED NEXT TO YOUR NAME IN CHAT)',
                  style: TextStyle(
                    color: CatTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                ...BadgeShopItem.catalog.map((badge) {
                  final isOwned =
                      user.unlockedBadges.contains(badge.badgeTitle);
                  final isEquipped = user.equippedBadge == badge.badgeTitle;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CatTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEquipped
                            ? CatTheme.pawPink
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: CatTheme.purrple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge.badgeTitle,
                            style: const TextStyle(
                              color: CatTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            badge.description,
                            style: const TextStyle(
                              color: CatTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isEquipped
                                ? CatTheme.catnipMint
                                : (isOwned
                                    ? CatTheme.purrple
                                    : CatTheme.meowCoinGold),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: isEquipped
                              ? null
                              : () => backend.purchaseOrEquipBadge(badge),
                          child: Text(
                            isEquipped
                                ? 'Equipped ✓'
                                : (isOwned
                                    ? 'Equip Badge'
                                    : '🪙 ${badge.priceCoins} Buy'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final CatQuest quest;
  final VoidCallback onClaim;

  const _QuestCard({
    required this.quest,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isClaimable = quest.isClaimable;
    final isClaimed = quest.isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimable
              ? CatTheme.meowCoinGold
              : (isClaimed
                  ? CatTheme.catnipMint.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06)),
          width: isClaimable ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CatTheme.channelSidebarBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(quest.iconEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        color: CatTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CatTheme.purrple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quest.category,
                        style: const TextStyle(
                          color: CatTheme.purrple,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest.description,
                  style: const TextStyle(
                    color: CatTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: quest.progressRatio,
                          minHeight: 7,
                          backgroundColor: CatTheme.serverRailBg,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            quest.isCompleted
                                ? CatTheme.catnipMint
                                : CatTheme.pawPink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${quest.currentProgress} / ${quest.targetCount}',
                      style: const TextStyle(
                        color: CatTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: CatTheme.catnipMint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '✓ Claimed',
                style: TextStyle(
                  color: CatTheme.catnipMint,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            )
          else if (isClaimable)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: CatTheme.meowCoinGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: onClaim,
              icon: const Text('🪙', style: TextStyle(fontSize: 15)),
              label: Text(
                'Claim +${quest.rewardCoins}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CatTheme.channelSidebarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🪙 +${quest.rewardCoins}',
                style: const TextStyle(
                  color: CatTheme.meowCoinGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    this.accentColor = CatTheme.pawPink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accentColor : CatTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
