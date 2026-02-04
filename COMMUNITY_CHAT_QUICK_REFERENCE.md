# Community Chat - Quick Reference

## 🎯 What Is It?

A **broadcast messaging system** where:
- Users create public communities
- When someone sends a message, **EVERYONE in the community sees it**
- Messages are visible to all members in real-time

## 🚀 Quick Start

### For Users:
1. **Create a Community**: Community tab → Create button → Fill details
2. **Join a Community**: Community tab → Browse → Click "Join"
3. **Send a Message**: Open community → Type in input field → Send
4. **Leave**: Tap menu → "Leave Community"

### For Developers:
```dart
// Send message to community (visible to all members)
await chatProvider.sendMessage(
  senderId: userId,
  content: "Hello everyone!",
  type: MessageType.text,
);

// Join community
await chatProvider.joinCommunityChat(communityId, userId);

// Create community
await chatProvider.createCommunityChat(
  name: "Community Name",
  creatorId: userId,
  description: "Optional description",
);
```

## 📁 Files Involved

| File | Purpose |
|------|---------|
| `community_broadcast_screen.dart` | **Main UI** - Shows all messages visible to all |
| `community_chat_screen.dart` | Community list screen |
| `chat_provider.dart` | State management |
| `chat_service.dart` | Firestore operations |
| `chat_model.dart` | Data model |

## 🔄 Message Flow

```
User types & sends
    ↓
Message saved to Firestore
    ↓
All members notified via Stream
    ↓
UI updates for everyone
    ↓
All see message with sender info
```

## ✨ Key Features

| Feature | How It Works |
|---------|------------|
| 📢 Broadcast | Messages sent to all community members |
| 👥 Member List | View all members, see who's admin |
| ⏱️ Real-time | Updates instantly via Firestore streams |
| 📊 Timestamps | Shows "5m ago", "2h ago", etc. |
| 👤 Sender Info | Name and profile picture with each message |
| 🚪 Leave/Join | Can leave and rejoin anytime |

## 🛡️ Security

- Users can only message communities they've joined
- Messages only visible to community members
- Firestore rules enforce access control

## 🧪 Testing Quick Checklist

- [ ] Create community with name + description
- [ ] Join community as different user
- [ ] Send message - verify all see it
- [ ] Check timestamps display correctly
- [ ] View members - verify list accuracy
- [ ] Leave community - verify it works
- [ ] Rejoin - verify message history still there
- [ ] Profile pictures load correctly
- [ ] No crashes or errors

## 📊 Firestore Schema

```
chats/{communityId}
  ├── id, groupName, groupDescription
  ├── participantIds: [userId1, userId2, ...]
  ├── chatType: "community"
  └── messages/{messageId}
      ├── senderId, content, createdAt
      └── readBy: [userId1, userId2, ...]
```

## 🎨 UI Components

### CommunityBroadcastScreen
- Community name & member count in header
- Description banner
- Messages list (all messages visible)
- Input field at bottom
- Send button
- Menu with Members & Leave options

### Message Display
- Sender's avatar & name (left side)
- Message bubble (different color for current user)
- Timestamp below message
- Animations on load

## ⚡ Performance Tips

1. **Lazy Load**: Users loaded on-demand
2. **Stream Cache**: Avoid re-fetching
3. **Batch Messages**: Load 50 at a time
4. **Efficient Queries**: Proper Firestore indexes

## 🔧 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Messages not appearing | Verify user in participantIds, check Firestore |
| Slow message delivery | Check network, verify Firestore indexes |
| Profile images missing | Verify profileImageUrl in user model |
| Can't send message | Verify user is community member |

## 📚 Related Documentation

- [Full Community Chat Documentation](COMMUNITY_CHAT_DOCUMENTATION.md)
- [Implementation Guide](COMMUNITY_CHAT_IMPLEMENTATION.md)
- [Main README](README.md)

## 🎓 Code Examples

### Send Message
```dart
final chatProvider = context.read<ChatProvider>();
final success = await chatProvider.sendMessage(
  senderId: currentUserId,
  content: messageText,
  type: MessageType.text,
);
```

### Open Community
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CommunityBroadcastScreen(
      community: communityModel,
    ),
  ),
);
```

### Load Communities
```dart
final chatProvider = context.read<ChatProvider>();
chatProvider.loadCommunityChats(); // Loads all communities
```

## 🚀 Getting Started

1. Navigate to Community tab in app
2. Click "Create" to make new community
3. Enter community details
4. You're now in the broadcast chat!
5. Type messages - everyone sees them instantly

---

**Status**: ✅ Fully Implemented
**Last Updated**: February 2026
