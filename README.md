# 🐾 CatMsg (PurrCord) — Flutter + Firebase Cat-Themed Discord App

A responsive, cat-themed Discord-style messaging app built with **Flutter** and **Firebase (`firebase_auth` + `cloud_firestore`)**, complete with **Cat Houses (Servers)**, **Direct Meows (DMs)**, **Cat Reactions & Stickers**, **Member Presence/Roles**, and **Quests & MeowCoins (`🪙`)**.

---

## ✨ Features

- **🏰 Cat Houses (Servers) & Channels**:
  - Left server rail with animated selection pills, unread/quest badges, and a `+` modal to create new Cat Houses.
  - Collapsible channel categories (`📌 WELCOME MAT`, `💬 MEOW CHATS`, `🌿 CATNIP LOUNGES`) and channel creation.
- **💬 Real-Time Chat, Replies, Stickers & Cat Reactions**:
  - Reply to messages with Discord-style thread connectors (`╭── ↩️ @Mochi...`).
  - React to any message with Cat Emojis (`🐾`, `😻`, `🐟`, `🧶`, `🥛`, `😾`, `⚡`, `👑`).
  - Send illustrated **Cat Stickers** (`10/10 Loaf`, `3AM Zoomies`, `Snoot Boop`, `Gib Tuna`, `Bongo Paws`, `Red Dot Target`, `If I Fits I Sits`, `Emperor Meow`).
  - Pin important messages to the channel's Pinned Scratching Post and search/filter messages.
- **🐾 Direct Meows (DMs) & Cat Friends**:
  - Dedicated **Cat Friends** dashboard (`Online`, `All Cats`, `+ Add Cat Friend`).
  - 1-on-1 DM conversations with a right-hand **Cat Dossier** profile sidebar.
- **🐈 Member List, Cat Presence & Roles**:
  - Members grouped by Castle Roles (`👑 Supreme Loaf`, `🛡️ Mod-erater`, `🐾 Senior Paws`, `🧶 Kitten`).
  - Live presence switcher (`🟢 Purring`, `🌙 Catnapping`, `⛔ Hissing`, `⚪ Stray`).
- **🪙 Quests & MeowCoin Emporium**:
  - Automatic quest tracking for chatting, reacting with paws, replying, sending stickers, DMs, and exploring channels.
  - Claim **MeowCoins (`🪙`)** from completed quests and spend them in the **MeowCoin Emporium** to unlock premium Cat Stickers and Royal Profile Badges (`🐟 Tuna Tycoon`, `🧶 Yarn Master`, `🌙 Midnight Zoomer`, `👑 Royal Whisker`).
- **📱💻 Responsive Layout**:
  - **Desktop / Web**: Full 4-pane Discord layout (`Server Rail` + `Channel Sidebar` + `Chat / Quests View` + `Member Sidebar`).
  - **Mobile / Narrow**: Sliding left & right Discord drawers + bottom quick navigation bar.

---

## 🚀 Getting Started

### 1. Run Immediately (Instant Demo + Local Sync Mode)
If you haven't generated platform runners yet in this folder, run:
```bash
cd "c:\Users\pitot\Projects 4\catmsg"
flutter create .
flutter pub get
flutter run
```
Out of the box, CatMsg starts in **Instant Demo + Local Sync Mode** with pre-seeded Cat Houses, interactive cat bot replies, quests, and MeowCoins so you can test every feature right away.

### 2. Connect Your Live Firebase Project (Auth + Cloud Firestore)
Whenever you are ready to connect your live Firebase backend:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
`flutterfire configure` will overwrite `lib/firebase_options.dart` with your real API keys. On the next run, `DefaultFirebaseOptions.isFirebaseConfigured` automatically switches the app to live **Firebase Auth** and **Cloud Firestore** (and you can click the cloud icon in the bottom-left Server Rail to sign in or one-click seed initial Cat Houses into Firestore).
