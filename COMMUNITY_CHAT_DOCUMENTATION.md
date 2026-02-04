# Community Chat Feature Documentation

## Overview

The Community Chat feature allows users to create public communities where all messages are visible to all members. When a user sends a message in a community, it's broadcasted to everyone in that community.

## Features

### 1. **Create Community**
- Users can create new public communities by clicking the "Create" button
- Each community requires:
  - **Name**: Required (minimum 3 characters)
  - **Description**: Optional (explains what the community is about)
- The creator automatically becomes a member and admin of the community

### 2. **Join Community**
- Users can browse all available communities in the Community tab
- Users can join any community by clicking the "Join" button
- After joining, users can immediately start chatting

### 3. **Community Broadcasting**
- **All messages are visible to all members** - This is the key feature
- When a user sends a message, it appears to everyone in the community in real-time
- Messages are organized chronologically with:
  - Sender's name and profile image
  - Message content
  - Timestamp (e.g., "5m ago", "2h ago")

### 4. **Community Features**
- **View Members**: See all community members and identify the admin
- **Leave Community**: Users can leave at any time and rejoin later
- **Real-time Updates**: Messages appear instantly for all members using Firestore listeners
- **Message Status**: Shows when messages are sent with timestamps

## Architecture

### Data Models

**ChatModel (Community Type)**
```dart
ChatModel(
  id: String,
  participantIds: List<String>,        // All community members
  groupName: String,                   // Community name
  groupDescription: String?,           // Community description
  chatType: ChatType.community,        // Type = community
  createdBy: String,                   // Community admin
  isGroupChat: true,                   // Always true for communities
)
```

**MessageModel**
```dart
MessageModel(
  id: String,
  chatId: String,                      // Community ID
  senderId: String,                    // Who sent it
  content: String,                     // Message content
  createdAt: DateTime,                 // When sent
  readBy: List<String>,                // Who read it
)
```

### Services

#### ChatService Methods
- `createCommunityChat()` - Creates a new community
- `getCommunityChats()` - Gets all communities (Stream)
- `joinCommunityChat()` - Adds user to community
- `leaveCommunityChat()` - Removes user from community
- `sendMessage()` - Sends a message to the community
- `getMessages()` - Gets all messages in a community (Stream)

#### ChatProvider Methods
- `loadCommunityChats()` - Loads all communities
- `createCommunityChat()` - Creates new community with UI handling
- `joinCommunityChat()` - Joins community with error handling
- `leaveCommunityChat()` - Leaves community with error handling
- `sendMessage()` - Sends message to current community
- `selectChat()` - Opens a community and loads messages

### UI Components

#### CommunityBroadcastScreen
Main screen for viewing and interacting with a community:
- **Header**: Shows community name and member count
- **Description Banner**: Displays community description
- **Messages Area**: Shows all messages with sender info
- **Members Dialog**: Shows all community members
- **Input Area**: TextField for composing messages
- **Send Button**: Sends message to all community members

#### CommunityChatScreen
List view of all communities:
- **Create Button**: Opens dialog to create new community
- **Community Cards**: Shows each community with:
  - Community name and description
  - Member count
  - Join/Open button
- **Empty State**: Prompts to create first community

## Firestore Structure

```
chats/{communityId}
├── id: String
├── chatType: "community"
├── groupName: String
├── groupDescription: String
├── participantIds: [userId1, userId2, ...]
├── createdBy: String
├── createdAt: Timestamp
├── lastMessage: String
├── lastMessageSenderId: String
├── lastMessageTime: Timestamp
└── messages/{messageId}
    ├── id: String
    ├── senderId: String
    ├── content: String
    ├── type: "text"
    ├── createdAt: Timestamp
    ├── readBy: [userId1, userId2, ...]
    └── isRead: Boolean
```

## How Messages Work

1. **Sending a Message**:
   ```dart
   // User types message and clicks send
   chatProvider.sendMessage(
     senderId: currentUserId,
     content: messageText,
   )
   ```

2. **Broadcasting**:
   - Message is saved to Firestore under community's subcollection
   - Community's `lastMessage` is updated
   - Firestore listener triggers for all connected users

3. **Receiving Messages**:
   - All members are subscribed via `getMessages(communityId)` stream
   - When new message is added, everyone sees it immediately
   - Messages are displayed with sender information

## Usage Flow

### For Creating Community
```
1. User taps "Create" button
2. Dialog opens with name and description fields
3. User fills in details and clicks "Create"
4. Community is created in Firestore
5. User is automatically added to participantIds
6. User navigates to community broadcast screen
7. User can now send messages visible to all
```

### For Joining Community
```
1. User views Community tab
2. Browses list of communities
3. Taps "Join" on desired community
4. User is added to participantIds
5. User can now view and send messages
```

### For Sending Messages
```
1. User opens community
2. Types message in input field
3. Taps send button
4. Message is saved to Firestore
5. All community members see it instantly
6. Message appears with sender's name and profile
```

## Security Considerations

### Firestore Rules
Ensure these rules are set for communities:
```firestore
match /chats/{chatId} {
  allow read: if request.auth != null && 
              request.auth.uid in resource.data.participantIds;
  allow create: if request.auth != null;
  allow update: if request.auth != null && 
                request.auth.uid == resource.data.createdBy;
  
  match /messages/{messageId} {
    allow read: if request.auth != null && 
                request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
    allow create: if request.auth != null && 
                  request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
  }
}
```

## Performance Optimizations

1. **Efficient User Caching**: Users are cached to avoid repeated fetches
2. **Stream Listeners**: Real-time updates via Firestore streams
3. **Limited Message Loading**: Messages are loaded in chunks of 50
4. **Post-frame Callbacks**: UI updates happen after frame to avoid conflicts

## Testing Community Chat

1. **Create Community**:
   - Create a new community from Community tab
   - Verify it appears in the list

2. **Join Community**:
   - Create community as User A
   - Join same community as User B
   - Verify both see each other in members list

3. **Send Messages**:
   - User A sends: "Hello Everyone!"
   - Verify User B sees it immediately
   - Verify sender name and profile appear

4. **Leave Community**:
   - User B leaves community
   - Verify User B is removed from participants
   - Verify User A still sees the messages

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   ├── chat_model.dart
│   │   ├── message_model.dart
│   │   └── user_model.dart
│   ├── services/
│   │   └── chat_service.dart
│   └── ...
├── providers/
│   └── chat_provider.dart
├── ui/
│   └── screens/
│       └── chat/
│           ├── community_chat_screen.dart      (List of communities)
│           ├── community_broadcast_screen.dart (Main broadcast chat)
│           ├── chat_screen.dart                (Generic chat screen)
│           └── chat_list_screen.dart
└── ...
```

## Future Enhancements

- [ ] Community moderation (delete inappropriate messages)
- [ ] Community rules/guidelines
- [ ] Pinned messages
- [ ] Community search
- [ ] Message reactions/emoji
- [ ] Media sharing (images, videos)
- [ ] Message search within community
- [ ] Community notifications settings
- [ ] Community badges/categories
