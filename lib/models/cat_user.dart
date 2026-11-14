import 'package:flutter/material.dart';
import '../theme/cat_theme.dart';

enum CatPresence {
  purring, // Online
  catnap, // Idle / Sleeping
  hissing, // Do Not Disturb
  stray, // Offline
}

extension CatPresenceExtension on CatPresence {
  String get label {
    switch (this) {
      case CatPresence.purring:
        return 'Purring (Online)';
      case CatPresence.catnap:
        return 'Catnapping (Idle)';
      case CatPresence.hissing:
        return 'Hissing (Do Not Disturb)';
      case CatPresence.stray:
        return 'Stray (Offline)';
    }
  }

  String get shortLabel {
    switch (this) {
      case CatPresence.purring:
        return 'Purring';
      case CatPresence.catnap:
        return 'Catnapping';
      case CatPresence.hissing:
        return 'Hissing';
      case CatPresence.stray:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case CatPresence.purring:
        return CatTheme.statusPurring;
      case CatPresence.catnap:
        return CatTheme.statusCatnap;
      case CatPresence.hissing:
        return CatTheme.statusHissing;
      case CatPresence.stray:
        return CatTheme.statusStray;
    }
  }

  String get iconEmoji {
    switch (this) {
      case CatPresence.purring:
        return '🟢';
      case CatPresence.catnap:
        return '🌙';
      case CatPresence.hissing:
        return '⛔';
      case CatPresence.stray:
        return '⚪';
    }
  }
}

enum CatRole {
  owner,
  supremeLoaf,
  moderator,
  seniorPaws,
  kitten,
}

extension CatRoleExtension on CatRole {
  String get title {
    switch (this) {
      case CatRole.owner:
        return 'OWNER';
      case CatRole.supremeLoaf:
        return 'Supreme Loaf';
      case CatRole.moderator:
        return 'Mod-erater';
      case CatRole.seniorPaws:
        return 'Senior Paws';
      case CatRole.kitten:
        return 'Kitten';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case CatRole.owner:
        return '👑';
      case CatRole.supremeLoaf:
        return '🍞';
      case CatRole.moderator:
        return '🛡️';
      case CatRole.seniorPaws:
        return '🐾';
      case CatRole.kitten:
        return '🧶';
    }
  }

  Color get color {
    switch (this) {
      case CatRole.owner:
        return CatTheme.meowCoinGold;
      case CatRole.supremeLoaf:
        return CatTheme.meowCoinGold;
      case CatRole.moderator:
        return CatTheme.pawPink;
      case CatRole.seniorPaws:
        return CatTheme.catnipMint;
      case CatRole.kitten:
        return CatTheme.yarnBlue;
    }
  }

  String get colorHex {
    switch (this) {
      case CatRole.owner:
        return '#FFD166';
      case CatRole.supremeLoaf:
        return '#FFD166';
      case CatRole.moderator:
        return '#FF7EB6';
      case CatRole.seniorPaws:
        return '#43D9AD';
      case CatRole.kitten:
        return '#5CE1E6';
    }
  }
}

class CatUser {
  final String id;
  final String username;
  final String displayName;
  final String avatarEmoji;
  final String avatarColorHex;
  final CatPresence presence;
  final String customStatus;
  final CatRole role;
  final String bio;
  final int meowCoins;
  final List<String> unlockedStickerIds;
  final List<String> unlockedBadges;
  final String? equippedBadge;
  final List<String> friendIds;
  final bool isBot;

  const CatUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarEmoji,
    required this.avatarColorHex,
    this.presence = CatPresence.purring,
    this.customStatus = 'Loafing on a warm keyboard ⌨️🐾',
    this.role = CatRole.kitten,
    this.bio = 'Just a cozy cat looking for tuna and warm cardboard boxes.',
    this.meowCoins = 120,
    this.unlockedStickerIds = const [
      'sticker_loaf',
      'sticker_zoomies',
      'sticker_boop',
      'sticker_tuna',
    ],
    this.unlockedBadges = const ['🐾 Day One Paws'],
    this.equippedBadge = '🐾 Day One Paws',
    this.friendIds = const [],
    this.isBot = false,
  });

  CatUser copyWith({
    String? username,
    String? displayName,
    String? avatarEmoji,
    String? avatarColorHex,
    CatPresence? presence,
    String? customStatus,
    CatRole? role,
    String? bio,
    int? meowCoins,
    List<String>? unlockedStickerIds,
    List<String>? unlockedBadges,
    String? equippedBadge,
    List<String>? friendIds,
  }) {
    return CatUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      presence: presence ?? this.presence,
      customStatus: customStatus ?? this.customStatus,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      meowCoins: meowCoins ?? this.meowCoins,
      unlockedStickerIds: unlockedStickerIds ?? this.unlockedStickerIds,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      equippedBadge: equippedBadge ?? this.equippedBadge,
      friendIds: friendIds ?? this.friendIds,
      isBot: isBot,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarEmoji': avatarEmoji,
      'avatarColorHex': avatarColorHex,
      'presence': presence.name,
      'customStatus': customStatus,
      'role': role.name,
      'bio': bio,
      'meowCoins': meowCoins,
      'unlockedStickerIds': unlockedStickerIds,
      'unlockedBadges': unlockedBadges,
      'equippedBadge': equippedBadge,
      'friendIds': friendIds,
      'isBot': isBot,
    };
  }

  factory CatUser.fromMap(Map<String, dynamic> map) {
    return CatUser(
      id: map['id'] ?? '',
      username: map['username'] ?? 'mystery_cat',
      displayName: map['displayName'] ?? 'Mystery Cat',
      avatarEmoji: map['avatarEmoji'] ?? '🐱',
      avatarColorHex: map['avatarColorHex'] ?? '#FF7EB6',
      presence: CatPresence.values.firstWhere(
        (e) => e.name == map['presence'],
        orElse: () => CatPresence.purring,
      ),
      customStatus: map['customStatus'] ?? 'Purring loudly 🐾',
      role: CatRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => CatRole.kitten,
      ),
      bio: map['bio'] ?? '',
      meowCoins: (map['meowCoins'] as num?)?.toInt() ?? 100,
      unlockedStickerIds: List<String>.from(
        map['unlockedStickerIds'] ??
            const ['sticker_loaf', 'sticker_zoomies', 'sticker_boop', 'sticker_tuna'],
      ),
      unlockedBadges: List<String>.from(
        map['unlockedBadges'] ?? const ['🐾 Day One Paws'],
      ),
      equippedBadge: map['equippedBadge'],
      friendIds: List<String>.from(map['friendIds'] ?? const []),
      isBot: map['isBot'] ?? false,
    );
  }
}
