# Firebase Schema Documentation - CodeClub

**Project**: CodeClub - Hackathon Team Matching Platform  
**Firebase Project ID**: `codeclub-b8e50`  
**Storage Bucket**: `gs://codeclub-b8e50.firebasestorage.app`  
**Document Version**: March 2026

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Firebase Configuration](#firebase-configuration)
3. [Firestore Collections](#firestore-collections)
4. [Data Models](#data-models)
5. [Data Relationships](#data-relationships)
6. [Services Layer](#services-layer)
7. [File Storage](#file-storage)
8. [Security Rules](#security-rules)
9. [State Management](#state-management)
10. [API Reference](#api-reference)

---

## Project Overview

### Architecture Pattern
CodeClub follows a **Clean Architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────┐
│     UI Layer (lib/ui/)              │
│  - Screens, Widgets, Components     │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Provider Layer (lib/providers/)    │
│  - State Management (Provider pkg)  │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   Services Layer (lib/data/services)│
│  - Firebase Integration             │
│  - Chat Service, Auth, User, Team   │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Firebase Backend                   │
│  - Firestore, Authentication        │
│  - Cloud Storage                    │
└─────────────────────────────────────┘
```

### Key Features
- ✅ Multi-platform support (Android, iOS, macOS, Web, Windows)
- ✅ Real-time chat (1-on-1, team, group, community)
- ✅ Team management with join requests
- ✅ Hackathon event management
- ✅ User profile with skill matching
- ✅ Firebase Authentication with email validation

---

## Firebase Configuration

### Platform Configurations

| Platform | Configuration | Details |
|----------|----------------|---------|
| **Android** | `android/app/google-services.json` | API Key + App ID |
| **iOS** | `GoogleService-Info.plist` | API Key (shared with macOS) |
| **macOS** | Info.plist | Shared with iOS config |
| **Web** | `_firebaseConfig` in index.html | API Key + Measurement ID |
| **Windows** | Web configuration | Desktop support |

### Email Validation Rules
```dart
// Primary domain (institutional)
@apsit.edu.in  // APSIT students

// Testing/Development
@gmail.com     // Firebase emulator & testing
```

### Initialization
```dart
// lib/main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Firestore Collections

### Collection Hierarchy Overview

```
Firestore Database: projects/codeclub-b8e50/databases/(default)
├── users/                          [Top-level Collection]
├── teams/                          [Top-level Collection]
├── teamRequests/                   [Top-level Collection]
├── chats/                          [Top-level Collection]
│   └── {chatId}/messages/         [Subcollection]
├── communityChats/                 [Top-level Collection - DEPRECATED]
└── hackathons/                     [Top-level Collection]
```

---

## Firestore Collections (Detailed Schema)

### 1. Collection: `users`

**Purpose**: User/Student profiles and authentication data storage

**Document Path**: `users/{userId}` where `{userId}` = Firebase Auth UID

**Schema**:
```json
{
  "uid": "string (Document ID)",
  "email": "string",
  "fullName": "string",
  "branch": "string (e.g., 'Computer Science', 'IT')",
  "year": "string (e.g., 'FE', 'SE', 'TE', 'BE')",
  "skills": ["array<string> - Technical skills"],
  "role": "string (e.g., 'Developer', 'Designer', 'Manager')",
  "bio": "string (nullable) - User biography",
  "profileImageUrl": "string (nullable) - Firebase Storage path",
  "currentTeamId": "string (reference/nullable) - Link to teams/{teamId}",
  "linkedInUrl": "string (nullable) - LinkedIn profile URL",
  "githubUrl": "string (nullable) - GitHub profile URL",
  "isProfileComplete": "boolean - Profile completion flag",
  "createdAt": "timestamp - Account creation time",
  "updatedAt": "timestamp - Last profile update"
}
```

**Example Document**:
```json
{
  "uid": "user123abc",
  "email": "john.doe@apsit.edu.in",
  "fullName": "John Doe",
  "branch": "Computer Science",
  "year": "TE",
  "skills": ["Flutter", "Dart", "Firebase", "Python"],
  "role": "Developer",
  "bio": "Passionate about mobile development",
  "profileImageUrl": "users/user123abc/profile_image.jpg",
  "currentTeamId": "team456def",
  "linkedInUrl": "https://linkedin.com/in/johndoe",
  "githubUrl": "https://github.com/johndoe",
  "isProfileComplete": true,
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-02-20T14:45:30Z"
}
```

**Important Relationships**:
- `uid` = Firebase Authentication UID (auto-generated)
- `currentTeamId` → links to `teams/{currentTeamId}`
- `profileImageUrl` → stored in Cloud Storage

**Read/Write Rules**:
- ✅ Users can write their own data
- ✅ All authenticated users can read profiles
- ❌ Users cannot modify other users' data

**Indexes**: None required (simple document reads)

---

### 2. Collection: `teams`

**Purpose**: Hackathon team organization and member management

**Document Path**: `teams/{teamId}` where `{teamId}` = auto-generated

**Schema**:
```json
{
  "name": "string - Team display name",
  "leaderId": "string (reference) - Link to users/{leaderId}",
  "memberIds": ["array<string> - References to users collection"],
  "maxSize": "number - Maximum team members (typically 4-6)",
  "hackathonName": "string (nullable) - Associated hackathon name",
  "description": "string (nullable) - Team description/tagline",
  "isOpen": "boolean - Open for new member requests",
  "createdAt": "timestamp - Team creation time",
  "updatedAt": "timestamp - Last modification time"
}
```

**Example Document**:
```json
{
  "name": "Tech Innovators",
  "leaderId": "user123abc",
  "memberIds": ["user123abc", "user456def", "user789ghi"],
  "maxSize": 4,
  "hackathonName": "Hackathon 2026",
  "description": "Building AI-powered mobile solutions",
  "isOpen": false,
  "createdAt": "2025-02-01T09:00:00Z",
  "updatedAt": "2025-02-15T16:20:00Z"
}
```

**Utility Methods** (in TeamModel):
```dart
bool isFull()              // memberIds.length >= maxSize
int availableSlots()       // maxSize - memberIds.length
bool isMember(userId)      // userId in memberIds
```

**Important Relationships**:
- `leaderId` → refers to `users/{leaderId}`
- `memberIds` → array of references to `users/{userId}`
- `hackathonName` → loose reference to hackathons (not enforced)

**Read/Write Rules**:
- ✅ All authenticated users can read team data
- ✅ Team lead can update team info
- ✅ Team members can delete their membership
- ✅ Any authenticated user can send join requests

**Indexes**:
- Needed for queries: `isOpen == true AND createdAt DESC`

---

### 3. Collection: `teamRequests`

**Purpose**: Manage team join requests and invitations

**Document Path**: `teamRequests/{requestId}` where `{requestId}` = auto-generated

**Schema**:
```json
{
  "fromUserId": "string (reference) - Request sender (Link to users/)",
  "toUserId": "string (reference) - Request recipient (Link to users/)",
  "teamId": "string (reference/nullable) - Target team (Link to teams/)",
  "message": "string (nullable) - Request message/motivation",
  "status": "enum - pending | accepted | rejected",
  "createdAt": "timestamp - Request creation time",
  "updatedAt": "timestamp - Last status update"
}
```

**Status Enum Values**:
```dart
enum TeamRequestStatus {
  pending,    // Awaiting response
  accepted,   // Request approved
  rejected    // Request declined
}
```

**Example Document**:
```json
{
  "fromUserId": "user999xyz",
  "toUserId": "user123abc",
  "teamId": "team456def",
  "message": "I have experience with Flutter and Firebase, interested in joining!",
  "status": "pending",
  "createdAt": "2025-02-10T11:30:00Z",
  "updatedAt": "2025-02-10T11:30:00Z"
}
```

**Important Relationships**:
- `fromUserId` → `users/{fromUserId}` (request sender)
- `toUserId` → `users/{toUserId}` (typically team lead)
- `teamId` → `teams/{teamId}` (target team)

**Read/Write Rules**:
- ✅ Users involved in request can read
- ✅ All authenticated users can create requests
- ✅ Team lead can update status
- ✅ Request can be deleted by initiator or recipient

**Indexes**:
- Needed for queries: `toUserId == userId AND status == pending`
- Needed for queries: `teamId == teamId AND status == pending`

---

### 4. Collection: `chats`

**Purpose**: Multi-type conversation management (1-on-1, team, group, community)

**Document Path**: `chats/{chatId}` where `{chatId}` = auto-generated

**Main Document Schema**:
```json
{
  "id": "string (Document ID)",
  "participantIds": ["array<string> - Chat participants (users refs)"],
  "chatType": "enum - private | team | group | community",
  "isGroupChat": "boolean - Flag for group/team chats",
  "teamId": "string (reference/nullable) - For team chats Link to teams/",
  "hackathonId": "string (reference/nullable) - Associated hackathon",
  "createdBy": "string (reference) - Chat creator/admin (Link to users/)",
  "groupName": "string (nullable) - For team/group/community chats",
  "groupDescription": "string (nullable) - Chat purpose description",
  "groupImageUrl": "string (nullable) - Chat avatar/icon path",
  "lastMessage": "string (nullable) - Last message content preview",
  "lastMessageSenderId": "string (nullable) - Sender of last message",
  "lastMessageTime": "timestamp (nullable) - Last message timestamp",
  "createdAt": "timestamp - Chat creation time",
  "updatedAt": "timestamp (nullable) - Last update"
}
```

**Subcollection: `chats/{chatId}/messages`**
```json
{
  "id": "string (Document ID)",
  "chatId": "string - Reference to parent chat",
  "senderId": "string (reference) - Message sender (Link to users/)",
  "content": "string - Message text content",
  "type": "enum - text | image | file | system",
  "createdAt": "timestamp - Message sent time",
  "isRead": "boolean - Read status for individual chats",
  "readBy": ["array<string> - User IDs who read (for group chats)"]
}
```

**ChatType Enum**:
```dart
enum ChatType {
  private,    // 1-on-1 conversation
  team,       // Team members only
  group,      // Custom group
  community   // Broadcast to all users
}
```

**MessageType Enum**:
```dart
enum MessageType {
  text,      // Text message
  image,     // Image attachment
  file,      // File attachment
  system     // System notification
}
```

**Example: Private Chat Document**:
```json
{
  "id": "chat001",
  "participantIds": ["user123abc", "user456def"],
  "chatType": "private",
  "isGroupChat": false,
  "teamId": null,
  "hackathonId": null,
  "createdBy": "user123abc",
  "groupName": null,
  "groupDescription": null,
  "groupImageUrl": null,
  "lastMessage": "See you at the hackathon!",
  "lastMessageSenderId": "user456def",
  "lastMessageTime": "2025-02-20T15:45:00Z",
  "createdAt": "2025-02-10T10:00:00Z",
  "updatedAt": "2025-02-20T15:45:00Z"
}
```

**Example: Team Chat Document**:
```json
{
  "id": "chat002",
  "participantIds": ["user123abc", "user456def", "user789ghi"],
  "chatType": "team",
  "isGroupChat": true,
  "teamId": "team456def",
  "hackathonId": "hackathon2026",
  "createdBy": "user123abc",
  "groupName": "Tech Innovators Team Chat",
  "groupDescription": "Discussion channel for team strategy",
  "groupImageUrl": "chats/chat002/team_avatar.jpg",
  "lastMessage": "The deployment is ready for demo!",
  "lastMessageSenderId": "user789ghi",
  "lastMessageTime": "2025-02-20T14:30:00Z",
  "createdAt": "2025-02-01T09:00:00Z",
  "updatedAt": "2025-02-20T14:30:00Z"
}
```

**Example: Community Chat Document**:
```json
{
  "id": "chat_community_main",
  "participantIds": ["*all authenticated users*"],
  "chatType": "community",
  "isGroupChat": true,
  "teamId": null,
  "hackathonId": "hackathon2026",
  "createdBy": "admin_user",
  "groupName": "Global Community Chat",
  "groupDescription": "Connect with all hackathon participants",
  "groupImageUrl": "chats/chat_community_main/community_avatar.jpg",
  "lastMessage": "Excited for the hackathon to begin!",
  "lastMessageSenderId": "user999xyz",
  "lastMessageTime": "2025-02-20T13:00:00Z",
  "createdAt": "2025-01-15T00:00:00Z",
  "updatedAt": "2025-02-20T13:00:00Z"
}
```

**Subcollection Message Example**:
```
chats/chat001/messages/{messageId}
{
  "id": "msg_001",
  "chatId": "chat001",
  "senderId": "user123abc",
  "content": "Hi! How are you doing?",
  "type": "text",
  "createdAt": "2025-02-20T15:30:00Z",
  "isRead": true,
  "readBy": null
}
```

**Important Relationships**:
- `participantIds` → array of `users/{userId}`
- `createdBy` → `users/{createdBy}`
- `teamId` → `teams/{teamId}` (for team chats)
- `hackathonId` → `hackathons/{hackathonId}` (optional)
- Messages stored in subcollection `chats/{chatId}/messages/{messageId}`

**Read/Write Rules**:
- **Private Chats**: Only participants can read/write
- **Team Chats**: Only team members can read/write
- **Group Chats**: Invited members only
- **Community Chats**: All authenticated users can read/write

**Indexes**:
- Needed: `participantIds ARRAY-CONTAINS userId ORDER BY lastMessageTime DESC`
- Needed: `chatType == community ORDER BY lastMessageTime DESC`

---

### 5. Collection: `communityChats` (DEPRECATED)

**Status**: ⚠️ **LEGACY - Use `chats` collection with `chatType: community` instead**

This collection is deprecated. All community chat functionality has been merged into the main `chats` collection using `chatType: community`.

---

### 6. Collection: `hackathons`

**Purpose**: Hackathon event management and registration tracking

**Document Path**: `hackathons/{hackathonId}` where `{hackathonId}` = auto-generated

**Schema**:
```json
{
  "title": "string - Hackathon name",
  "description": "string - Event description",
  "imageUrl": "string (nullable) - Event poster/banner image",
  "startDate": "timestamp - Event start date/time",
  "endDate": "timestamp - Event end date/time",
  "registrationDeadline": "timestamp - Last registration time",
  "venue": "string - Event location",
  "website": "string (nullable) - Hackathon website URL",
  "minTeamSize": "number - Minimum team members",
  "maxTeamSize": "number - Maximum team members",
  "prizes": ["array<string> - Prize descriptions"],
  "rules": ["array<string> - Event rules (nullable)"],
  "registeredTeamIds": ["array<string> - Team references"],
  "registeredIndividualIds": ["array<string> - Individual participant references"],
  "isActive": "boolean - Active status flag",
  "createdAt": "timestamp - Creation time",
  "updatedAt": "timestamp - Last update time"
}
```

**Example Document**:
```json
{
  "title": "Hackathon 2026 - Innovation Challenge",
  "description": "24-hour hackathon focused on AI and mobile development",
  "imageUrl": "hackathons/hack2026/poster.jpg",
  "startDate": "2026-03-20T09:00:00Z",
  "endDate": "2026-03-21T09:00:00Z",
  "registrationDeadline": "2026-03-18T23:59:00Z",
  "venue": "APSIT Campus, Mumbai",
  "website": "https://hackathon2026.com",
  "minTeamSize": 2,
  "maxTeamSize": 4,
  "prizes": [
    "₹50,000 - Grand Prize",
    "₹30,000 - Second Place",
    "₹20,000 - Third Place",
    "Internship opportunities with sponsors"
  ],
  "rules": [
    "Original code only",
    "No pre-built solutions",
    "Team members must be present",
    "Code must be submitted by deadline"
  ],
  "registeredTeamIds": ["team456def", "team789ghi", "team101jkl"],
  "registeredIndividualIds": ["userABC123", "userDEF456"],
  "isActive": true,
  "createdAt": "2025-12-01T10:00:00Z",
  "updatedAt": "2026-02-15T18:30:00Z"
}
```

**Important Relationships**:
- `registeredTeamIds` → array of references to `teams/{teamId}`
- `registeredIndividualIds` → array of references to `users/{userId}`

**Read/Write Rules**:
- ✅ All authenticated users can read
- ❌ Only admins can create/edit
- ✅ Users can only modify their own registration

**Indexes**:
- Needed: `isActive == true ORDER BY startDate DESC`
- Needed: `startDate > now ORDER BY startDate ASC` (upcoming events)

---

## Data Models

### 1. UserModel

**File**: `lib/data/models/user_model.dart`

```dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String branch;
  final String year;
  final List<String> skills;
  final String role;
  final String? bio;
  final String? profileImageUrl;
  final String? currentTeamId;
  final String? linkedInUrl;
  final String? githubUrl;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Methods
  factory UserModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  UserModel copyWith({...})
}
```

**Serialization**:
```dart
// Deserialize from Firestore
UserModel.fromFirestore(doc) {
  return UserModel(
    uid: doc.id,
    email: doc['email'],
    // ... other fields
  );
}

// Serialize to Firestore
toFirestore() {
  return {
    'email': email,
    'fullName': fullName,
    'createdAt': FieldValue.serverTimestamp(),
    // ... other fields
  };
}
```

---

### 2. TeamModel

**File**: `lib/data/models/team_model.dart`

```dart
class TeamModel {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberIds;
  final int maxSize;
  final String? hackathonName;
  final String? description;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Utility methods
  bool isFull()
  int availableSlots()
  bool isMember(String userId)

  // Serialization methods
  factory TeamModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  TeamModel copyWith({...})
}
```

---

### 3. ChatModel

**File**: `lib/data/models/chat_model.dart`

```dart
enum ChatType { private, team, group, community }

class ChatModel {
  final String id;
  final List<String> participantIds;
  final ChatType chatType;
  final bool isGroupChat;
  final String? teamId;
  final String? hackathonId;
  final String? createdBy;
  final String? groupName;
  final String? groupDescription;
  final String? groupImageUrl;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Serialization methods
  factory ChatModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  ChatModel copyWith({...})
}
```

---

### 4. MessageModel

**File**: `lib/data/models/message_model.dart`

```dart
enum MessageType { text, image, file, system }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final List<String>? readBy;

  // Serialization methods
  factory MessageModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  MessageModel copyWith({...})
}
```

---

### 5. TeamRequestModel

**File**: `lib/data/models/team_request_model.dart`

```dart
enum TeamRequestStatus { pending, accepted, rejected }

class TeamRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? teamId;
  final String? message;
  final TeamRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Serialization methods
  factory TeamRequestModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  TeamRequestModel copyWith({...})
}
```

---

### 6. HackathonModel

**File**: `lib/data/models/hackathon_model.dart`

```dart
class HackathonModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final String venue;
  final String? website;
  final int minTeamSize;
  final int maxTeamSize;
  final List<String> prizes;
  final List<String>? rules;
  final List<String> registeredTeamIds;
  final List<String> registeredIndividualIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Serialization methods
  factory HackathonModel.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()
  HackathonModel copyWith({...})
}
```

---

## Data Relationships

### Entity Relationship Diagram

```
┌──────────────────┐
│     Users        │
│   (uid as PK)    │
├──────────────────┤
│ - uid (PK)       │
│ - email          │
│ - fullName       │
│ - skills[]       │
│ - currentTeamId  │──────────┐
│ - createdAt      │          │
└──────────────────┘          │
         │                    │
         │ (1 -- many)        │
         │                    │
         ▼                    ▼
┌──────────────────────────────────┐
│         Teams                    │
│    (teamId as PK)                │
├──────────────────────────────────┤
│ - teamId (PK)                    │
│ - leaderId (FK → users)          │
│ - memberIds[] (FK → users)       │
│ - hackathonName                  │
│ - maxSize                        │
│ - createdAt                      │
└──────────────────────────────────┘
     │     │
     │     └─── many-to-many relationship
     │
     ▼
┌──────────────────────────────────┐
│   Hackathons                     │
│ (hackathonId as PK)              │
├──────────────────────────────────┤
│ - hackathonId (PK)               │
│ - title                          │
│ - startDate, endDate             │
│ - registeredTeamIds[]            │
│ - registeredIndividualIds[]      │
│ - createdAt                      │
└──────────────────────────────────┘


         ┌──────────────────────┐
         │  TeamRequests        │
         │ (requestId as PK)    │
         ├──────────────────────┤
         │ - fromUserId (FK)    │──► users/fromUserId
         │ - toUserId (FK)      │──► users/toUserId
         │ - teamId (FK)        │──► teams/teamId
         │ - status             │
         │ - createdAt          │
         └──────────────────────┘


         ┌──────────────────────┐
         │     Chats            │
         │  (chatId as PK)      │
         ├──────────────────────┤
         │ - chatId (PK)        │
         │ - participantIds[] ──────► users collection
         │ - chatType           │
         │ - teamId (FK)        │──► teams/teamId
         │ - createdBy (FK)     │──► users/createdBy
         │ - createdAt          │
         │                      │
         │ Subcollection:       │
         │ └─ messages/         │
         │    - messageId (PK)  │
         │    - senderId ───────────► users/senderId
         │    - createdAt       │
         └──────────────────────┘
```

### Relationship Matrix

| From | To | Type | Field | Cardinality |
|------|----|----|-------|-------------|
| users | teams | currentTeamId | currentTeamId | 1-to-many |
| teams | users | leaderId | leaderId | 1-to-many |
| teams | users | members | memberIds[] | many-to-many |
| teams | hackathons | hackathonName | hackathonName | 1-to-many |
| chat | users | participants | participantIds[] | many-to-many |
| chat | teams | team chat | teamId | 1-to-many |
| messages | chat | parent | chatId | many-to-1 |
| messages | users | sender | senderId | many-to-1 |
| teamRequests | users | from/to | fromUserId/toUserId | 1-to-many |
| teamRequests | teams | target | teamId | 1-to-many |
| hackathons | teams | registered | registeredTeamIds[] | 1-to-many |
| hackathons | users | registered | registeredIndividualIds[] | 1-to-many |

---

## Services Layer

### 1. AuthService

**File**: `lib/data/services/auth_service.dart`

**Purpose**: Firebase Authentication and user account management

**Key Methods**:

```dart
// Authentication
Future<UserModel> signUp(String email, String password, Map userData)
Future<UserModel> signIn(String email, String password)
Future<void> signOut()

// User Management
Future<void> sendPasswordResetEmail(String email)
Future<UserModel?> getUserProfile()
Stream<UserModel?> authStateChanges()

// Validation
bool validateEmailDomain(String email)  // @apsit.edu.in or @gmail.com
```

**Email Validation Logic**:
```dart
// Allowed domains
const ALLOWED_DOMAINS = ['@apsit.edu.in', '@gmail.com'];

// Custom exception handling
class FirebaseAuthException extends FirebaseException {
  // User-friendly error messages
}
```

**Data Flow**:
1. User enters email + password
2. Firebase Auth validates credentials
3. Auto-creates Firestore document in `users/{uid}`
4. Returns UserModel or throws FirebaseAuthException

---

### 2. UserService

**File**: `lib/data/services/user_service.dart`

**Purpose**: User profile CRUD operations and searching

**Key Methods**:

```dart
// Retrieve
Future<UserModel?> getUserById(String userId)
Stream<UserModel?> getUserStream(String userId)
Future<List<UserModel>> getAllUsers()

// Search
Future<List<UserModel>> searchUsersByName(String searchTerm)
Future<List<UserModel>> searchUsersBySkill(String skill)
Future<List<UserModel>> searchUsersByRole(String role)
Future<List<UserModel>> searchUsersByYear(String year)
Future<List<UserModel>> getUsersByIds(List<String> userIds)

// Update
Future<void> updateUserProfile(String userId, Map<String, dynamic> data)
Future<void> setCurrentTeam(String userId, String teamId)
Future<void> clearCurrentTeam(String userId)

// Profile Completion
Future<void> markProfileComplete(String userId)
```

**Batch Operations**:
- `getUsersByIds()` handles Firestore's 10-reference limit by batching queries

**Search Indexes**:
- Firestore composite indexes needed for complex search queries
- Range queries on array fields (skills, preferences)

---

### 3. TeamService

**File**: `lib/data/services/team_service.dart`

**Purpose**: Team CRUD and membership management

**Key Methods**:

```dart
// Team CRUD
Future<String> createTeam(TeamModel team, String leaderId)
Future<TeamModel?> getTeamById(String teamId)
Future<List<TeamModel>> getOpenTeams()
Future<List<TeamModel>> getTeamsByHackathon(String hackathonName)
Future<void> updateTeam(String teamId, Map<String, dynamic> data)
Future<void> deleteTeam(String teamId)

// Member Management
Future<void> addMember(String teamId, String userId)
Future<void> removeMember(String teamId, String userId)
Future<bool> isMember(String teamId, String userId)

// Team Requests
Future<void> sendTeamRequest(TeamRequestModel request)
Future<void> acceptTeamRequest(String requestId)
Future<void> rejectTeamRequest(String requestId)
Future<List<TeamRequestModel>> getTeamRequests(String userId)
Future<List<TeamRequestModel>> getPendingRequests(String teamId)
```

**Business Logic**:
- Validates team size before adding members
- Updates `users.currentTeamId` on member addition
- Automatic cleanup of requests on acceptance/rejection

---

### 4. ChatService

**File**: `lib/data/services/chat_service.dart`

**Purpose**: Multi-type conversation management

**Key Methods**:

```dart
// Chat Management (All Types)
Future<ChatModel> getOrCreatePrivateChat(String userId1, String userId2)
Future<ChatModel> createTeamChat(String teamId, String teamName)
Future<ChatModel> createGroupChat(String groupName, List<String> participantIds)
Future<ChatModel> createCommunityChat(String chatName, String hackathonId)
Future<ChatModel?> getChatById(String chatId)
Future<List<ChatModel>> getUserChats(String userId)
Future<List<ChatModel>> getCommunityChats(String hackathonId)

// Message Operations
Future<void> sendMessage(MessageModel message)
Future<Stream<List<MessageModel>>> getMessagesStream(
  String chatId,
  {int limit = 50}
)
Future<void> updateLastMessage(String chatId, String message, String senderId)
Future<void> markAsRead(String chatId, String messageId, String userId)

// Participant Management
Future<void> addParticipant(String chatId, String userId)
Future<void> removeParticipant(String chatId, String userId)
Future<void> joinCommunityChat(String chatId, String userId)
Future<void> leaveCommunityChat(String chatId, String userId)

// Chat Updates
Future<void> updateChatInfo(
  String chatId,
  String? groupName,
  String? description,
  String? imageUrl
)
```

**Auto-Messaging Feature**:
- Last message updated automatically on each send
- `lastMessageTime` used for chat list sorting
- `lastMessageSenderId` for UI display

**Message Ordering**:
- Messages ordered by `createdAt DESC` (newest first)
- Default limit of 50 messages (pagination support)

**Read Status**:
- Individual chats: `isRead` boolean per message
- Group chats: `readBy` array of user IDs

---

### 5. HackathonService

**File**: `lib/data/services/hackathon_service.dart`

**Purpose**: Hackathon event data management

**Key Methods**:

```dart
// Retrieve
Future<List<HackathonModel>> getAllHackathons()
Future<List<HackathonModel>> getActiveHackathons()
Future<List<HackathonModel>> getUpcomingHackathons()
Future<List<HackathonModel>> getOngoingHackathons()
Future<HackathonModel?> getHackathonById(String hackathonId)
Stream<HackathonModel?> getHackathonStream(String hackathonId)

// Registration
Future<void> registerTeam(String hackathonId, String teamId)
Future<void> registerIndividual(String hackathonId, String userId)
Future<void> unregisterTeam(String hackathonId, String teamId)
Future<void> unregisterIndividual(String hackathonId, String userId)
```

**Date-Based Filtering**:
```dart
// Upcoming: startDate > now
// Ongoing: now between startDate and endDate
// Past: endDate < now
```

---

### 6. NotificationService

**File**: `lib/data/services/notification_service.dart`

**Purpose**: Local push notifications for app events

**Key Methods**:

```dart
// Initialization
Future<void> initialize()
Future<void> initializePlatformSpecifics()

// Notifications
Future<void> showMessageNotification({
  required String senderName,
  required String message,
  required String payloadChatId
})

Future<void> showTeamInviteNotification({
  required String teamName,
  required String message
})

// Handlers
void handleNotificationTap(NotificationResponse response)
```

**Platform Support**:
- Android: Uses `flutter_local_notifications` with NotificationChannel
- iOS: Configured with UNUserNotificationCenter
- Web: Notification API compatibility

---

## File Storage

### Cloud Storage Structure

**Bucket**: `gs://codeclub-b8e50.firebasestorage.app`

```
storage-bucket/
│
├── users/
│   ├── {userId}/
│   │   ├── profile_image.jpg
│   │   └── profile_image_thumb.jpg
│   ├── user123abc/
│   │   └── profile_image.jpg
│   └── user456def/
│       └── profile_image.jpg
│
├── chats/
│   ├── {chatId}/
│   │   ├── group_avatar.jpg
│   │   ├── messages_images/
│   │   │   ├── msg_001_image.jpg
│   │   │   └── msg_002_image.jpg
│   │   └── attachments/
│   │       ├── msg_005_document.pdf
│   │       └── msg_010_archive.zip
│   └── chat002/
│       ├── team_avatar.jpg
│       └── messages_images/
│           └── msg_001_image.jpg
│
├── hackathons/
│   ├── {hackathonId}/
│   │   ├── poster.jpg
│   │   ├── banner.jpg
│   │   └── logo.png
│   └── hack2026/
│       └── poster.jpg
│
└── temp/
    └── uploads_in_progress/
```

### Usage in Firestore

**User Profile Image**:
```json
{
  "profileImageUrl": "users/user123abc/profile_image.jpg"
}
```

**Chat Group Avatar**:
```json
{
  "groupImageUrl": "chats/chat002/team_avatar.jpg"
}
```

**Hackathon Poster**:
```json
{
  "imageUrl": "hackathons/hack2026/poster.jpg"
}
```

### Storage Access Rules

**Location**: `firestore.storage.rules` (if configured)

```firestore
// Users can upload their own profile images
match /users/{userId}/profile_image.jpg {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}

// Chat participants can access group images
match /chats/{chatId}/{allPaths=**} {
  allow read: if request.auth != null && request.auth.uid in resource.data.participantIds;
  allow write: if request.auth != null && request.auth.uid == resource.data.createdBy;
}
```

---

## Security Rules

### Firestore Security Rules

**File**: `firestore.rules`

**Complete Rule Structure**:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== USERS COLLECTION =====
    match /users/{userId} {
      // Users can read all user profiles (for search/discovery)
      allow read: if request.auth != null;
      
      // Users can only write their own data
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ===== TEAMS COLLECTION =====
    match /teams/{teamId} {
      // All authenticated users can read team data
      allow read: if request.auth != null;
      
      // Create: Any authenticated user
      allow create: if request.auth != null;
      
      // Update: Team lead or members only
      allow update: if request.auth != null && 
                       (request.auth.uid == resource.data.leaderId || 
                        request.auth.uid in resource.data.memberIds);
      
      // Delete: Team lead only
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.leaderId;
    }
    
    // ===== TEAM REQUESTS COLLECTION =====
    match /teamRequests/{requestId} {
      // Users involved can read their requests
      allow read: if request.auth != null && 
                     (request.auth.uid == resource.data.fromUserId || 
                      request.auth.uid == resource.data.toUserId);
      
      // Any authenticated user can create requests
      allow create: if request.auth != null;
      
      // Only requestor or recipient can update
      allow update: if request.auth != null && 
                       (request.auth.uid == resource.data.fromUserId || 
                        request.auth.uid == resource.data.toUserId);
      
      // Only requestor can delete
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.fromUserId;
    }
    
    // ===== CHATS COLLECTION =====
    match /chats/{chatId} {
      // Participants can read chat metadata
      allow read: if request.auth != null && 
                     (request.auth.uid in resource.data.participantIds ||
                      resource.data.chatType == 'community');
      
      // Any authenticated user can create
      allow create: if request.auth != null;
      
      // Only chat creator/members can update
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.participantIds;
      
      // Messages subcollection
      match /messages/{messageId} {
        // Participants can read messages
        allow read: if request.auth != null && 
                       (request.auth.uid in resource.parent.data.participantIds ||
                        resource.parent.data.chatType == 'community');
        
        // Participants (and community users) can create
        allow create: if request.auth != null;
        
        // Sender can update their own messages
        allow update: if request.auth != null && 
                         request.auth.uid == resource.data.senderId;
        
        // Sender can delete their messages
        allow delete: if request.auth != null && 
                         request.auth.uid == resource.data.senderId;
      }
    }
    
    // ===== HACKATHONS COLLECTION =====
    match /hackathons/{hackathonId} {
      // All authenticated users can read
      allow read: if request.auth != null;
      
      // Only admins can create/update (custom claim check)
      allow create, update: if request.auth != null && 
                               request.auth.token.admin == true;
      
      // Only admins can delete
      allow delete: if request.auth != null && 
                       request.auth.token.admin == true;
    }
  }
}
```

### Key Security Principles

1. **Authentication Required**: All operations require `request.auth != null`
2. **User Privacy**: Users can only modify their own data
3. **Team Hierarchy**: Team lead has special privileges
4. **Chat Privacy**: Only participants can access chat content
5. **Community Access**: Community chats readable by all authenticated users
6. **Admin Controls**: Hackathon management restricted to admins (custom claims)

---

## State Management

### Provider Architecture

**File**: `lib/main.dart`

**Providers Used**:

```dart
MultiProvider(
  providers: [
    // Authentication State
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
    ),
    
    // Team Management
    ChangeNotifierProvider<TeamProvider>(
      create: (_) => TeamProvider(),
    ),
    
    // Chat Management
    ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(),
    ),
    
    // Hackathon Data
    ChangeNotifierProvider<HackathonProvider>(
      create: (_) => HackathonProvider(),
    ),
    
    // Theme Management
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
  ],
  child: MyApp(),
)
```

### Provider Responsibilities

| Provider | Purpose | Key Methods |
|----------|---------|------------|
| **AuthProvider** | Auth state & login | `signUp()`, `signIn()`, `signOut()`, `getCurrentUser()` |
| **TeamProvider** | Team operations | `createTeam()`, `joinTeam()`, `getTeams()`, `updateTeam()` |
| **ChatProvider** | Chat operations | `getChats()`, `sendMessage()`, `createChat()`, `getMessages()` |
| **HackathonProvider** | Hackathon data | `getHackathons()`, `registerHackathon()`, `getActive()` |
| **ThemeProvider** | Theme switching | `toggleTheme()`, `setTheme()` |

### State Flow Pattern

```
UI Layer
  ↓
Provider (Listen for changes)
  ↓
Service Layer (Business logic)
  ↓
Firestore (Data persistence)
  ↓
Local Notifications (Events)
```

---

## API Reference

### Authentication Flow

```
signup(email, password) → Firebase Auth → Create users/{uid} → UserModel

signin(email, password) → Firebase Auth → Fetch users/{uid} → UserModel

signout() → Clear Auth → Update local state

sendPasswordReset(email) → Firebase Auth email sent
```

### Team Join Flow

```
User A wants to join Team B

1. User A: sendTeamRequest(fromUserId=A, toUserId=teamLead, teamId=B)
   ↓
2. Create teamRequests/{requestId} with status=pending
   ↓
3. Team Lead receives notification
   ↓
4. Team Lead: acceptTeamRequest(requestId)
   ↓
5. Update: teamRequests.status = accepted
           teams.memberIds += [A]
           users.currentTeamId = B
```

### Chat Message Flow

```
User A sends message to Chat X

1. User A: sendMessage(content, chatId=X)
   ↓
2. Create chats/X/messages/{messageId}
   ↓
3. Update chats/X:
     - lastMessage = content
     - lastMessageSenderId = A
     - lastMessageTime = serverTimestamp()
   ↓
4. Show notification to chat participants
   ↓
5. Reorder chat list by lastMessageTime
```

### Search & Discovery

```
Search for users with skill "Flutter":

1. Client: searchUsersBySkill("Flutter")
   ↓
2. Query: users where skills ARRAY-CONTAINS "Flutter"
   ↓
3. Return: List<UserModel> ordered by createdAt DESC
   ↓
4. UI: Display user cards with connect button
```

### Hackathon Registration

```
Team registers for hackathon:

1. Team clicks "Register for Hackathon"
   ↓
2. registerTeam(hackathonId, teamId)
   ↓
3. Update hackathons/{hackathonId}:
     - registeredTeamIds += [teamId]
     - Create community chat if not exists
   ↓
4. Add team members to community chat
```

---

## Performance Optimization

### Indexes Required

To ensure optimal query performance, create these composite indexes in Firestore:

```
Collection: users
- Index 1: skills (ARRAY), createdAt (DESCENDING)
- Index 2: year, branch, createdAt (DESCENDING)

Collection: teams
- Index 1: isOpen, createdAt (DESCENDING)
- Index 2: hackathonName, createdAt (DESCENDING)

Collection: chats
- Index 1: participantIds (ARRAY), lastMessageTime (DESCENDING)
- Index 2: chatType, lastMessageTime (DESCENDING)

Collection: teamRequests
- Index 1: toUserId, status, createdAt (DESCENDING)
- Index 2: teamId, status, createdAt (DESCENDING)

Collection: hackathons
- Index 1: isActive, startDate (DESCENDING)
- Index 2: endDate, startDate (DESCENDING)
```

### Pagination Strategy

**For Message Lists**:
```dart
// Fetch 50 messages per page
messages = QuerySnapshot.limit(50)
                        .orderBy('createdAt', descending: true)

// Load more on scroll
lastDocument = result.docs.last
nextBatch = collection.startAfter(lastDocument)
                      .limit(50)
```

**For User/Team Lists**:
```dart
// Initial load: first 20 documents
users = collection.limit(20)

// Load more
nextBatch = collection.startAfter(lastDoc).limit(20)
```

---

## Limits & Quotas

### Firestore Limits

| Limit | Value | Impact |
|-------|-------|--------|
| Max document size | 1 MB | Keep arrays reasonably sized |
| Max field count | 20,000 | Use subcollections for scalability |
| Max read ops/second | Depends on region | Implement caching for popular docs |
| Array size | Not limited | But keep < 10,000 for performance |
| Ref array limit | 10 references per query | Batch `getUsersByIds()` in chunks of 10 |

### Practical Constraints

- **Team memberIds**: Keep array < 100 (typical team size 2-6)
- **Chat participantIds**: Keep < 200 for group chats
- **Message batch size**: Load 50 messages per pagination
- **Search results**: Limit to top 100 results per query

---

## Troubleshooting & Common Issues

### Issue: Message not appearing in chat

**Checklist**:
- [ ] User in `chats/{chatId}.participantIds`?
- [ ] Message created in `chats/{chatId}/messages/{msgId}`?
- [ ] `lastMessageTime` updated in parent chat doc?
- [ ] Real-time listener active in UI?

**Solution**:
```dart
// Ensure chat listener is active
StreamBuilder(
  stream: chatService.getMessagesStream(chatId),
  builder: (context, snapshot) {
    // Rebuild on new messages
  }
)
```

### Issue: Team member not appearing

**Checklist**:
- [ ] User ID in `teams.memberIds` array?
- [ ] User `currentTeamId` updated?
- [ ] Firestore rules allow read access?

**Debug**:
```dart
// Check team data
teams.get(teamId).then((doc) {
  print('Members: ${doc.data().memberIds}');
});
```

### Issue: Search returns no results

**Solutions**:
1. Verify composite index exists in Firestore console
2. Check query field names match exactly
3. Ensure documents have required fields
4. Check security rules allow read access

---

## Summary

**Total Collections**: 7  
**Total Data Models**: 6  
**Total Services**: 6  
**Total Providers**: 5  
**Platforms Supported**: 5

This schema provides a comprehensive, scalable foundation for the CodeClub hackathon team-matching platform with real-time communication, team management, and event organization capabilities.

---

**Document Last Updated**: March 2026  
**Maintainer**: AI Coding Agent  
**Version**: 1.0
