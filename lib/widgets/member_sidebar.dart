import 'package:flutter/material.dart';
import '../models/cat_user.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import 'modals.dart';

class MemberSidebar extends StatelessWidget {
  final CatBackendService backend;

  const MemberSidebar({
    super.key,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    final isDm = backend.navMode == NavMode.dms &&
        backend.dmSubView == DmSubView.conversation &&
        backend.currentDmPartner != null;

    return Container(
      width: 256,
      color: CatTheme.memberSidebarBg,
      child: isDm
          ? _buildDmPartnerDossier(context, backend.currentDmPartner!)
          : _buildServerMemberGroups(context),
    );
  }

  Widget _buildServerMemberGroups(BuildContext context) {
    final members = backend.currentServerMembers;

    final owners = members.where((m) => m.role == CatRole.owner).toList();
    final supremeLoaves =
        members.where((m) => m.role == CatRole.supremeLoaf).toList();
    final moderators =
        members.where((m) => m.role == CatRole.moderator).toList();
    final seniorPaws =
        members.where((m) => m.role == CatRole.seniorPaws).toList();
    final kittens = members.where((m) => m.role == CatRole.kitten).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Text('🐈', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text(
                backend.isArabic
                    ? 'أعضاء القطط (${members.length})'
                    : 'Cat Members (${members.length})',
                style: const TextStyle(
                  color: CatTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              if (owners.isNotEmpty) ...[
                _RoleSectionHeader(
                  title: backend.isArabic
                      ? '👑 مالك الخادم (OWNER) — ${owners.length}'
                      : '👑 SERVER OWNER — ${owners.length}',
                  color: CatTheme.meowCoinGold,
                ),
                ...owners.map((u) => _MemberTile(
                      user: u,
                      backend: backend,
                    )),
                const SizedBox(height: 12),
              ],
              if (supremeLoaves.isNotEmpty) ...[
                _RoleSectionHeader(
                  title: '👑 SUPREME LOAF — ${supremeLoaves.length}',
                  color: CatTheme.meowCoinGold,
                ),
                ...supremeLoaves.map((u) => _MemberTile(
                      user: u,
                      backend: backend,
                    )),
                const SizedBox(height: 12),
              ],
              if (moderators.isNotEmpty) ...[
                _RoleSectionHeader(
                  title: '🛡️ MOD-ERATERS — ${moderators.length}',
                  color: CatTheme.pawPink,
                ),
                ...moderators.map((u) => _MemberTile(
                      user: u,
                      backend: backend,
                    )),
                const SizedBox(height: 12),
              ],
              if (seniorPaws.isNotEmpty) ...[
                _RoleSectionHeader(
                  title: '🐾 SENIOR PAWS — ${seniorPaws.length}',
                  color: CatTheme.catnipMint,
                ),
                ...seniorPaws.map((u) => _MemberTile(
                      user: u,
                      backend: backend,
                    )),
                const SizedBox(height: 12),
              ],
              if (kittens.isNotEmpty) ...[
                _RoleSectionHeader(
                  title: '🧶 KITTENS — ${kittens.length}',
                  color: CatTheme.yarnBlue,
                ),
                ...kittens.map((u) => _MemberTile(
                      user: u,
                      backend: backend,
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDmPartnerDossier(BuildContext context, CatUser partner) {
    final accentColor = CatTheme.fromHex(partner.avatarColorHex);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Top Banner
        Container(
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.6),
                CatTheme.purrple.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -28),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CatTheme.memberSidebarBg,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: accentColor.withValues(alpha: 0.3),
                        child: Text(
                          partner.avatarEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: partner.presence.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${partner.presence.iconEmoji} ${partner.presence.shortLabel}',
                        style: TextStyle(
                          color: partner.presence.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                partner.displayName,
                style: const TextStyle(
                  color: CatTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '@${partner.username}',
                style: const TextStyle(
                  color: CatTheme.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 12),
              if (partner.equippedBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: CatTheme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    partner.equippedBadge!,
                    style: const TextStyle(
                      color: CatTheme.meowCoinGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CatTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENTLY DOING',
                      style: TextStyle(
                        color: CatTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      partner.customStatus,
                      style: const TextStyle(
                        color: CatTheme.textPrimary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ABOUT THIS CAT',
                      style: TextStyle(
                        color: CatTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      partner.bio,
                      style: const TextStyle(
                        color: CatTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CASTLE ROLE',
                      style: TextStyle(
                        color: CatTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(partner.role.badgeEmoji),
                        const SizedBox(width: 6),
                        Text(
                          partner.role.title,
                          style: TextStyle(
                            color: partner.role.color,
                            fontWeight: FontWeight.bold,
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
      ],
    );
  }
}

class _RoleSectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _RoleSectionHeader({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CatUser user;
  final CatBackendService backend;

  const _MemberTile({
    required this.user,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = user.presence == CatPresence.stray;

    return Opacity(
      opacity: isOffline ? 0.55 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => CatModals.showUserProfileModal(context, backend, user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: CatTheme.fromHex(user.avatarColorHex)
                        .withValues(alpha: 0.25),
                    child: Text(
                      user.avatarEmoji,
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
                        color: user.presence.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CatTheme.memberSidebarBg,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: user.role.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (user.id == backend.currentUser.id) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '(You)',
                            style: TextStyle(
                              color: CatTheme.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user.customStatus,
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
    );
  }
}
