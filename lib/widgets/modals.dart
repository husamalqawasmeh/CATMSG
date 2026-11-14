import 'package:flutter/material.dart';
import '../models/cat_server.dart';
import '../models/cat_user.dart';
import '../services/cat_backend_service.dart';
import '../theme/cat_theme.dart';

class CatModals {
  static const List<String> catAvatarOptions = [
    '😼',
    '🐱',
    '😻',
    '😺',
    '🐈‍⬛',
    '🦁',
    '🐯',
    '🦊',
    '🐾',
    '👑',
  ];

  static const List<String> serverEmojiOptions = [
    '🏰',
    '☕',
    '⚡',
    '🐟',
    '🧶',
    '📦',
    '🌙',
    '🌿',
  ];

  static void showCreateServerDialog(
    BuildContext context,
    CatBackendService backend,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedEmoji = '🐟';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Text('🏰 '),
              Text(
                'Create a New Cat House',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a Cat House Icon:',
                  style: TextStyle(
                    color: CatTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: serverEmojiOptions.map((emoji) {
                    final selected = emoji == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = emoji),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? CatTheme.pawPink.withValues(alpha: 0.25)
                              : CatTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selected ? CatTheme.pawPink : Colors.transparent,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cat House Name',
                    hintText: 'e.g. Tuna Lovers Society',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What do cats do in this server?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CatTheme.pawPink,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                backend.createCatServer(
                  name: nameCtrl.text,
                  iconEmoji: selectedEmoji,
                  description: descCtrl.text,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Create Cat House',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showCreateChannelDialog(
    BuildContext context,
    CatBackendService backend, {
    required String defaultCategoryId,
  }) {
    final nameCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    CatChannelType selectedType = CatChannelType.text;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text(
            '🐾 Create Channel',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CatChannelType>(
                  value: selectedType,
                  dropdownColor: CatTheme.cardBg,
                  decoration: const InputDecoration(labelText: 'Channel Type'),
                  items: const [
                    DropdownMenuItem(
                      value: CatChannelType.text,
                      child: Text('🐾 Standard Meow Chat'),
                    ),
                    DropdownMenuItem(
                      value: CatChannelType.announcements,
                      child: Text('📣 Royal Announcements'),
                    ),
                    DropdownMenuItem(
                      value: CatChannelType.catnipLounge,
                      child: Text('🌿 Cozy Catnip Lounge'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Channel Name',
                    hintText: 'e.g. midnight-snacks',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Channel Topic',
                    hintText: 'What should cats discuss here?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CatTheme.pawPink,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                backend.createChannelInCurrentServer(
                  categoryId: defaultCategoryId,
                  channelName: nameCtrl.text,
                  topic: topicCtrl.text,
                  type: selectedType,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Create Channel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditProfileDialog(
    BuildContext context,
    CatBackendService backend,
  ) {
    final user = backend.currentUser;
    final nameCtrl = TextEditingController(text: user.displayName);
    final statusCtrl = TextEditingController(text: user.customStatus);
    final bioCtrl = TextEditingController(text: user.bio);
    String selectedEmoji = user.avatarEmoji;
    String? selectedBadge = user.equippedBadge;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  backend.isArabic
                      ? '😼 إعدادات حساب القطة واللغة'
                      : '😼 Cat Profile & UI Settings',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CatTheme.meowCoinGold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  backend.isArabic ? '👑 المالك' : '👑 OWNER',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🌐 UI Language / لغة الواجهة:',
                    style: TextStyle(
                      color: CatTheme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !backend.isArabic
                                ? CatTheme.pawPink.withValues(alpha: 0.2)
                                : CatTheme.cardBg,
                            side: BorderSide(
                              color: !backend.isArabic
                                  ? CatTheme.pawPink
                                  : Colors.white24,
                            ),
                          ),
                          onPressed: () {
                            backend.setLocaleCode('en');
                            setModalState(() {});
                          },
                          child: const Text('🇬🇧 English (LTR)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: backend.isArabic
                                ? CatTheme.pawPink.withValues(alpha: 0.2)
                                : CatTheme.cardBg,
                            side: BorderSide(
                              color: backend.isArabic
                                  ? CatTheme.pawPink
                                  : Colors.white24,
                            ),
                          ),
                          onPressed: () {
                            backend.setLocaleCode('ar');
                            setModalState(() {});
                          },
                          child: const Text('🇸🇦 العربية (RTL)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CatTheme.catnipMint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CatTheme.catnipMint.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              backend.isArabic
                                  ? '💾 حفظ بيانات المستخدم'
                                  : '💾 USER DATA SAVING & BACKUP',
                              style: const TextStyle(
                                color: CatTheme.catnipMint,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '✓ ${backend.lastSavedTime}',
                              style: const TextStyle(
                                color: CatTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            backend.isArabic
                                ? 'الحفظ التلقائي للبيانات'
                                : 'Auto-Save User Data',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          value: backend.autoSaveEnabled,
                          onChanged: (val) {
                            backend.toggleAutoSave(val);
                            setModalState(() {});
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await backend.saveUserDataNow();
                                  setModalState(() {});
                                },
                                icon: const Text('💾'),
                                label: Text(
                                  backend.isArabic
                                      ? 'حفظ الآن'
                                      : 'Save Data Now',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pick Cat Avatar:',
                    style: TextStyle(
                      color: CatTheme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: catAvatarOptions.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedEmoji = emoji),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CatTheme.pawPink.withValues(alpha: 0.25)
                                : CatTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? CatTheme.pawPink
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cat Display Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: statusCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Custom Cat Status',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Cat Bio',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (user.unlockedBadges.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: user.unlockedBadges.contains(selectedBadge)
                          ? selectedBadge
                          : user.unlockedBadges.first,
                      dropdownColor: CatTheme.cardBg,
                      decoration:
                          const InputDecoration(labelText: 'Equipped Badge'),
                      items: user.unlockedBadges
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedBadge = val),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CatTheme.pawPink,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                backend.updateProfile(
                  displayName: nameCtrl.text,
                  avatarEmoji: selectedEmoji,
                  customStatus: statusCtrl.text,
                  bio: bioCtrl.text,
                  equippedBadge: selectedBadge,
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Save Paws',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showUserProfileModal(
    BuildContext context,
    CatBackendService backend,
    CatUser user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: CatTheme.fromHex(user.avatarColorHex)
                        .withValues(alpha: 0.25),
                    child: Text(
                      user.avatarEmoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: CatTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: CatTheme.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.presence.iconEmoji} ${user.presence.label}',
                          style: TextStyle(
                            color: user.presence.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    Text(
                      '${user.role.badgeEmoji} Role: ${user.role.title}',
                      style: TextStyle(
                        color: user.role.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.customStatus,
                      style: const TextStyle(
                        color: CatTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: const TextStyle(
                        color: CatTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (user.id != backend.currentUser.id)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: CatTheme.pawPink,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      backend.openDmConversation(user.id);
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: Text(
                      'Send Direct Meow to ${user.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPinnedMessagesModal(
    BuildContext context,
    CatBackendService backend,
  ) {
    final pinned =
        backend.activeMessages.where((m) => m.isPinned).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text('📌 '),
            Text(
              'Pinned Scratching Post Messages',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: pinned.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No pinned messages in this channel yet! Click "Pin" on any message to save it here.',
                    style: TextStyle(color: CatTheme.textSecondary),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: pinned
                      .map(
                        (m) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CatTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(m.senderAvatar),
                                  const SizedBox(width: 6),
                                  Text(
                                    m.senderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: CatTheme.pawPink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m.content,
                                style: const TextStyle(
                                  color: CatTheme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void showFirebaseAndAuthDialog(
    BuildContext context,
    CatBackendService backend,
  ) {
    final emailCtrl = TextEditingController(
      text: '${backend.currentUser.username}@catmsg.app',
    );
    final passCtrl = TextEditingController(text: 'meowmeow123');
    final nameCtrl = TextEditingController(
      text: backend.currentUser.displayName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              backend.useFirebase
                  ? Icons.cloud_done_rounded
                  : Icons.bolt_rounded,
              color: CatTheme.meowCoinGold,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Firebase Auth & Cloud Firestore',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CatTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: backend.useFirebase
                          ? CatTheme.catnipMint
                          : CatTheme.meowCoinGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backend.useFirebase
                            ? '🟢 Connected to Live Firebase Project'
                            : '🟡 Running in Instant Demo + Local Sync Mode',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CatTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'To connect your own live Firebase project, run:\n`flutterfire configure`\nin the project folder. CatMsg will automatically switch from Local Demo Mode to live Firebase Auth + Cloud Firestore!',
                        style: TextStyle(
                          color: CatTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SIGN IN / SWITCH CAT ACCOUNT',
                  style: TextStyle(
                    color: CatTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cat Display Name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email / Cat Handle',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (for Firebase Auth)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (backend.useFirebase)
            OutlinedButton.icon(
              onPressed: () {
                backend.seedFirestoreDatabase();
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.storage_rounded, size: 16),
              label: const Text('Seed Firestore'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CatTheme.pawPink,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              backend.signInOrSwitchCatAccount(
                emailOrUsername: emailCtrl.text,
                password: passCtrl.text,
                displayName: nameCtrl.text,
                avatarEmoji: backend.currentUser.avatarEmoji,
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Sign In / Switch Cat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
