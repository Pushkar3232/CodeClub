# CodeClub — Admin Module Documentation
**Project**: CodeClub — Hackathon Team Matching Platform  
**Firebase Project**: `codeclub-b8e50`  
**Module**: Admin Panel (Flutter)  
**Document Version**: March 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Schema Changes Required](#2-schema-changes-required)
3. [Admin Authentication](#3-admin-authentication)
4. [Admin Data Model](#4-admin-data-model)
5. [Admin Service Layer](#5-admin-service-layer)
6. [Firebase Security Rules (Updated)](#6-firebase-security-rules-updated)
7. [Admin Dashboard](#7-admin-dashboard)
8. [Hackathon CRUD Module](#8-hackathon-crud-module)
9. [State Management — AdminProvider](#9-state-management--adminprovider)
10. [Navigation & Routing](#10-navigation--routing)
11. [File & Folder Structure](#11-file--folder-structure)
12. [New Firestore Indexes Required](#12-new-firestore-indexes-required)
13. [Implementation Checklist](#13-implementation-checklist)

---

## 1. Overview

The Admin Module is a protected section of the CodeClub Flutter app accessible only to designated administrators. Admins can authenticate with a special admin credential, view a real-time dashboard of platform statistics, and perform full **Create / Read / Update / Delete (CRUD)** operations on Hackathons.

### What the Admin Can Do

| Capability | Description |
|---|---|
| **Authenticate** | Sign in with an admin-designated email; access is verified via Firebase Custom Claims |
| **Dashboard** | View live stats — total users, teams, active hackathons, registrations |
| **Create Hackathon** | Add a new hackathon event with all details including prizes, rules, dates, venue |
| **Read Hackathons** | View all hackathons (active + past) in a sortable list |
| **Update Hackathon** | Edit any field of an existing hackathon |
| **Delete Hackathon** | Soft-delete or permanently remove a hackathon |
| **Toggle Active Status** | Quickly flip a hackathon from active ↔ inactive |
| **View Registrations** | See which teams and individuals have registered for a hackathon |

### What the Admin Cannot Do From This Panel (V1 Scope)

- Directly manage user accounts (ban/delete users) — deferred to V2
- Manage teams — deferred to V2
- Send push notifications — deferred to V2

---

## 2. Schema Changes Required

The existing schema needs the following additions. **No existing fields should be removed.**

### 2.1 Add `admins` Collection (New)

Create a new top-level Firestore collection `admins` to store admin profiles separately from regular users.

**Collection Path**: `admins/{adminId}`

**Schema**:
```json
{
  "uid": "string — Firebase Auth UID (same as document ID)",
  "email": "string — Admin email address",
  "displayName": "string — Admin's full name",
  "role": "string — enum: superadmin | admin",
  "createdAt": "timestamp — When admin account was created",
  "lastLoginAt": "timestamp — Last successful login",
  "isActive": "boolean — Whether this admin account is enabled"
}
```

**Example Document**:
```json
{
  "uid": "adminUID123",
  "email": "admin@apsit.edu.in",
  "displayName": "Dr. Ramesh Kumar",
  "role": "superadmin",
  "createdAt": "2026-01-01T00:00:00Z",
  "lastLoginAt": "2026-03-13T10:00:00Z",
  "isActive": true
}
```

**Why a separate collection?** This keeps admin data cleanly separated from student data, makes security rule checks straightforward, and prevents any accidental exposure of admin metadata to regular users.

---

### 2.2 Update `users` Collection — Add `isAdmin` Field

Add a boolean field `isAdmin` to the existing `users` schema. This is a **lightweight flag** for quick client-side checks and is always validated server-side via Firebase Custom Claims.

```json
{
  "isAdmin": "boolean — Defaults to false for all regular users"
}
```

> ⚠️ **Important**: `isAdmin: true` alone is NOT sufficient for security. All admin Firestore operations must be protected by Firebase Custom Claims (`request.auth.token.admin == true`) in Security Rules. The `isAdmin` field is for UI routing only.

---

### 2.3 Update `hackathons` Collection — Add Admin Metadata Fields

Add the following fields to each hackathon document to support admin management:

```json
{
  "createdByAdminId": "string — UID of admin who created this hackathon",
  "lastEditedByAdminId": "string (nullable) — UID of admin who last edited",
  "lastEditedAt": "timestamp (nullable) — Timestamp of last edit",
  "isDeleted": "boolean — Soft-delete flag (defaults to false)",
  "deletedAt": "timestamp (nullable) — When it was soft-deleted",
  "tags": "array<string> (nullable) — e.g. ['AI', 'Mobile', 'Web'] for filtering",
  "status": "string — enum: draft | published | ongoing | completed | cancelled"
}
```

**Status Enum Explained**:

| Status | Meaning |
|---|---|
| `draft` | Created by admin but not yet visible to students |
| `published` | Visible to students, registration open |
| `ongoing` | Hackathon is currently happening |
| `completed` | Event has ended |
| `cancelled` | Cancelled by admin, hidden from students |

> **Note**: The existing `isActive` boolean field should be kept for backward compatibility but `status` now provides finer control. When `status == published`, `isActive` should be `true`. Wherever the app reads `isActive`, it should also be updated to read `status`.

---

### 2.4 Updated Firestore Collection Hierarchy

```
Firestore Database
├── users/              [existing — add isAdmin field]
├── teams/              [no changes]
├── teamRequests/       [no changes]
├── chats/              [no changes]
│   └── {chatId}/messages/
├── hackathons/         [existing — add admin metadata fields + status]
└── admins/             [NEW — admin profiles]
```

---

## 3. Admin Authentication

### 3.1 Strategy: Firebase Custom Claims

Admin authentication uses the same Firebase Authentication system as regular users, but admin accounts are granted a **Custom Claim** (`admin: true`) by a Cloud Function or manually via Firebase Admin SDK. The Flutter app checks this claim after login.

**Flow**:
```
Admin enters email + password
        ↓
Firebase Auth validates credentials
        ↓
App fetches ID Token from Firebase Auth
        ↓
App decodes token and checks: token.claims['admin'] == true
        ↓
   YES → Navigate to Admin Dashboard
   NO  → Show "Unauthorized" error, sign out
```

### 3.2 Setting Up Admin Custom Claims

This is a **one-time server-side setup** done per admin account using the Firebase Admin SDK (Node.js or Python). It is not done from the Flutter app.

**Using Firebase Admin SDK (Node.js)**:
```javascript
// Run this script once per admin to grant access
admin.auth().setCustomUserClaims(uid, { admin: true });
```

**Using Firebase CLI (quick setup)**:
```bash
# Via Cloud Functions HTTP call or Firebase Admin SDK script
# Set custom claim on the target UID
```

Once the claim is set, the user's next login will include `admin: true` in their ID token.

### 3.3 Admin Login Screen

The admin login screen is a **separate route** from the regular student login. It should be accessible via a hidden route (e.g., accessed from the Settings screen or a dedicated URL on web). Do not expose an obvious "Admin Login" button to regular students.

**UI Elements Required**:
- Email text field (pre-filled hint: `admin@apsit.edu.in`)
- Password text field (obscured)
- "Sign In as Admin" button
- Error message display for unauthorized accounts
- Loading indicator during authentication

**Validation**:
- Email must not be empty
- Password must not be empty
- After Firebase login succeeds, check ID token for `admin` claim
- If claim is absent → call `signOut()` and display "You are not authorized as an admin"

### 3.4 Keeping Admin Session Secure

- Admin session should **auto-expire** if the app is backgrounded for more than 30 minutes (optional, V2)
- On app restart, re-check the ID token claim before showing the Admin Dashboard
- If `isActive == false` in the `admins` collection → deny access and sign out even if claim is present
- Admin logout must call `FirebaseAuth.instance.signOut()`

---

## 4. Admin Data Model

Create a new model file for admin data.

**File**: `lib/data/models/admin_model.dart`

```
AdminModel
  ├── uid: String
  ├── email: String
  ├── displayName: String
  ├── role: AdminRole (enum: superadmin | admin)
  ├── isActive: bool
  ├── createdAt: DateTime
  └── lastLoginAt: DateTime

Methods:
  ├── AdminModel.fromFirestore(DocumentSnapshot doc)
  ├── Map<String, dynamic> toFirestore()
  └── AdminModel copyWith({...})
```

**HackathonModel Updates** (`lib/data/models/hackathon_model.dart`):

Add to the existing `HackathonModel`:

```
New fields:
  ├── createdByAdminId: String
  ├── lastEditedByAdminId: String?
  ├── lastEditedAt: DateTime?
  ├── isDeleted: bool
  ├── deletedAt: DateTime?
  ├── tags: List<String>?
  └── status: HackathonStatus (enum)

New enum:
HackathonStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled
}
```

---

## 5. Admin Service Layer

Create a dedicated service for all admin operations.

**File**: `lib/data/services/admin_service.dart`

### 5.1 Authentication Methods

```
Future<AdminModel?> signInAdmin(String email, String password)
  → Signs in via Firebase Auth
  → Fetches ID token and checks admin claim
  → Reads admin document from admins/{uid}
  → Updates lastLoginAt timestamp
  → Returns AdminModel on success, throws on failure

Future<void> signOutAdmin()
  → Calls FirebaseAuth.instance.signOut()
  → Clears local admin state

Future<bool> isCurrentUserAdmin()
  → Fetches current user's ID token result
  → Returns token.claims['admin'] == true

Stream<AdminModel?> adminAuthStateChanges()
  → Listens to Firebase auth state
  → On each auth state change, checks admin claim
  → Returns stream of AdminModel or null
```

### 5.2 Dashboard Stats Methods

```
Future<AdminDashboardStats> getDashboardStats()
  → Fetches counts from:
      users collection (total users)
      teams collection (total teams)
      hackathons collection where isDeleted == false (total hackathons)
      hackathons where status == 'published' or 'ongoing' (active hackathons)
  → Returns a DashboardStats data class

Stream<int> getTotalUsersStream()
  → Real-time count of users collection

Stream<int> getTotalTeamsStream()
  → Real-time count of teams collection

Stream<int> getActiveHackathonsStream()
  → Real-time count of hackathons where isActive == true
```

**AdminDashboardStats Data Class**:
```
AdminDashboardStats {
  int totalUsers
  int totalTeams
  int totalHackathons
  int activeHackathons
  int totalRegisteredTeams     // sum across all hackathons
  int totalRegisteredIndividuals
}
```

### 5.3 Hackathon CRUD Methods

```
// CREATE
Future<String> createHackathon(HackathonModel hackathon, String adminId)
  → Validates all required fields
  → Sets createdByAdminId = adminId
  → Sets createdAt = serverTimestamp()
  → Sets isDeleted = false
  → Sets status = 'draft' by default
  → Returns the new document ID

// READ
Future<List<HackathonModel>> getAllHackathons({bool includeDeleted = false})
  → Fetches all hackathons
  → Filters out isDeleted == true unless includeDeleted is true
  → Ordered by createdAt descending

Stream<List<HackathonModel>> getHackathonsStream({bool includeDeleted = false})
  → Real-time stream version of getAllHackathons

Future<HackathonModel?> getHackathonById(String hackathonId)
  → Fetches a single hackathon document

// UPDATE
Future<void> updateHackathon(String hackathonId, Map<String, dynamic> data, String adminId)
  → Updates specified fields
  → Automatically sets lastEditedByAdminId = adminId
  → Automatically sets lastEditedAt = serverTimestamp()

Future<void> toggleHackathonStatus(String hackathonId, HackathonStatus newStatus, String adminId)
  → Updates only status and isActive fields
  → Used for quick status toggling from the list

// DELETE
Future<void> softDeleteHackathon(String hackathonId, String adminId)
  → Sets isDeleted = true
  → Sets deletedAt = serverTimestamp()
  → Sets status = 'cancelled'
  → Does NOT remove the document from Firestore

Future<void> permanentlyDeleteHackathon(String hackathonId)
  → Hard-deletes the document from Firestore
  → Also removes the associated banner image from Firebase Storage
  → Should only be available to superadmin role

// IMAGE UPLOAD
Future<String> uploadHackathonBanner(String hackathonId, File imageFile)
  → Uploads to Firebase Storage path: hackathons/{hackathonId}/banner.jpg
  → Returns the download URL
  → Replaces existing banner if one exists

Future<void> deleteHackathonBanner(String hackathonId)
  → Deletes image from Storage path: hackathons/{hackathonId}/banner.jpg
```

### 5.4 Registration View Methods

```
Future<List<TeamModel>> getRegisteredTeams(String hackathonId)
  → Reads registeredTeamIds[] from hackathon document
  → Batch-fetches team documents in chunks of 10 (Firestore limit)
  → Returns List<TeamModel>

Future<List<UserModel>> getRegisteredIndividuals(String hackathonId)
  → Reads registeredIndividualIds[] from hackathon document
  → Batch-fetches user documents
  → Returns List<UserModel>
```

---

## 6. Firebase Security Rules (Updated)

Update the Firestore Security Rules to protect admin operations. The key principle is: **client-side admin checks (isAdmin field) are for UI only; all Firestore write protection uses Custom Claims**.

### 6.1 `admins` Collection Rules

```javascript
match /admins/{adminId} {
  // Only the admin themselves can read their own document
  allow read: if request.auth != null && request.auth.uid == adminId
              && request.auth.token.admin == true;

  // Only admins can write to the admins collection
  // (In practice, admin creation should go through Cloud Functions)
  allow write: if request.auth != null
               && request.auth.token.admin == true
               && request.auth.token.role == 'superadmin';
}
```

### 6.2 Updated `hackathons` Collection Rules

```javascript
match /hackathons/{hackathonId} {
  // All authenticated users can read published/active hackathons
  allow read: if request.auth != null
              && (resource.data.isDeleted == false)
              && (resource.data.status in ['published', 'ongoing', 'completed']);

  // Admins can read all hackathons including drafts and deleted
  allow read: if request.auth != null && request.auth.token.admin == true;

  // Only admins can create, update, or delete
  allow create: if request.auth != null
                && request.auth.token.admin == true
                && request.resource.data.createdByAdminId == request.auth.uid;

  allow update: if request.auth != null
                && request.auth.token.admin == true;

  allow delete: if request.auth != null
                && request.auth.token.admin == true
                && request.auth.token.role == 'superadmin';

  // Regular users can still update only their own registration fields
  allow update: if request.auth != null
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['registeredTeamIds', 'registeredIndividualIds']);
}
```

### 6.3 Updated `users` Collection Rules

```javascript
match /users/{userId} {
  // Users can read any profile (unchanged)
  allow read: if request.auth != null;

  // Users can write their own profile, but cannot set isAdmin = true
  allow write: if request.auth != null
               && request.auth.uid == userId
               && request.resource.data.isAdmin == false;

  // Admins can read and update any user document
  allow read, update: if request.auth != null
                      && request.auth.token.admin == true;
}
```

---

## 7. Admin Dashboard

The Admin Dashboard is the first screen shown after a successful admin login. It displays real-time statistics and provides quick navigation to key admin functions.

### 7.1 Dashboard Screen Structure

**File**: `lib/ui/admin/screens/admin_dashboard_screen.dart`

**Layout**:
```
AdminDashboardScreen
├── AppBar
│   ├── Title: "CodeClub Admin"
│   └── Actions: [Logout IconButton, Admin name display]
│
├── Body (SingleChildScrollView)
│   ├── Welcome Card
│   │   └── "Welcome back, {adminName}" + current date
│   │
│   ├── Stats Grid (2-column GridView)
│   │   ├── StatCard: Total Users
│   │   ├── StatCard: Total Teams
│   │   ├── StatCard: Active Hackathons
│   │   └── StatCard: Total Registrations
│   │
│   ├── Section Header: "Hackathon Management"
│   │
│   ├── Quick Action Buttons (Row)
│   │   ├── Button: "+ Create Hackathon"  → navigates to Create screen
│   │   └── Button: "View All"            → navigates to Hackathon List screen
│   │
│   └── Recent Hackathons List (last 5)
│       └── ListView of HackathonListTile widgets
│
└── FloatingActionButton: "+ New Hackathon"
```

### 7.2 StatCard Widget

**File**: `lib/ui/admin/widgets/stat_card.dart`

Each stat card shows:
- An icon (e.g., people icon for users, trophy icon for hackathons)
- A real-time number (use `StreamBuilder` connected to the relevant count stream)
- A label
- A subtle background color per category

### 7.3 Dashboard Data Flow

```
AdminDashboardScreen mounts
        ↓
AdminProvider.loadDashboardStats() is called
        ↓
AdminService.getDashboardStats() fetches counts from Firestore
        ↓
AdminProvider notifies listeners with AdminDashboardStats
        ↓
StatCard widgets rebuild with new numbers
```

For real-time updates, individual stat cards should use `StreamBuilder` widgets connected to the count streams (`getTotalUsersStream`, `getActiveHackathonsStream`, etc.) so numbers update automatically without manual refresh.

---

## 8. Hackathon CRUD Module

### 8.1 Hackathon List Screen

**File**: `lib/ui/admin/screens/admin_hackathon_list_screen.dart`

**Features**:
- Displays all hackathons including drafts (admins see everything)
- Filter tabs: All | Draft | Published | Ongoing | Completed | Cancelled
- Search bar to filter by title
- Each list item shows: title, status badge, start date, registration count
- Swipe-to-delete gesture for quick soft-delete
- Tap to view detail / edit

**List Item (HackathonAdminTile)**:
```
HackathonAdminTile
├── Leading: Hackathon banner thumbnail (or placeholder icon)
├── Title: hackathon.title
├── Subtitle: startDate → endDate | {registeredTeamIds.length} teams
├── Trailing: StatusBadge widget + PopupMenuButton
│             PopupMenuButton options:
│               - Edit
│               - Toggle Status (publish/unpublish)
│               - Delete
└── onTap → Navigate to HackathonDetailAdminScreen
```

### 8.2 Create Hackathon Screen

**File**: `lib/ui/admin/screens/admin_hackathon_create_screen.dart`

This screen contains a multi-section form. Use a `Form` widget with a `GlobalKey<FormState>` for validation.

**Form Sections and Fields**:

**Section 1 — Basic Info**
- Title (TextFormField, required)
- Description (TextFormField, multiline, required)
- Status (DropdownButtonFormField: draft / published)
- Tags (multi-select chip input, optional)

**Section 2 — Dates & Venue**
- Start Date + Time (DateTimePicker, required)
- End Date + Time (DateTimePicker, required, must be after start date)
- Registration Deadline (DateTimePicker, required, must be before start date)
- Venue (TextFormField, required)
- Website URL (TextFormField, optional, URL validation)

**Section 3 — Team Settings**
- Minimum Team Size (NumberField, required, default: 2)
- Maximum Team Size (NumberField, required, default: 4, must be ≥ min)

**Section 4 — Prizes**
- Dynamic list of prize text fields
- "Add Prize" button adds a new field
- Each field has a remove (×) button
- At least 1 prize required

**Section 5 — Rules**
- Dynamic list of rule text fields
- "Add Rule" button adds a new field
- Each field has a remove (×) button
- Optional

**Section 6 — Banner Image**
- Image picker (from gallery or camera)
- Shows preview of selected image
- If no image selected, shows a placeholder with a dashed border

**Submit Button**:
- Label: "Create Hackathon"
- Shows loading indicator during upload + Firestore write
- On success: navigate back to list with success SnackBar
- On failure: show error SnackBar with message

**Validation Rules**:

| Field | Rule |
|---|---|
| Title | Not empty, max 100 characters |
| Description | Not empty, max 1000 characters |
| End Date | Must be after Start Date |
| Registration Deadline | Must be before Start Date |
| Max Team Size | Must be ≥ Min Team Size |
| Website | If provided, must be a valid URL |

### 8.3 Edit Hackathon Screen

**File**: `lib/ui/admin/screens/admin_hackathon_edit_screen.dart`

This screen is identical in structure to the Create screen but is pre-populated with the existing hackathon's data. The submit button label changes to "Save Changes".

**Key differences from Create**:
- Screen receives a `HackathonModel` (or `hackathonId`) as a route argument
- On mount, all form fields are pre-filled from the existing model
- Existing banner image is shown; admin can replace it or keep it
- If admin uploads a new image, the old one is deleted from Storage before uploading the new one
- `updateHackathon()` is called instead of `createHackathon()`

### 8.4 Hackathon Detail Screen (Admin View)

**File**: `lib/ui/admin/screens/admin_hackathon_detail_screen.dart`

A read-only summary screen for admins that shows:
- Full hackathon details
- Status badge and toggle button
- Registration stats: X teams registered, Y individuals registered
- List of registered teams (expandable)
- List of registered individuals (expandable)
- "Edit" button → navigates to Edit screen
- "Delete" button → shows confirmation dialog before deleting

### 8.5 Delete Confirmation Dialog

Before any delete action, show a confirmation dialog:

```
Title: "Delete Hackathon?"
Body: "This will hide '{hackathonTitle}' from all students.
       Registered teams will not be affected.
       This action can be reviewed by a superadmin."
Actions:
  - "Cancel" button
  - "Delete" button (red/destructive styling)
```

For permanent delete (superadmin only), show a second, stronger warning:

```
Title: "Permanently Delete?"
Body: "This CANNOT be undone. All data for this hackathon
       will be lost permanently. Type the hackathon title to confirm."
Actions:
  - Text input for confirmation
  - "Permanently Delete" button (enabled only when input matches title)
  - "Cancel" button
```

---

## 9. State Management — AdminProvider

**File**: `lib/providers/admin_provider.dart`

Create a new `ChangeNotifier` provider specifically for admin state. This keeps admin state completely separate from the existing student-facing providers.

### 9.1 State Variables

```
AdminProvider manages:
  ├── AdminModel? _currentAdmin         — logged-in admin data
  ├── AdminDashboardStats? _dashStats   — dashboard counts
  ├── List<HackathonModel> _hackathons  — all hackathons for admin
  ├── bool _isLoading                   — global loading indicator
  ├── bool _isSubmitting                — form submission in progress
  ├── String? _errorMessage             — last error message
  └── HackathonStatus _filterStatus     — current list filter
```

### 9.2 Key Methods

```
// Authentication
Future<void> signInAdmin(String email, String password)
Future<void> signOutAdmin()
bool get isAuthenticated → _currentAdmin != null

// Dashboard
Future<void> loadDashboardStats()
AdminDashboardStats? get dashStats

// Hackathon Management
Future<void> loadAllHackathons()
Future<void> createHackathon(HackathonModel model, File? bannerImage)
Future<void> updateHackathon(String id, Map<String, dynamic> data, File? newBanner)
Future<void> deleteHackathon(String id)  // soft delete
Future<void> toggleStatus(String id, HackathonStatus status)

// Filtering
void setFilter(HackathonStatus? status)
List<HackathonModel> get filteredHackathons
```

### 9.3 Registering the Provider

Add `AdminProvider` to `MultiProvider` in `lib/main.dart`:

```dart
// Add alongside existing providers
ChangeNotifierProvider<AdminProvider>(
  create: (_) => AdminProvider(),
),
```

---

## 10. Navigation & Routing

### 10.1 Admin Route Names

Define these constants in `lib/core/routes/app_routes.dart` (or equivalent):

```dart
static const String adminLogin     = '/admin/login';
static const String adminDashboard = '/admin/dashboard';
static const String adminHackathonList   = '/admin/hackathons';
static const String adminHackathonCreate = '/admin/hackathons/create';
static const String adminHackathonEdit   = '/admin/hackathons/edit';
static const String adminHackathonDetail = '/admin/hackathons/detail';
```

### 10.2 Route Guard (Admin Auth Guard)

Before rendering any admin screen (except the login screen), check that the current user is an authenticated admin. If not, redirect to the admin login screen.

This guard should be implemented as a wrapper widget or in the `onGenerateRoute` handler:

```
AdminAuthGuard logic:
  IF FirebaseAuth.currentUser == null → redirect to /admin/login
  IF ID token does NOT contain admin claim → redirect to /admin/login
  IF admins/{uid}.isActive == false → redirect to /admin/login with error
  ELSE → render the requested admin screen
```

### 10.3 Accessing the Admin Panel

The admin panel entry point should NOT be a visible menu item for regular students. Recommended approaches:

- On the Settings screen, add a small hidden tap target (e.g., tapping the app version text 5 times quickly) that navigates to `/admin/login`
- Or: On web platform only, support direct URL navigation to `/admin/login`

### 10.4 Admin Bottom Navigation

The admin area should have its own `BottomNavigationBar` (or `NavigationRail` on wider screens) separate from the student navigation:

```
Admin Navigation Bar:
  Tab 1: Dashboard (home icon)
  Tab 2: Hackathons (trophy/event icon)
  Tab 3: Settings / Profile (person icon)
```

---

## 11. File & Folder Structure

All admin-related code lives under `lib/ui/admin/` and `lib/data/` (service + model additions). This keeps admin code isolated and easy to find.

```
lib/
├── data/
│   ├── models/
│   │   ├── admin_model.dart              [NEW]
│   │   └── hackathon_model.dart          [UPDATED — add status, isDeleted, etc.]
│   └── services/
│       └── admin_service.dart            [NEW]
│
├── providers/
│   └── admin_provider.dart               [NEW]
│
└── ui/
    └── admin/
        ├── screens/
        │   ├── admin_login_screen.dart              [NEW]
        │   ├── admin_dashboard_screen.dart          [NEW]
        │   ├── admin_hackathon_list_screen.dart     [NEW]
        │   ├── admin_hackathon_create_screen.dart   [NEW]
        │   ├── admin_hackathon_edit_screen.dart     [NEW]
        │   └── admin_hackathon_detail_screen.dart   [NEW]
        └── widgets/
            ├── stat_card.dart                       [NEW]
            ├── hackathon_admin_tile.dart            [NEW]
            ├── status_badge.dart                    [NEW]
            ├── admin_form_section.dart              [NEW — reusable form section wrapper]
            ├── dynamic_list_field.dart              [NEW — for prizes/rules lists]
            └── admin_auth_guard.dart                [NEW]
```

---

## 12. New Firestore Indexes Required

Add these indexes in the Firebase Console under **Firestore → Indexes**:

**Collection: `hackathons`** (new indexes for admin queries)

| Fields | Order | Purpose |
|---|---|---|
| `isDeleted` (ASC), `createdAt` (DESC) | Composite | Admin list — exclude deleted |
| `status` (ASC), `createdAt` (DESC) | Composite | Filter hackathons by status |
| `isDeleted` (ASC), `status` (ASC), `startDate` (DESC) | Composite | Combined admin filter |

**Collection: `admins`** (new collection, simple reads — no composite index needed)

---

## 13. Implementation Checklist

Use this checklist to track development progress.

### Phase 1 — Foundation
- [ ] Add `admins` collection to Firestore and create the first admin document manually
- [ ] Set Firebase Custom Claim (`admin: true`) on the admin UID via Firebase Admin SDK
- [ ] Add `isAdmin: false` field to all existing `users` documents (batch update)
- [ ] Add `status`, `isDeleted`, `createdByAdminId` fields to all existing `hackathons` documents
- [ ] Create `AdminModel` data class with `fromFirestore` and `toFirestore`
- [ ] Update `HackathonModel` with new fields and `HackathonStatus` enum
- [ ] Update Firebase Security Rules for `hackathons`, `users`, and add `admins` rules

### Phase 2 — Authentication
- [ ] Create `AdminService` with `signInAdmin`, `signOutAdmin`, `isCurrentUserAdmin`
- [ ] Create `AdminProvider` with auth state management
- [ ] Build `AdminLoginScreen` UI with form and validation
- [ ] Implement `AdminAuthGuard` widget
- [ ] Register admin routes in the app router
- [ ] Add hidden navigation entry point (e.g., version tap trigger)
- [ ] Test: login with admin account → check claim → reach dashboard
- [ ] Test: login with student account → blocked and signed out

### Phase 3 — Dashboard
- [ ] Add dashboard stats methods to `AdminService`
- [ ] Add `loadDashboardStats` to `AdminProvider`
- [ ] Build `StatCard` widget
- [ ] Build `AdminDashboardScreen` with stats grid and recent hackathons list
- [ ] Connect real-time streams to stat cards

### Phase 4 — Hackathon CRUD
- [ ] Add `createHackathon`, `getAllHackathons`, `updateHackathon`, `softDeleteHackathon` to `AdminService`
- [ ] Add image upload method to `AdminService`
- [ ] Add CRUD methods to `AdminProvider`
- [ ] Build `AdminHackathonListScreen` with filter tabs
- [ ] Build `HackathonAdminTile` widget with status badge and popup menu
- [ ] Build `AdminHackathonCreateScreen` with full form and validation
- [ ] Build `AdminHackathonEditScreen` (reuse Create form, pre-populate data)
- [ ] Build `AdminHackathonDetailScreen` with registrations view
- [ ] Implement delete confirmation dialogs (soft-delete and permanent)
- [ ] Test: Create → verify appears in Firestore and student view
- [ ] Test: Update → verify changes reflect immediately
- [ ] Test: Soft-delete → verify hidden from students, visible to admin
- [ ] Test: Toggle status draft → published → verify student visibility

### Phase 5 — Security & Polish
- [ ] Run full security rules test suite (Firebase Emulator)
- [ ] Verify student accounts cannot write to hackathons (except registration)
- [ ] Add loading states and error handling throughout
- [ ] Add success/failure SnackBars for all CRUD operations
- [ ] Add empty states for lists with no hackathons
- [ ] Add pull-to-refresh on the hackathon list
- [ ] Add Firestore composite indexes for all new admin queries

---

## Appendix A — AdminDashboardStats Data Class

```
AdminDashboardStats {
  final int totalUsers
  final int totalTeams
  final int totalHackathons
  final int activeHackathons
  final int totalRegisteredTeams
  final int totalRegisteredIndividuals

  AdminDashboardStats copyWith({...})
}
```

---

## Appendix B — HackathonStatus Extension

```
extension HackathonStatusExtension on HackathonStatus {
  String get label {
    switch (this) {
      case HackathonStatus.draft:      return 'Draft';
      case HackathonStatus.published:  return 'Published';
      case HackathonStatus.ongoing:    return 'Ongoing';
      case HackathonStatus.completed:  return 'Completed';
      case HackathonStatus.cancelled:  return 'Cancelled';
    }
  }

  Color get badgeColor {
    switch (this) {
      case HackathonStatus.draft:      return Colors.grey;
      case HackathonStatus.published:  return Colors.green;
      case HackathonStatus.ongoing:    return Colors.blue;
      case HackathonStatus.completed:  return Colors.purple;
      case HackathonStatus.cancelled:  return Colors.red;
    }
  }

  bool get isVisibleToStudents {
    return this == HackathonStatus.published || this == HackathonStatus.ongoing;
  }
}
```

---

*Document Last Updated: March 2026*
*Version: 1.0 — CodeClub Admin Module*
