import 'package:flutter/material.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';
import '../widgets/channel_sidebar.dart';
import '../widgets/chat_view.dart';
import '../widgets/friends_and_quests_views.dart';
import '../widgets/member_sidebar.dart';
import '../widgets/server_rail.dart';

class HomeScreen extends StatefulWidget {
  final CatBackendService backend;

  const HomeScreen({
    super.key,
    required this.backend,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showRightSidebarDesktop = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.backend,
      builder: (context, _) {
        final backend = widget.backend;

        return Directionality(
          textDirection:
              backend.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 940;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: CatTheme.chatFeedBg,
              drawer: isCompact
                  ? Drawer(
                      width: 322,
                      backgroundColor: CatTheme.serverRailBg,
                      child: SafeArea(
                        child: Row(
                          children: [
                            ServerRail(
                              backend: backend,
                            ),
                            Expanded(
                              child: ChannelSidebar(
                                backend: backend,
                                onItemSelected: () {
                                  Navigator.of(context).maybePop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
              endDrawer: isCompact
                  ? Drawer(
                      width: 268,
                      backgroundColor: CatTheme.memberSidebarBg,
                      child: SafeArea(
                        child: MemberSidebar(backend: backend),
                      ),
                    )
                  : null,
              body: SafeArea(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        if (!isCompact) ...[
                          ServerRail(backend: backend),
                          ChannelSidebar(backend: backend),
                        ],
                        Expanded(
                          child: _buildMainContent(backend, isCompact),
                        ),
                        if (!isCompact &&
                            _showRightSidebarDesktop &&
                            backend.navMode != NavMode.quests)
                          MemberSidebar(backend: backend),
                      ],
                    ),

                    // Floating Quest / MeowCoin Toast Notification
                    if (backend.latestToast != null)
                      Positioned(
                        top: 64,
                        right: 24,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: CatTheme.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: CatTheme.meowCoinGold,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    backend.latestToast!,
                                    style: const TextStyle(
                                      color: CatTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  onPressed: backend.clearToast,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottomNavigationBar: isCompact
                  ? NavigationBar(
                      height: 62,
                      backgroundColor: CatTheme.serverRailBg,
                      indicatorColor: CatTheme.pawPink.withValues(alpha: 0.22),
                      selectedIndex: backend.navMode == NavMode.server
                          ? 0
                          : (backend.navMode == NavMode.dms ? 1 : 2),
                      onDestinationSelected: (idx) {
                        if (idx == 0) {
                          backend.selectServer(backend.selectedServerId);
                        } else if (idx == 1) {
                          backend.openDmsHome();
                        } else {
                          backend.openQuestsAndShop();
                        }
                      },
                      destinations: [
                        const NavigationDestination(
                          icon: Text('🏰', style: TextStyle(fontSize: 19)),
                          label: 'Cat Houses',
                        ),
                        const NavigationDestination(
                          icon: Text('🐾', style: TextStyle(fontSize: 19)),
                          label: 'DMs & Friends',
                        ),
                        NavigationDestination(
                          icon: Badge(
                            isLabelVisible: backend.claimableQuestsCount > 0,
                            label: Text('${backend.claimableQuestsCount}'),
                            child: const Text(
                              '🪙',
                              style: TextStyle(fontSize: 19),
                            ),
                          ),
                          label: 'Quests & Coins',
                        ),
                      ],
                    )
                  : null,
            );
          },
          ),
        );
      },
    );
  }

  Widget _buildMainContent(CatBackendService backend, bool isCompact) {
    void openLeftDrawer() {
      _scaffoldKey.currentState?.openDrawer();
    }

    void toggleRightPanel() {
      if (isCompact) {
        _scaffoldKey.currentState?.openEndDrawer();
      } else {
        setState(() {
          _showRightSidebarDesktop = !_showRightSidebarDesktop;
        });
      }
    }

    if (backend.navMode == NavMode.quests) {
      return QuestsAndShopView(
        backend: backend,
        isCompact: isCompact,
        onOpenLeftDrawer: openLeftDrawer,
      );
    }

    if (backend.navMode == NavMode.dms &&
        backend.dmSubView == DmSubView.friends) {
      return FriendsDashboardView(
        backend: backend,
        isCompact: isCompact,
        onOpenLeftDrawer: openLeftDrawer,
      );
    }

    return ChatView(
      backend: backend,
      isCompact: isCompact,
      onOpenLeftDrawer: openLeftDrawer,
      onToggleRightPanel: toggleRightPanel,
    );
  }
}
