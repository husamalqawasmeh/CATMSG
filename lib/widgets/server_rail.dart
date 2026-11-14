import 'package:flutter/material.dart';
import '../models/cat_server.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import 'modals.dart';

class ServerRail extends StatelessWidget {
  final CatBackendService backend;
  final VoidCallback? onNavigationSelected;

  const ServerRail({
    super.key,
    required this.backend,
    this.onNavigationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navMode = backend.navMode;
    final claimableCount = backend.claimableQuestsCount;

    return Container(
      width: 74,
      color: CatTheme.serverRailBg,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Top Direct Messages & Friends Button
          _RailIconButton(
            isSelected: navMode == NavMode.dms,
            tooltip: 'Direct Meows & Cat Friends',
            activeColor: CatTheme.pawPink,
            onTap: () {
              backend.openDmsHome();
              onNavigationSelected?.call();
            },
            child: const Text('🐾', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),

          // Quests & MeowCoins Hub Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RailIconButton(
                isSelected: navMode == NavMode.quests,
                tooltip: 'Cat Quests & MeowCoin Emporium',
                activeColor: CatTheme.meowCoinGold,
                onTap: () {
                  backend.openQuestsAndShop();
                  onNavigationSelected?.call();
                },
                child: const Text('🪙', style: TextStyle(fontSize: 23)),
              ),
              if (claimableCount > 0)
                Positioned(
                  right: 8,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CatTheme.tunaCoral,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CatTheme.serverRailBg,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$claimableCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Divider(
              height: 2,
              thickness: 2,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Scrollable Cat Houses (Servers)
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: backend.servers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final CatServer server = backend.servers[index];
                final bool isSelected = navMode == NavMode.server &&
                    backend.selectedServerId == server.id;

                return _RailIconButton(
                  isSelected: isSelected,
                  tooltip: server.name,
                  activeColor: CatTheme.fromHex(server.bannerColorHex),
                  onTap: () {
                    backend.selectServer(server.id);
                    onNavigationSelected?.call();
                  },
                  child: Text(
                    server.iconEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Create New Cat House (+) Button
          _RailIconButton(
            isSelected: false,
            tooltip: 'Create a Cat House (Server)',
            activeColor: CatTheme.catnipMint,
            onTap: () => CatModals.showCreateServerDialog(context, backend),
            child: const Icon(
              Icons.add_rounded,
              color: CatTheme.catnipMint,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),

          // Firebase / Auth Connection Status Button
          _RailIconButton(
            isSelected: false,
            tooltip: backend.useFirebase
                ? 'Firebase Connected (Click for Auth & Firestore options)'
                : 'Demo Mode Active (Click for Firebase & Account options)',
            activeColor: CatTheme.purrple,
            onTap: () => CatModals.showFirebaseAndAuthDialog(context, backend),
            child: Icon(
              backend.useFirebase
                  ? Icons.cloud_done_rounded
                  : Icons.pets_rounded,
              color: backend.useFirebase
                  ? CatTheme.meowCoinGold
                  : CatTheme.purrple,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailIconButton extends StatefulWidget {
  final bool isSelected;
  final String tooltip;
  final Color activeColor;
  final VoidCallback onTap;
  final Widget child;

  const _RailIconButton({
    required this.isSelected,
    required this.tooltip,
    required this.activeColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_RailIconButton> createState() => _RailIconButtonState();
}

class _RailIconButtonState extends State<_RailIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final activeOrHover = widget.isSelected || _hovering;

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            height: 48,
            width: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Discord left indicator pill
                Positioned(
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 4,
                    height: widget.isSelected
                        ? 38
                        : (_hovering ? 20 : 0),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? widget.activeColor
                          : Colors.white,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.activeColor.withValues(alpha: 0.25)
                        : (_hovering
                            ? CatTheme.cardHoverBg
                            : CatTheme.cardBg),
                    borderRadius: BorderRadius.circular(
                      activeOrHover ? 16 : 24,
                    ),
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.activeColor
                          : Colors.white.withValues(alpha: 0.06),
                      width: widget.isSelected ? 1.8 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
