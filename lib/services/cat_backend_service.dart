import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/cat_message.dart';
import '../models/cat_quest.dart';
import '../models/cat_server.dart';
import '../models/cat_user.dart';

enum NavMode {
  server,
  dms,
  quests,
}

enum DmSubView {
  friends,
  conversation,
}

class CatBackendService extends ChangeNotifier {
  bool _useFirebase = false;
  bool get useFirebase => _useFirebase;

  String? _firebaseError;
  String? get firebaseError => _firebaseError;

  // Navigation state
  NavMode _navMode = NavMode.server;
  NavMode get navMode => _navMode;

  DmSubView _dmSubView = DmSubView.friends;
  DmSubView get dmSubView => _dmSubView;

  String _selectedServerId = 'server_castle';
  String get selectedServerId => _selectedServerId;

  String _selectedChannelId = 'chan_general_meows';
  String get selectedChannelId => _selectedChannelId;

  String? _selectedDmUserId = 'user_mochi';
  String? get selectedDmUserId => _selectedDmUserId;

  CatMessage? _replyingToMessage;
  CatMessage? get replyingToMessage => _replyingToMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // UI Language ('en' or 'ar')
  String _localeCode = 'en';
  String get localeCode => _localeCode;
  bool get isArabic => _localeCode == 'ar';

  // User Data Saving state
  bool _autoSaveEnabled = true;
  bool get autoSaveEnabled => _autoSaveEnabled;
  String _lastSavedTime = 'Just now';
  String get lastSavedTime => _lastSavedTime;

  void toggleAutoSave(bool value) {
    _autoSaveEnabled = value;
    _showToast(
      isArabic
          ? (_autoSaveEnabled
              ? '💾 تم تفعيل الحفظ التلقائي للبيانات!'
              : '⏸️ تم إيقاف الحفظ التلقائي.')
          : (_autoSaveEnabled ? '💾 Auto-Save enabled!' : '⏸️ Auto-Save paused.'),
    );
    notifyListeners();
  }

  Future<void> saveUserDataNow() async {
    final now = DateTime.now();
    _lastSavedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _syncCurrentUserToFirestore();
    _showToast(
      isArabic
          ? '💾 تم حفظ بيانات المستخدم بنجاح ($_lastSavedTime)!'
          : '💾 User Data Saved ($_lastSavedTime)!',
    );
    notifyListeners();
  }

  String exportUserDataJson() {
    final payload = {
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'localeCode': _localeCode,
      'autoSaveEnabled': _autoSaveEnabled,
      'currentUser': _currentUser.toMap(),
      'quests': _quests.map((q) => q.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  bool importUserDataJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      if (decoded['localeCode'] is String) {
        _localeCode = decoded['localeCode'];
      }
      if (decoded['autoSaveEnabled'] is bool) {
        _autoSaveEnabled = decoded['autoSaveEnabled'];
      }
      if (decoded['currentUser'] is Map) {
        _currentUser = CatUser.fromMap(
          Map<String, dynamic>.from(decoded['currentUser']),
        ).copyWith(role: CatRole.owner);
        _users[_currentUser.id] = _currentUser;
      }
      if (decoded['quests'] is List) {
        _quests = (decoded['quests'] as List)
            .map((q) => CatQuest.fromMap(Map<String, dynamic>.from(q)))
            .toList();
      }
      _showToast(
        isArabic
            ? '📤 تمت استعادة بيانات المستخدم بنجاح!'
            : '📤 Restored User Data from Backup!',
      );
      notifyListeners();
      return true;
    } catch (_) {
      _showToast('😾 Invalid JSON backup format.');
      return false;
    }
  }

  void setLocaleCode(String code) {
    _localeCode = code == 'ar' ? 'ar' : 'en';
    _showToast(
      _localeCode == 'ar'
          ? '🇸🇦 تم تفعيل الواجهة العربية بنجاح!'
          : '🇬🇧 Switched UI language to English!',
    );
    notifyListeners();
  }

  // Toast / Quest completion banner notification
  String? _latestToast;
  String? get latestToast => _latestToast;

  final Set<String> _visitedChannelIds = {'chan_general_meows'};

  // Data state
  late CatUser _currentUser;
  CatUser get currentUser => _currentUser;

  final Map<String, CatUser> _users = {};
  List<CatUser> get allUsers => _users.values.toList();

  List<CatServer> _servers = [];
  List<CatServer> get servers => _servers;

  final Map<String, List<CatMessage>> _messagesByChannel = {};
  List<CatQuest> _quests = [];
  List<CatQuest> get quests => _quests;

  StreamSubscription<QuerySnapshot>? _messagesSub;
  StreamSubscription<DocumentSnapshot>? _userSub;

  CatBackendService({bool firebaseReady = false}) {
    _useFirebase = firebaseReady && DefaultFirebaseOptions.isFirebaseConfigured;
    _seedInitialData();
    if (_useFirebase) {
      _initFirebaseListeners();
    }
  }

  CatServer get currentServer {
    return _servers.firstWhere(
      (s) => s.id == _selectedServerId,
      orElse: () => _servers.first,
    );
  }

  CatChannel get currentChannel {
    final all = currentServer.allChannels;
    return all.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => all.first,
    );
  }

  CatUser? get currentDmPartner {
    if (_selectedDmUserId == null) return null;
    return _users[_selectedDmUserId];
  }

  String get activeConversationChannelId {
    if (_navMode == NavMode.dms && _selectedDmUserId != null) {
      return dmChannelIdFor(_currentUser.id, _selectedDmUserId!);
    }
    return _selectedChannelId;
  }

