enum CatChannelType {
  announcements,
  text,
  catnipLounge,
}

class CatChannel {
  final String id;
  final String name;
  final String topic;
  final CatChannelType type;
  final int unreadCount;

  const CatChannel({
    required this.id,
    required this.name,
    required this.topic,
    this.type = CatChannelType.text,
    this.unreadCount = 0,
  });

  String get prefixEmoji {
    switch (type) {
      case CatChannelType.announcements:
        return '📣';
      case CatChannelType.text:
        return '🐾';
      case CatChannelType.catnipLounge:
        return '🌿';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'topic': topic,
      'type': type.name,
      'unreadCount': unreadCount,
    };
  }

  factory CatChannel.fromMap(Map<String, dynamic> map) {
    return CatChannel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'general-meows',
      topic: map['topic'] ?? '',
      type: CatChannelType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CatChannelType.text,
      ),
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final List<CatChannel> channels;

  const ChannelCategory({
    required this.id,
    required this.name,
    required this.channels,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'channels': channels.map((c) => c.toMap()).toList(),
    };
  }

  factory ChannelCategory.fromMap(Map<String, dynamic> map) {
    return ChannelCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? 'MEOW CHATS',
      channels: (map['channels'] as List<dynamic>? ?? [])
          .map((c) => CatChannel.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

class CatServer {
  final String id;
  final String name;
  final String iconEmoji;
  final String bannerColorHex;
  final String description;
  final String ownerId;
  final List<String> memberIds;
  final List<ChannelCategory> categories;

  const CatServer({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.bannerColorHex,
    required this.description,
    required this.ownerId,
    required this.memberIds,
    required this.categories,
  });

  List<CatChannel> get allChannels =>
      categories.expand((cat) => cat.channels).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconEmoji': iconEmoji,
      'bannerColorHex': bannerColorHex,
      'description': description,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  factory CatServer.fromMap(Map<String, dynamic> map) {
    return CatServer(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Cat House',
      iconEmoji: map['iconEmoji'] ?? '🏰',
      bannerColorHex: map['bannerColorHex'] ?? '#FF7EB6',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? const []),
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((c) => ChannelCategory.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}
