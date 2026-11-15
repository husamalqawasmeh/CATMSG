class CatSticker {
  final String id;
  final String name;
  final List<String> emojis;
  final String artEmoji;
  final String caption;
  final String bgHex;
  final int priceCoins;

  const CatSticker({
    required this.id,
    required this.name,
    required this.emojis,
    required this.artEmoji,
    required this.caption,
    required this.bgHex,
    this.priceCoins = 0,
  });

  static const List<CatSticker> catalog = [
    CatSticker(
      id: 'sticker_loaf',
      name: '10/10 Loaf Pack',
      emojis: ['🍞', '🐱', '✨'],
      artEmoji: '🍞🐱✨',
      caption: '10/10 PURRFECT LOAF',
      bgHex: '#FF9F68',
      priceCoins: 0,
    ),
    CatSticker(
      id: 'sticker_zoomies',
      name: '3AM Zoomies Pack',
      emojis: ['⚡', '🐈‍⬛', '💨'],
      artEmoji: '⚡🐈‍⬛💨',
      caption: '3:00 AM ZOOMIES!!',
      bgHex: '#9D7BFF',
      priceCoins: 0,
    ),
    CatSticker(
      id: 'sticker_boop',
      name: 'Snoot Boop Pack',
      emojis: ['👉', '🐽', '🐱'],
      artEmoji: '👉🐽🐱',
      caption: 'BOOP THE SNOOT',
      bgHex: '#FF7EB6',
      priceCoins: 0,
    ),
    CatSticker(
      id: 'sticker_tuna',
      name: 'Gib Tuna Pack',
      emojis: ['🐟', '😿', '🍽️'],
      artEmoji: '🐟😿🍽️',
      caption: 'STARVING FOR 4 MINUTES',
      bgHex: '#5CE1E6',
      priceCoins: 0,
    ),
    CatSticker(
      id: 'sticker_bongo',
      name: 'Bongo Paws Pack',
      emojis: ['🐾', '🥁', '😺'],
      artEmoji: '🐾🥁😺',
      caption: 'BONGO BONGO MEOW',
      bgHex: '#FFD166',
      priceCoins: 50,
    ),
    CatSticker(
      id: 'sticker_laser',
      name: 'Red Dot Target Pack',
      emojis: ['🔴', '👀', '😼'],
      artEmoji: '🔴👀😼',
      caption: 'TARGET ACQUIRED',
      bgHex: '#FF6B6B',
      priceCoins: 75,
    ),
    CatSticker(
      id: 'sticker_box',
      name: 'If I Fits I Sits Pack',
      emojis: ['📦', '😺', '✨'],
      artEmoji: '📦😺✨',
      caption: 'IF I FITS, I SITS',
      bgHex: '#43D9AD',
      priceCoins: 90,
    ),
    CatSticker(
      id: 'sticker_royal',
      name: 'Emperor Meow Pack',
      emojis: ['👑', '🦁', '🪙'],
      artEmoji: '👑🦁🪙',
      caption: 'BOW BEFORE THE WHISKERS',
      bgHex: '#C77DFF',
      priceCoins: 150,
    ),
  ];

  static CatSticker? byId(String? id) {
    if (id == null) return null;
    for (final s in catalog) {
      if (s.id == id) return s;
    }
    return null;
  }
}

class CatMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String senderAvatarHex;
  final String senderRoleColorHex;
  final String? senderBadge;
  final String content;
  final String? stickerId;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToPreview;
  final Map<String, List<String>> reactions;
  final DateTime timestamp;
  final bool isPinned;

  const CatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.senderAvatarHex,
    required this.senderRoleColorHex,
    this.senderBadge,
    required this.content,
    this.stickerId,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToPreview,
    this.reactions = const {},
    required this.timestamp,
    this.isPinned = false,
  });

  CatMessage copyWith({
    String? content,
    Map<String, List<String>>? reactions,
    bool? isPinned,
  }) {
    return CatMessage(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderAvatarHex: senderAvatarHex,
      senderRoleColorHex: senderRoleColorHex,
      senderBadge: senderBadge,
      content: content ?? this.content,
      stickerId: stickerId,
      replyToMessageId: replyToMessageId,
      replyToSenderName: replyToSenderName,
      replyToPreview: replyToPreview,
      reactions: reactions ?? this.reactions,
      timestamp: timestamp,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channelId': channelId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'senderAvatarHex': senderAvatarHex,
      'senderRoleColorHex': senderRoleColorHex,
      'senderBadge': senderBadge,
      'content': content,
      'stickerId': stickerId,
      'replyToMessageId': replyToMessageId,
      'replyToSenderName': replyToSenderName,
      'replyToPreview': replyToPreview,
      'reactions': reactions,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isPinned': isPinned,
    };
  }

  factory CatMessage.fromMap(Map<String, dynamic> map) {
    final rawReactions = map['reactions'] as Map<String, dynamic>? ?? {};
    final parsedReactions = <String, List<String>>{};
    rawReactions.forEach((key, value) {
      parsedReactions[key] = List<String>.from(value as List? ?? const []);
    });

    return CatMessage(
      id: map['id'] ?? '',
      channelId: map['channelId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Cat',
      senderAvatar: map['senderAvatar'] ?? '🐱',
      senderAvatarHex: map['senderAvatarHex'] ?? '#FF7EB6',
      senderRoleColorHex: map['senderRoleColorHex'] ?? '#F4F1FA',
      senderBadge: map['senderBadge'],
      content: map['content'] ?? '',
      stickerId: map['stickerId'],
      replyToMessageId: map['replyToMessageId'],
      replyToSenderName: map['replyToSenderName'],
      replyToPreview: map['replyToPreview'],
      reactions: parsedReactions,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      isPinned: map['isPinned'] ?? false,
    );
  }

  static const List<String> reactionPalette = [
    '🐾',
    '😻',
    '🐟',
    '🧶',
    '🥛',
    '😾',
    '⚡',
    '👑',
  ];
}