  static String dmChannelIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return 'dm_${sorted[0]}_${sorted[1]}';
  }

  List<CatMessage> get activeMessages {
    final list = _messagesByChannel[activeConversationChannelId] ?? [];
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where(
          (m) =>
              m.content.toLowerCase().contains(q) ||
              m.senderName.toLowerCase().contains(q),
        )
        .toList();
  }

  List<CatUser> get currentServerMembers {
    final memberIds = currentServer.memberIds;
    final members = <CatUser>[];
    for (final id in memberIds) {
      if (id == _currentUser.id) {
        members.add(_currentUser);
      } else if (_users.containsKey(id)) {
        members.add(_users[id]!);
      }
    }
    return members;
  }

  List<CatUser> get friendsList {
    return _currentUser.friendIds
        .map((id) => _users[id])
        .whereType<CatUser>()
        .toList();
  }

  int get claimableQuestsCount =>
      _quests.where((q) => q.isClaimable).length;

  void clearToast() {
    _latestToast = null;
    notifyListeners();
  }

  void _showToast(String message) {
    _latestToast = message;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setReplyingTo(CatMessage? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  // Navigation Actions
  void selectServer(String serverId) {
    _navMode = NavMode.server;
    _selectedServerId = serverId;
    final srv = currentServer;
    if (srv.allChannels.isNotEmpty) {
      _selectedChannelId = srv.allChannels.first.id;
      _trackChannelVisit(_selectedChannelId);
    }
    _replyingToMessage = null;
    if (_useFirebase) {
      _subscribeToFirestoreChannel(activeConversationChannelId);
    }
    notifyListeners();
  }

  void selectChannel(String channelId) {
    _navMode = NavMode.server;
    _selectedChannelId = channelId;
    _replyingToMessage = null;
    _trackChannelVisit(channelId);
    if (_useFirebase) {
      _subscribeToFirestoreChannel(activeConversationChannelId);
    }
    notifyListeners();
  }

  void openDmsHome() {
    _navMode = NavMode.dms;
    _dmSubView = DmSubView.friends;
    _replyingToMessage = null;
    notifyListeners();
  }

  void openDmConversation(String otherUserId) {
    _navMode = NavMode.dms;
    _dmSubView = DmSubView.conversation;
    _selectedDmUserId = otherUserId;
    _replyingToMessage = null;
    if (_useFirebase) {
      _subscribeToFirestoreChannel(activeConversationChannelId);
    }
    notifyListeners();
  }

  void openQuestsAndShop() {
    _navMode = NavMode.quests;
    _replyingToMessage = null;
    notifyListeners();
  }

  void _trackChannelVisit(String channelId) {
    if (!_visitedChannelIds.contains(channelId)) {
      _visitedChannelIds.add(channelId);
      _incrementQuestProgress(QuestActionType.visitChannels, 1);
    }
  }

  // Messaging Actions
  Future<void> sendMessage({
    required String content,
    String? stickerId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && stickerId == null) return;

    final channelId = activeConversationChannelId;
    final isDm = _navMode == NavMode.dms && _dmSubView == DmSubView.conversation;
    final replyTarget = _replyingToMessage;

    final newMsg = CatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      channelId: channelId,
      senderId: _currentUser.id,
      senderName: _currentUser.displayName,
      senderAvatar: _currentUser.avatarEmoji,
      senderAvatarHex: _currentUser.avatarColorHex,
      senderRoleColorHex: _currentUser.role.colorHex,
      senderBadge: _currentUser.equippedBadge,
      content: trimmed,
      stickerId: stickerId,
      replyToMessageId: replyTarget?.id,
      replyToSenderName: replyTarget?.senderName,
      replyToPreview: replyTarget != null
          ? (replyTarget.content.isNotEmpty
              ? replyTarget.content
              : '🏷️ [Cat Sticker]')
          : null,
      reactions: const {},
      timestamp: DateTime.now(),
    );

    _messagesByChannel.putIfAbsent(channelId, () => []);
    _messagesByChannel[channelId]!.add(newMsg);
    _replyingToMessage = null;

    // Quest Progress Triggers
    _incrementQuestProgress(QuestActionType.sendMessages, 1);
    if (stickerId != null) {
      _incrementQuestProgress(QuestActionType.sendSticker, 1);
    }
    if (replyTarget != null) {
      _incrementQuestProgress(QuestActionType.replyMessage, 1);
    }
    if (isDm) {
      _incrementQuestProgress(QuestActionType.sendDm, 1);
    }

    notifyListeners();

    if (_useFirebase) {
      try {
        await FirebaseFirestore.instance
            .collection('channels')
            .doc(channelId)
            .collection('messages')
            .doc(newMsg.id)
            .set(newMsg.toMap());
      } catch (e) {
        _firebaseError = e.toString();
      }
    } else {
      _schedulePlayfulBotReply(channelId, newMsg, isDm: isDm);
    }
  }

  void _schedulePlayfulBotReply(
    String channelId,
    CatMessage userMsg, {
    required bool isDm,
  }) {
    Future.delayed(const Duration(milliseconds: 1400), () {
      CatUser? responder;
      if (isDm && _selectedDmUserId != null) {
        responder = _users[_selectedDmUserId!];
      } else {
        final candidates = currentServerMembers
            .where((u) => u.id != _currentUser.id && u.presence != CatPresence.stray)
            .toList();
        if (candidates.isNotEmpty) {
          responder = candidates[Random().nextInt(candidates.length)];
        }
      }
      if (responder == null) return;

      final lower = userMsg.content.toLowerCase();
      String replyText;
      String? replySticker;

      if (userMsg.stickerId != null) {
        replyText =
            'Purrfect sticker choice, @${_currentUser.displayName}! *boops back with paws* 🐾✨';
      } else if (lower.contains('tuna') ||
          lower.contains('fish') ||
          lower.contains('food') ||
          lower.contains('treat')) {
        replyText =
            'DID SOMEBODY SAY TUNA?! 🐟👀 I sprinted from the windowsill in 0.4 seconds!';
      } else if (lower.contains('meow') || lower.contains('purr')) {
        replyText =
            'Mrrr-oww! *vibrates at 45Hz purr frequency* 😺🎶 How are your whiskers today?';
      } else if (lower.contains('box') || lower.contains('sleep') || lower.contains('nap')) {
        replyText =
            'Can confirm: cardboard box > \$200 luxury velvet cat bed every single time 📦💤';
      } else {
        const responses = [
          'Pawsitively agreed! Let\'s knock a water glass off the counter to celebrate 🥛🐾',
          'Mrrrow! That deserves at least 3 headbutts and a slow blink 😻',
          '*ears perk up* Wait, is there a red laser dot behind you?! 🔴👀',
          '10/10 take. Awarding you honorary Supreme Loaf status for the afternoon 🍞👑',
          'Purr-fect! Don\'t forget to check your Daily Paws Quests for extra MeowCoins 🪙✨',
        ];
        replyText = responses[Random().nextInt(responses.length)];
      }

      final botReply = CatMessage(
        id: 'msg_bot_${DateTime.now().millisecondsSinceEpoch}',
        channelId: channelId,
        senderId: responder.id,
        senderName: responder.displayName,
        senderAvatar: responder.avatarEmoji,
        senderAvatarHex: responder.avatarColorHex,
        senderRoleColorHex: responder.role.colorHex,
        senderBadge: responder.equippedBadge,
        content: replyText,
        stickerId: replySticker,
        replyToMessageId: userMsg.id,
        replyToSenderName: userMsg.senderName,
        replyToPreview: userMsg.content.isNotEmpty
            ? userMsg.content
            : '🏷️ [Cat Sticker]',
        reactions: {
          '🐾': [responder.id],
        },
        timestamp: DateTime.now(),
      );

      _messagesByChannel.putIfAbsent(channelId, () => []);
      _messagesByChannel[channelId]!.add(botReply);
      notifyListeners();
    });
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final channelId = activeConversationChannelId;
    final list = _messagesByChannel[channelId];
    if (list == null) return;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final msg = list[idx];
    final updatedReactions = <String, List<String>>{};
    msg.reactions.forEach((k, v) {
      updatedReactions[k] = List<String>.from(v);
    });

    final currentUsers = updatedReactions[emoji] ?? <String>[];
    bool added = false;
    if (currentUsers.contains(_currentUser.id)) {
      currentUsers.remove(_currentUser.id);
      if (currentUsers.isEmpty) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = currentUsers;
      }
    } else {
      currentUsers.add(_currentUser.id);
      updatedReactions[emoji] = currentUsers;
      added = true;
    }

    list[idx] = msg.copyWith(reactions: updatedReactions);
    if (added) {
      _incrementQuestProgress(QuestActionType.addReactions, 1);
    }
    notifyListeners();

    if (_useFirebase) {
      try {
        await FirebaseFirestore.instance
            .collection('channels')
            .doc(channelId)
            .collection('messages')
            .doc(messageId)
            .update({'reactions': updatedReactions});
      } catch (_) {}
    }
  }

  void togglePinMessage(String messageId) {
    final channelId = activeConversationChannelId;
    final list = _messagesByChannel[channelId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final current = list[idx];
    list[idx] = current.copyWith(isPinned: !current.isPinned);
    _showToast(
      list[idx].isPinned
          ? '📌 Pinned message to #${currentChannel.name}!'
          : '📌 Unpinned message.',
    );
    notifyListeners();
  }

  // Quests & MeowCoins Engine
  void _incrementQuestProgress(QuestActionType actionType, int delta) {
    bool anyNewlyCompleted = false;
    String? completedQuestTitle;

    for (var i = 0; i < _quests.length; i++) {
      final q = _quests[i];
      if (q.actionType == actionType && !q.isCompleted) {
        final nextProgress =
            (q.currentProgress + delta).clamp(0, q.targetCount);
        final updated = q.copyWith(currentProgress: nextProgress);
        _quests[i] = updated;
        if (updated.isCompleted && !q.isCompleted) {
          anyNewlyCompleted = true;
          completedQuestTitle = updated.title;
        }
      }
    }

    if (anyNewlyCompleted && completedQuestTitle != null) {
      _showToast(
        '🎉 Quest Complete: "$completedQuestTitle"! Visit Quests to claim your MeowCoins 🪙',
      );
    }
  }

  void claimQuestReward(String questId) {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = _quests[idx];
    if (!quest.isClaimable) return;

    _quests[idx] = quest.copyWith(isClaimed: true);
    _currentUser = _currentUser.copyWith(
      meowCoins: _currentUser.meowCoins + quest.rewardCoins,
    );
    _users[_currentUser.id] = _currentUser;

    _showToast(
      '🪙 +${quest.rewardCoins} MeowCoins claimed from "${quest.title}"!',
    );
    _syncCurrentUserToFirestore();
    notifyListeners();
  }

  bool unlockSticker(CatSticker sticker) {
    if (_currentUser.unlockedStickerIds.contains(sticker.id)) return true;
    if (_currentUser.meowCoins < sticker.priceCoins) {
      _showToast('😾 Not enough MeowCoins! Complete quests to earn more.');
      return false;
    }

    final updatedStickers = List<String>.from(_currentUser.unlockedStickerIds)
      ..add(sticker.id);
    _currentUser = _currentUser.copyWith(
      meowCoins: _currentUser.meowCoins - sticker.priceCoins,
      unlockedStickerIds: updatedStickers,
    );
    _users[_currentUser.id] = _currentUser;
    _showToast('🎉 Unlocked "${sticker.name}" sticker! Find it in the chat sticker picker.');
    _syncCurrentUserToFirestore();
    notifyListeners();
    return true;
  }

  bool purchaseOrEquipBadge(BadgeShopItem item) {
    final alreadyOwned = _currentUser.unlockedBadges.contains(item.badgeTitle);
    if (alreadyOwned) {
      _currentUser = _currentUser.copyWith(equippedBadge: item.badgeTitle);
      _users[_currentUser.id] = _currentUser;
      _showToast('✨ Equipped badge: ${item.badgeTitle}');
      _syncCurrentUserToFirestore();
      notifyListeners();
      return true;
    }

    if (_currentUser.meowCoins < item.priceCoins) {
      _showToast('😾 Need ${item.priceCoins} MeowCoins to unlock ${item.badgeTitle}!');
      return false;
    }

    final updatedBadges = List<String>.from(_currentUser.unlockedBadges)
      ..add(item.badgeTitle);
    _currentUser = _currentUser.copyWith(
      meowCoins: _currentUser.meowCoins - item.priceCoins,
      unlockedBadges: updatedBadges,
      equippedBadge: item.badgeTitle,
    );
    _users[_currentUser.id] = _currentUser;
    _showToast('👑 Purchased & equipped "${item.badgeTitle}"!');
    _syncCurrentUserToFirestore();
    notifyListeners();
    return true;
  }

  // Profile & Presence Actions
  void updatePresence(CatPresence newPresence, {String? customStatus}) {
    _currentUser = _currentUser.copyWith(
      presence: newPresence,
      customStatus: customStatus ?? _currentUser.customStatus,
    );
    _users[_currentUser.id] = _currentUser;
    _syncCurrentUserToFirestore();
    notifyListeners();
  }

  void updateProfile({
    required String displayName,
    required String avatarEmoji,
    required String customStatus,
    required String bio,
    String? equippedBadge,
  }) {
    _currentUser = _currentUser.copyWith(
      displayName: displayName.trim().isEmpty
          ? _currentUser.displayName
          : displayName.trim(),
      avatarEmoji: avatarEmoji,
      customStatus: customStatus.trim(),
      bio: bio.trim(),
      equippedBadge: equippedBadge ?? _currentUser.equippedBadge,
    );
    _users[_currentUser.id] = _currentUser;
    _showToast('🐾 Cat Profile updated!');
    _syncCurrentUserToFirestore();
    notifyListeners();
  }

  void addFriendByUsername(String query) {
    final clean = query.trim().toLowerCase().replaceAll('@', '');
    if (clean.isEmpty) return;

    CatUser? match;
    for (final u in _users.values) {
      if (u.id != _currentUser.id &&
          (u.username.toLowerCase().contains(clean) ||
              u.displayName.toLowerCase().contains(clean))) {
        match = u;
        break;
      }
    }

    if (match != null) {
      if (_currentUser.friendIds.contains(match.id)) {
        _showToast('😺 You are already friends with ${match.displayName}!');
        return;
      }
      final updatedFriends = List<String>.from(_currentUser.friendIds)
        ..add(match.id);
      _currentUser = _currentUser.copyWith(friendIds: updatedFriends);
      _users[_currentUser.id] = _currentUser;
      _showToast('🐾 Added ${match.displayName} to your Cat Friends!');
      notifyListeners();
    } else {
      // Create a new friend cat on the fly!
      final newId = 'user_custom_${DateTime.now().millisecondsSinceEpoch}';
      final newCat = CatUser(
        id: newId,
        username: clean.replaceAll(' ', '_'),
        displayName: query.trim(),
        avatarEmoji: '😺',
        avatarColorHex: '#43D9AD',
        presence: CatPresence.purring,
        customStatus: 'Just joined CatMsg! Meow!',
        role: CatRole.kitten,
        equippedBadge: '🐾 New Kitty',
      );
      _users[newId] = newCat;
      final updatedFriends = List<String>.from(_currentUser.friendIds)
        ..add(newId);
      _currentUser = _currentUser.copyWith(friendIds: updatedFriends);
      _users[_currentUser.id] = _currentUser;
      _showToast('🎉 Invited & added ${newCat.displayName} as a Cat Friend!');
      notifyListeners();
    }
  }

  // Create Server & Channel
  void createCatServer({
    required String name,
    required String iconEmoji,
    required String description,
  }) {
    final id = 'server_${DateTime.now().millisecondsSinceEpoch}';
    final generalId = 'chan_${DateTime.now().millisecondsSinceEpoch}_general';
    final loungeId = 'chan_${DateTime.now().millisecondsSinceEpoch}_lounge';

    final newServer = CatServer(
      id: id,
      name: name.trim(),
      iconEmoji: iconEmoji,
      bannerColorHex: '#9D7BFF',
      description: description.trim().isEmpty
          ? 'A brand new cozy Cat House for purring and hanging out!'
          : description.trim(),
      ownerId: _currentUser.id,
      memberIds: _users.keys.toList(),
      categories: [
        ChannelCategory(
          id: 'cat_${id}_main',
          name: 'MEOW LOUNGE',
          channels: [
            CatChannel(
              id: generalId,
              name: 'general-meows',
              topic: 'Welcome to ${name.trim()}! Say meow!',
              type: CatChannelType.text,
            ),
            CatChannel(
              id: loungeId,
              name: 'catnip-chill',
              topic: 'Cozy naps and purring vibes only.',
              type: CatChannelType.catnipLounge,
            ),
          ],
        ),
      ],
    );

    _servers.add(newServer);
    _messagesByChannel[generalId] = [
      CatMessage(
        id: 'msg_welcome_$id',
        channelId: generalId,
        senderId: _currentUser.id,
        senderName: _currentUser.displayName,
        senderAvatar: _currentUser.avatarEmoji,
        senderAvatarHex: _currentUser.avatarColorHex,
        senderRoleColorHex: _currentUser.role.colorHex,
        senderBadge: _currentUser.equippedBadge,
        content:
            'Welcome everykitty to **${newServer.name}** ${newServer.iconEmoji}! Grab a cardboard box and make yourselves at home! 🐾✨',
        timestamp: DateTime.now(),
      ),
    ];

    selectServer(id);
    _showToast('🏰 Created new Cat House: "${newServer.name}"!');
  }

  void createChannelInCurrentServer({
    required String categoryId,
    required String channelName,
    required String topic,
    required CatChannelType type,
  }) {
    final srvIdx = _servers.indexWhere((s) => s.id == _selectedServerId);
    if (srvIdx == -1) return;

    final srv = _servers[srvIdx];
    final cleanName =
        channelName.trim().toLowerCase().replaceAll(' ', '-').replaceAll('#', '');
    if (cleanName.isEmpty) return;

    final newChannel = CatChannel(
      id: 'chan_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      topic: topic.trim().isEmpty
          ? 'Cat discussions inside #$cleanName'
          : topic.trim(),
      type: type,
    );

    final updatedCategories = srv.categories.map((cat) {
      if (cat.id == categoryId) {
        return ChannelCategory(
          id: cat.id,
          name: cat.name,
          channels: [...cat.channels, newChannel],
        );
      }
      return cat;
    }).toList();

    _servers[srvIdx] = CatServer(
      id: srv.id,
      name: srv.name,
      iconEmoji: srv.iconEmoji,
      bannerColorHex: srv.bannerColorHex,
      description: srv.description,
      ownerId: srv.ownerId,
      memberIds: srv.memberIds,
      categories: updatedCategories,
    );

    _messagesByChannel[newChannel.id] = [
      CatMessage(
        id: 'msg_init_${newChannel.id}',
        channelId: newChannel.id,
        senderId: _currentUser.id,
        senderName: _currentUser.displayName,
        senderAvatar: _currentUser.avatarEmoji,
        senderAvatarHex: _currentUser.avatarColorHex,
        senderRoleColorHex: _currentUser.role.colorHex,
        senderBadge: _currentUser.equippedBadge,
        content: '✨ Created channel **#$cleanName**! ${newChannel.topic}',
        timestamp: DateTime.now(),
      ),
    ];

    selectChannel(newChannel.id);
    _showToast('🐾 Created channel #$cleanName!');
  }

  // Firebase Auth & Firestore Synchronization
  Future<void> signInOrSwitchCatAccount({
    required String emailOrUsername,
    required String password,
    required String displayName,
    required String avatarEmoji,
    bool isRegister = false,
  }) async {
    if (_useFirebase) {
      try {
        UserCredential cred;
        if (isRegister) {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailOrUsername.trim(),
            password: password,
          );
        } else {
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailOrUsername.trim(),
            password: password,
          );
        }
        final uid = cred.user?.uid ?? 'user_captain';
        _currentUser = CatUser(
          id: uid,
          username: emailOrUsername.split('@').first,
          displayName: displayName.isNotEmpty
              ? displayName
              : emailOrUsername.split('@').first,
          avatarEmoji: avatarEmoji,
          avatarColorHex: '#FF7EB6',
          role: CatRole.supremeLoaf,
          meowCoins: 150,
          friendIds: _currentUser.friendIds,
        );
        _users[uid] = _currentUser;
        await _syncCurrentUserToFirestore();
        _showToast('🔥 Signed in with Firebase Auth as ${_currentUser.displayName}!');
        notifyListeners();
        return;
      } catch (e) {
        _firebaseError = e.toString();
        _showToast('Firebase Auth note: $e — Switched profile locally.');
      }
    }

    // Local / Demo profile switch
    _currentUser = _currentUser.copyWith(
      username: emailOrUsername.trim().toLowerCase().replaceAll(' ', '_'),
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : emailOrUsername.trim(),
      avatarEmoji: avatarEmoji,
    );
    _users[_currentUser.id] = _currentUser;
    _showToast('🐾 Switched active Cat Profile to ${_currentUser.displayName}!');
    notifyListeners();
  }

  Future<void> seedFirestoreDatabase() async {
    if (!_useFirebase) {
      _showToast(
        'ℹ️ Currently in Local Demo Mode. Run `flutterfire configure` to connect your live Cloud Firestore project!',
      );
      return;
    }
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      for (final user in _users.values) {
        batch.set(db.collection('users').doc(user.id), user.toMap());
      }
      for (final server in _servers) {
        batch.set(db.collection('servers').doc(server.id), server.toMap());
      }
      await batch.commit();
      _showToast('🔥 Seeded Cat Houses & Cat Users to Cloud Firestore!');
    } catch (e) {
      _firebaseError = e.toString();
      _showToast('⚠️ Firestore seed error: $e');
    }
  }

  void _initFirebaseListeners() {
    _subscribeToFirestoreChannel(activeConversationChannelId);
  }

  void _subscribeToFirestoreChannel(String channelId) {
    _messagesSub?.cancel();
    try {
      _messagesSub = FirebaseFirestore.instance
          .collection('channels')
          .doc(channelId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _messagesByChannel[channelId] = snapshot.docs
              .map((doc) => CatMessage.fromMap(doc.data()))
              .toList();
          notifyListeners();
        }
      }, onError: (e) {
        _firebaseError = e.toString();
      });
    } catch (e) {
      _firebaseError = e.toString();
    }
  }

  Future<void> _syncCurrentUserToFirestore() async {
    if (!_useFirebase) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.id)
          .set(_currentUser.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  void _seedInitialData() {
    _currentUser = const CatUser(
      id: 'user_captain',
      username: 'captain_purr',
      displayName: 'Captain Purr',
      avatarEmoji: '😼',
      avatarColorHex: '#FF7EB6',
      presence: CatPresence.purring,
      customStatus: 'Castle Owner & MeowCoin Hunter 🔴👑',
      role: CatRole.owner,
      bio: 'Founder & Supreme Owner of The Grand Cat Castle. Will trade headbutts for premium salmon.',
      meowCoins: 250,
      unlockedStickerIds: [
        'sticker_loaf',
        'sticker_zoomies',
        'sticker_boop',
        'sticker_tuna',
      ],
      unlockedBadges: ['👑 OWNER', '👑 Supreme Loaf', '🐾 Day One Paws'],
      equippedBadge: '👑 OWNER',
      friendIds: [
        'user_mochi',
        'user_pounce',
        'user_duchess',
        'user_mittens',
        'user_shadow',
      ],
    );

    final sampleUsers = <CatUser>[
      _currentUser,
      const CatUser(
        id: 'user_mochi',
        username: 'mochi_the_loaf',
        displayName: 'Mochi the Calico',
        avatarEmoji: '😻',
        avatarColorHex: '#FFD166',
        presence: CatPresence.purring,
        customStatus: 'Baking biscuits on a fleece blanket 🧶',
        role: CatRole.moderator,
        bio: 'Certified biscuit baker & professional sunbeam finder.',
        equippedBadge: '🧶 Yarn Master',
        isBot: true,
      ),
      const CatUser(
        id: 'user_pounce',
        username: 'sir_pounce_alot',
        displayName: 'Sir Pounce-a-Lot',
        avatarEmoji: '🦁',
        avatarColorHex: '#9D7BFF',
        presence: CatPresence.purring,
        customStatus: 'Guarding the treat jar 🛡️🐟',
        role: CatRole.moderator,
        bio: 'Head of Castle Security. No cucumber shall pass.',
        equippedBadge: '🛡️ Treat Guardian',
        isBot: true,
      ),
      const CatUser(
        id: 'user_duchess',
        username: 'duchess_whiskers',
        displayName: 'Duchess Whiskers',
        avatarEmoji: '🐱',
        avatarColorHex: '#43D9AD',
        presence: CatPresence.catnap,
        customStatus: '16-hour beauty catnap in progress 💤',
        role: CatRole.seniorPaws,
        bio: 'Persian royalty. Only drinks filtered fountain water.',
        equippedBadge: '👑 Royal Whisker',
        isBot: true,
      ),
      const CatUser(
        id: 'user_mittens',
        username: 'prof_mittens',
        displayName: 'Professor Mittens',
        avatarEmoji: '🤓',
        avatarColorHex: '#5CE1E6',
        presence: CatPresence.hissing,
        customStatus: 'Calculating laser dot trajectory 📈🔴',
        role: CatRole.seniorPaws,
        bio: 'PhD in Gravity Testing (knocking pens off desks since 2021).',
        equippedBadge: '🐟 Tuna Tycoon',
        isBot: true,
      ),
      const CatUser(
        id: 'user_shadow',
        username: 'void_zoomer',
        displayName: 'Shadow the Void',
        avatarEmoji: '🐈‍⬛',
        avatarColorHex: '#FF6B6B',
        presence: CatPresence.purring,
        customStatus: 'Staring at an empty corner of the ceiling 👀',
        role: CatRole.kitten,
        bio: 'If you stare into the void, the void meows back for wet food.',
        equippedBadge: '🌙 Midnight Zoomer',
        isBot: true,
      ),
      const CatUser(
        id: 'user_biscuit',
        username: 'orange_braincell',
        displayName: 'Biscuit (1 Braincell)',
        avatarEmoji: '🐯',
        avatarColorHex: '#FF9F68',
        presence: CatPresence.stray,
        customStatus: 'Waiting for my turn with the orange braincell 🍊',
        role: CatRole.kitten,
        bio: 'Orange tabby energy. Head empty, only purrs.',
        isBot: true,
      ),
    ];

    for (final u in sampleUsers) {
      _users[u.id] = u;
    }

    final allMemberIds = _users.keys.toList();

    _servers = [
      CatServer(
        id: 'server_castle',
        name: 'The Grand Cat Castle',
        iconEmoji: '🏰',
        bannerColorHex: '#FF7EB6',
        description:
            'The official CatMsg Kingdom for loaf rating, laser chasing, and daily MeowCoin quests!',
        ownerId: _currentUser.id,
        memberIds: allMemberIds,
        categories: const [
          ChannelCategory(
            id: 'cat_welcome',
            name: '📌 WELCOME MAT',
            channels: [
              CatChannel(
                id: 'chan_royal_decrees',
                name: 'royal-decrees',
                topic:
                    'Official castle announcements, tuna distribution schedules, and quest updates.',
                type: CatChannelType.announcements,
              ),
              CatChannel(
                id: 'chan_loaf_ratings',
                name: 'loaf-ratings',
                topic:
                    'Tuck your paws under and post your 10/10 loaf form!',
                type: CatChannelType.text,
              ),
            ],
          ),
          ChannelCategory(
            id: 'cat_chats',
            name: '💬 MEOW CHATS',
            channels: [
              CatChannel(
                id: 'chan_general_meows',
                name: 'general-meows',
                topic:
                    'Main scratching post for every kitty in the castle! Say meow!',
                type: CatChannelType.text,
              ),
              CatChannel(
                id: 'chan_laser_chase',
                name: 'laser-dot-chase',
                topic:
                    'WHERE DID THE RED DOT GO?! Coordinate tactical pounces here.',
                type: CatChannelType.text,
              ),
              CatChannel(
                id: 'chan_box_reviews',
                name: 'box-reviews',
                topic:
                    'Honest reviews of Amazon boxes, shoeboxes, and laundry baskets.',
                type: CatChannelType.text,
              ),
            ],
          ),
          ChannelCategory(
            id: 'cat_lounge',
            name: '🌿 CATNIP LOUNGES',
            channels: [
              CatChannel(
                id: 'chan_catnip_lounge',
                name: 'sunbeam-nap-zone',
                topic:
                    'Low-volume purring, slow blinks, and cozy afternoon sunbeams.',
                type: CatChannelType.catnipLounge,
              ),
            ],
          ),
        ],
      ),
      CatServer(
        id: 'server_cafe',
        name: 'Catpuccino Cozy Café',
        iconEmoji: '☕',
        bannerColorHex: '#FFD166',
        description:
            'Warm milk foam, window birdwatching, and lo-fi purring beats.',
        ownerId: 'user_mochi',
        memberIds: allMemberIds,
        categories: const [
          ChannelCategory(
            id: 'cat_cafe_main',
            name: '☕ CAFE COUNTER',
            channels: [
              CatChannel(
                id: 'chan_cafe_menu',
                name: 'tuna-menu-and-treats',
                topic: 'Today\'s special: Churuflight & Warm Catpuccino Foam!',
                type: CatChannelType.announcements,
              ),
              CatChannel(
                id: 'chan_birdwatching',
                name: 'window-birdwatching',
                topic: 'Ekekekekek! Chatter at pigeons and squirrels outside.',
                type: CatChannelType.text,
              ),
            ],
          ),
        ],
      ),
      CatServer(
        id: 'server_zoomies',
        name: '3AM Zoomies Club',
        iconEmoji: '⚡',
        bannerColorHex: '#9D7BFF',
        description:
            'High-velocity hallway sprints when the humans are trying to sleep.',
        ownerId: 'user_shadow',
        memberIds: allMemberIds,
        categories: const [
          ChannelCategory(
            id: 'cat_zoom_main',
            name: '⚡ MAXIMUM VELOCITY',
            channels: [
              CatChannel(
                id: 'chan_hallway_sprints',
                name: 'hallway-sprints',
                topic: 'Parkour off the sofa at Mach 3!',
                type: CatChannelType.text,
              ),
              CatChannel(
                id: 'chan_gravity_lab',
                name: 'knocked-off-tables',
                topic: 'Documenting mugs, keys, and plants tested for gravity.',
                type: CatChannelType.text,
              ),
            ],
          ),
        ],
      ),
    ];

    final now = DateTime.now();

    _messagesByChannel['chan_general_meows'] = [
      CatMessage(
        id: 'm1',
        channelId: 'chan_general_meows',
        senderId: 'user_pounce',
        senderName: 'Sir Pounce-a-Lot',
        senderAvatar: '🦁',
        senderAvatarHex: '#9D7BFF',
        senderRoleColorHex: '#FF7EB6',
        senderBadge: '🛡️ Treat Guardian',
        content:
            'Hear ye, hear ye! Welcome to **The Grand Cat Castle** on CatMsg! 🏰🐾 Remember to check the **Quests & MeowCoins** tab to claim rewards for chatting, reacting, and sending stickers!',
        reactions: {
          '🐾': ['user_captain', 'user_mochi', 'user_shadow'],
          '👑': ['user_duchess'],
        },
        timestamp: now.subtract(const Duration(minutes: 42)),
        isPinned: true,
      ),
      CatMessage(
        id: 'm2',
        channelId: 'chan_general_meows',
        senderId: 'user_mochi',
        senderName: 'Mochi the Calico',
        senderAvatar: '😻',
        senderAvatarHex: '#FFD166',
        senderRoleColorHex: '#FF7EB6',
        senderBadge: '🧶 Yarn Master',
        content:
            'Good morning everykitty! I just finished a 4-hour shift of making biscuits on the cashmere throw blanket 🍞✨',
        stickerId: 'sticker_loaf',
        reactions: {
          '😻': ['user_captain', 'user_pounce'],
          '🧶': ['user_mittens'],
        },
        timestamp: now.subtract(const Duration(minutes: 28)),
      ),
      CatMessage(
        id: 'm3',
        channelId: 'chan_general_meows',
        senderId: 'user_mittens',
        senderName: 'Professor Mittens',
        senderAvatar: '🤓',
        senderAvatarHex: '#5CE1E6',
        senderRoleColorHex: '#43D9AD',
        senderBadge: '🐟 Tuna Tycoon',
        content:
            'According to my calculations, the food bowl is 18% empty — which mathematically equals **COMPLETELY EMPTY**. I have begun singing the song of my people.',
        replyToMessageId: 'm2',
        replyToSenderName: 'Mochi the Calico',
        replyToPreview:
            'Good morning everykitty! I just finished a 4-hour shift...',
        reactions: {
          '🐟': ['user_captain', 'user_mochi', 'user_shadow', 'user_pounce'],
        },
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      CatMessage(
        id: 'm4',
        channelId: 'chan_general_meows',
        senderId: 'user_shadow',
        senderName: 'Shadow the Void',
        senderAvatar: '🐈‍⬛',
        senderAvatarHex: '#FF6B6B',
        senderRoleColorHex: '#5CE1E6',
        senderBadge: '🌙 Midnight Zoomer',
        content:
            'Hey @Captain Purr! Try reacting to this message with a paw `🐾`, replying, or sending a Cat Sticker to earn quick **MeowCoins** (`🪙`)!',
        reactions: {
          '⚡': ['user_mochi'],
        },
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
    ];

    _messagesByChannel['chan_royal_decrees'] = [
      CatMessage(
        id: 'm_decree_1',
        channelId: 'chan_royal_decrees',
        senderId: 'user_captain',
        senderName: 'Captain Purr',
        senderAvatar: '😼',
        senderAvatarHex: '#FF7EB6',
        senderRoleColorHex: '#FFD166',
        senderBadge: '👑 Supreme Loaf',
        content:
            '📣 **ROYAL DECREE #1**: Second breakfast is now mandatory at 10:30 AM. All closed bedroom doors are hereby declared illegal under Castle Law.',
        reactions: {
          '👑': ['user_mochi', 'user_pounce', 'user_duchess', 'user_mittens'],
          '🐟': ['user_shadow'],
        },
        timestamp: now.subtract(const Duration(hours: 3)),
        isPinned: true,
      ),
    ];

    _messagesByChannel['chan_laser_chase'] = [
      CatMessage(
        id: 'm_laser_1',
        channelId: 'chan_laser_chase',
        senderId: 'user_shadow',
        senderName: 'Shadow the Void',
        senderAvatar: '🐈‍⬛',
        senderAvatarHex: '#FF6B6B',
        senderRoleColorHex: '#5CE1E6',
        senderBadge: '🌙 Midnight Zoomer',
        content:
            '🔴 IT WAS RIGHT UNDER MY PAW AND THEN IT TELEPORTED ONTO THE WALL!! How does it defy physics?!',
        timestamp: now.subtract(const Duration(minutes: 35)),
      ),
    ];

    _messagesByChannel['chan_box_reviews'] = [
      CatMessage(
        id: 'm_box_1',
        channelId: 'chan_box_reviews',
        senderId: 'user_duchess',
        senderName: 'Duchess Whiskers',
        senderAvatar: '🐱',
        senderAvatarHex: '#43D9AD',
        senderRoleColorHex: '#43D9AD',
        senderBadge: '👑 Royal Whisker',
        content:
            '📦 **2026 Toaster Oven Cardboard Box**: Slightly too small by 3 inches, which makes it 11/10 comfort. Sides bulge nicely when loafing. Highly recommended.',
        reactions: {
          '😻': ['user_captain', 'user_mochi'],
        },
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ];

    // Seed DM conversation with Mochi
    final mochiDmId = dmChannelIdFor(_currentUser.id, 'user_mochi');
    _messagesByChannel[mochiDmId] = [
      CatMessage(
        id: 'dm_mochi_1',
        channelId: mochiDmId,
        senderId: 'user_mochi',
        senderName: 'Mochi the Calico',
        senderAvatar: '😻',
        senderAvatarHex: '#FFD166',
        senderRoleColorHex: '#FF7EB6',
        senderBadge: '🧶 Yarn Master',
        content:
            'Psst! Captain Purr! I hid two extra Churu tubes behind the scratching post 🐟🤫 Send me a DM back to complete your "Friendly Boop" quest!',
        stickerId: 'sticker_boop',
        timestamp: now.subtract(const Duration(minutes: 19)),
      ),
    ];

    // Seed Quests (all quest progress starts at 0 for newer users)
    _quests = const [
      CatQuest(
        id: 'quest_vocal_meower',
        title: 'Vocal Meower',
        description: 'Send 3 messages in any Cat House channel or DM.',
        iconEmoji: '🗣️',
        category: 'Daily Paws',
        actionType: QuestActionType.sendMessages,
        targetCount: 3,
        currentProgress: 0,
        rewardCoins: 50,
      ),
      CatQuest(
        id: 'quest_paws_approval',
        title: 'Paws of Approval',
        description: 'React to 3 messages using Cat Reactions (🐾, 😻, 🐟...).',
        iconEmoji: '🐾',
        category: 'Daily Paws',
        actionType: QuestActionType.addReactions,
        targetCount: 3,
        currentProgress: 0,
        rewardCoins: 45,
      ),
      CatQuest(
        id: 'quest_sticker_artist',
        title: 'Expressive Whiskers',
        description: 'Send 2 custom Cat Stickers in chat.',
        iconEmoji: '🏷️',
        category: 'Social Whiskers',
        actionType: QuestActionType.sendSticker,
        targetCount: 2,
        currentProgress: 0,
        rewardCoins: 65,
      ),
      CatQuest(
        id: 'quest_polite_purr',
        title: 'Polite Purr',
        description: 'Reply directly to another cat\'s message.',
        iconEmoji: '↩️',
        category: 'Social Whiskers',
        actionType: QuestActionType.replyMessage,
        targetCount: 1,
        currentProgress: 0,
        rewardCoins: 50,
      ),
      CatQuest(
        id: 'quest_friendly_boop',
        title: 'Friendly Snoot Boop',
        description: 'Send a Direct Message (DM) to one of your Cat Friends.',
        iconEmoji: '💌',
        category: 'Social Whiskers',
        actionType: QuestActionType.sendDm,
        targetCount: 1,
        currentProgress: 0,
        rewardCoins: 60,
      ),
      CatQuest(
        id: 'quest_curious_explorer',
        title: 'Curious Territory Explorer',
        description: 'Visit 4 different channels across the Cat Houses.',
        iconEmoji: '🧭',
        category: 'Legend Milestones',
        actionType: QuestActionType.visitChannels,
        targetCount: 4,
        currentProgress: 0,
        rewardCoins: 75,
      ),
    ];
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
