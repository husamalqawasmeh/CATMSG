enum QuestActionType {
  sendMessages,
  addReactions,
  sendSticker,
  replyMessage,
  sendDm,
  visitChannels,
}

class CatQuest {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final String category; // 'Daily Paws', 'Social Whiskers', 'Legend Milestones'
  final QuestActionType actionType;
  final int targetCount;
  final int currentProgress;
  final int rewardCoins;
  final bool isClaimed;

  const CatQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.category,
    required this.actionType,
    required this.targetCount,
    this.currentProgress = 0,
    required this.rewardCoins,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetCount;
  bool get isClaimable => isCompleted && !isClaimed;
  double get progressRatio =>
      targetCount == 0 ? 1.0 : (currentProgress / targetCount).clamp(0.0, 1.0);

  CatQuest copyWith({
    int? currentProgress,
    bool? isClaimed,
  }) {
    return CatQuest(
      id: id,
      title: title,
      description: description,
      iconEmoji: iconEmoji,
      category: category,
      actionType: actionType,
      targetCount: targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      rewardCoins: rewardCoins,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconEmoji': iconEmoji,
      'category': category,
      'actionType': actionType.name,
      'targetCount': targetCount,
      'currentProgress': currentProgress,
      'rewardCoins': rewardCoins,
      'isClaimed': isClaimed,
    };
  }

  factory CatQuest.fromMap(Map<String, dynamic> map) {
    return CatQuest(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Cat Quest',
      description: map['description'] ?? '',
      iconEmoji: map['iconEmoji'] ?? '🎯',
      category: map['category'] ?? 'Daily Paws',
      actionType: QuestActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => QuestActionType.sendMessages,
      ),
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      currentProgress: (map['currentProgress'] as num?)?.toInt() ?? 0,
      rewardCoins: (map['rewardCoins'] as num?)?.toInt() ?? 50,
      isClaimed: map['isClaimed'] ?? false,
    );
  }
}

class BadgeShopItem {
  final String badgeTitle;
  final String description;
  final int priceCoins;

  const BadgeShopItem({
    required this.badgeTitle,
    required this.description,
    required this.priceCoins,
  });

  static const List<BadgeShopItem> catalog = [
    BadgeShopItem(
      badgeTitle: '🪙 MeowCoin Collector',
      description: 'Proud collector of shiny MeowCoins across the Cat Houses.',
      priceCoins: 20,
    ),
    BadgeShopItem(
      badgeTitle: '🐟 Tuna Tycoon',
      description: 'Flaunt your elite taste for sashimi in every chat message.',
      priceCoins: 60,
    ),
    BadgeShopItem(
      badgeTitle: '💰 MeowCoin Hoarder',
      description: 'Sitting atop a massive dragon-sized pile of golden MeowCoins.',
      priceCoins: 80,
    ),
    BadgeShopItem(
      badgeTitle: '🧶 Yarn Master',
      description: 'Awarded to cats who never get tangled in threads.',
      priceCoins: 80,
    ),
    BadgeShopItem(
      badgeTitle: '🌙 Midnight Zoomer',
      description: 'Certified speedster at 3:00 AM across the hallway.',
      priceCoins: 110,
    ),
    BadgeShopItem(
      badgeTitle: '👑 Royal Whisker',
      description: 'The most prestigious golden crown badge in CatMsg.',
      priceCoins: 200,
    ),
  ];
}

class WhiteboardMarkerItem {
  final String id;
  final String name;
  final String colorHex;
  final int priceCoins;

  const WhiteboardMarkerItem({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.priceCoins,
  });

  static const List<WhiteboardMarkerItem> catalog = [
    WhiteboardMarkerItem(
      id: 'marker_white',
      name: '🤍 Default White Marker',
      colorHex: '#FFFFFF',
      priceCoins: 0,
    ),
    WhiteboardMarkerItem(
      id: 'marker_emerald',
      name: '💚 Emerald Marker',
      colorHex: '#10B981',
      priceCoins: 25,
    ),
  ];
}
