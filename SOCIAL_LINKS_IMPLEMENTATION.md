# LinkedIn and GitHub Social Links Implementation

## Overview
Added optional LinkedIn and GitHub profile links to the CodeClub application. Users can now add these links during signup, profile setup, and can edit them anytime in their profile.

## Changes Made

### 1. **User Model** (`lib/data/models/user_model.dart`)
- Added two new optional fields to `UserModel`:
  - `String? linkedInUrl` - LinkedIn profile URL
  - `String? githubUrl` - GitHub profile URL
- Updated `UserModel.empty()` factory constructor to include null values for these fields
- Updated `UserModel.fromFirestore()` to read these fields from Firestore
- Updated `toFirestore()` method to save these fields to Firestore
- Updated `copyWith()` method to allow updating these fields

### 2. **Signup Screen** (`lib/ui/screens/auth/signup_screen.dart`)
- Added two new `TextEditingController` instances:
  - `_linkedInController` - for LinkedIn profile URL input
  - `_githubController` - for GitHub profile URL input
- Added optional social links section in the signup form
- Displays helper text: "Add your LinkedIn and GitHub profiles to help teammates find you"
- Fields appear after the password confirmation field
- Users can leave these fields empty (completely optional)

### 3. **Profile Setup Screen** (`lib/ui/screens/profile/profile_setup_screen.dart`)
- Added two new `TextEditingController` instances for social links
- Added social links section in the final step (Bio Step) of the profile setup
- Integrated LinkedIn and GitHub URL fields with the profile completion flow
- Updated `_handleSaveProfile()` to save these optional links (converts empty strings to null)

### 4. **Edit Profile Screen** (`lib/ui/screens/profile/edit_profile_screen.dart`)
- Added two new `TextEditingController` instances
- Initialize controllers with existing social links data from user profile
- Added a "Social Links" section below the bio field
- Users can add, update, or remove social links from their existing profile
- Updated `_handleSave()` to properly handle these fields

### 5. **Profile Screen** (`lib/ui/screens/profile/profile_screen.dart`)
- Added conditional display of "Social Profiles" card
- Only shows the card if user has at least one social link added
- Created new `_buildSocialLinkRow()` widget method to display individual social links
- Social links display with:
  - Platform icon (LinkedIn icon for LinkedIn, code icon for GitHub)
  - Platform name and clickable URL
  - Visual indication that it's clickable (open in new icon)
  - Proper formatting with URL domain displayed (without https://)

## User Flow

### During Signup
1. User creates account with email and password
2. Optional: User adds LinkedIn and/or GitHub profile URLs
3. User is directed to profile setup

### During Profile Setup
1. User completes basic information (Step 1)
2. User selects role and skills (Step 2)
3. User adds bio and optionally adds LinkedIn/GitHub links (Step 3)
4. Profile is saved with all information

### In Profile View
1. User can see their complete profile
2. If social links are added, they appear in a "Social Profiles" card
3. User can click "Edit Profile" to modify social links anytime

### Editing Profile
1. User navigates to Edit Profile
2. Can update any field including social links
3. Can remove links by clearing the fields
4. Changes are saved to Firestore

## Data Storage

### Firestore Structure
```firestore
/users/{userId} {
  // ... existing fields ...
  linkedInUrl: "https://linkedin.com/in/username" (optional, null if not provided)
  githubUrl: "https://github.com/username" (optional, null if not provided)
}
```

## Validation
- Both social link fields are **completely optional**
- No URL validation is performed (users can enter any URL)
- Empty fields are stored as `null` in Firestore
- On edit, empty fields are cleared from the database

## UI/UX Considerations
- Social links section appears after bio in profile setup (final step)
- Helps with profile completion flow
- In profile view, social links card only appears if links exist
- Icons indicate the type of link (work for LinkedIn, code for GitHub)
- Clickable/tappable appearance with visual feedback
- Responsive design matches existing profile UI

## Future Enhancements
- Add URL validation using regex
- Add direct launch capability for social profile links (using url_launcher package)
- Add social profile images/thumbnails
- Add connection status indicators
- Allow users to verify/authenticate social accounts

## Testing Recommendations
1. Create account without social links
2. Create account with only LinkedIn link
3. Create account with only GitHub link
4. Create account with both links
5. Edit profile to add/remove/update links
6. Verify Firestore data is correctly saved
7. Test profile view with different combinations of links
8. Test on both Android and iOS platforms

