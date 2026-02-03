# CodeClub

CodeClub is a Flutter-based application designed to help students find their perfect hackathon team. It allows users to create profiles, search for team members, and collaborate effectively.

## Features

- **Profile Setup**: Complete your profile with details like name, branch, year, skills, and bio.
- **Team Matching**: Search for team members based on skills, roles, and academic year.
- **Hackathon Management**: View upcoming, ongoing, and past hackathons.
- **Team Collaboration**: Create and manage teams, send team requests, and chat with members.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Pushkar3232/CodeClub.git
   ```

2. Navigate to the project directory:

   ```bash
   cd CodeClub
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Set up Firebase:

   - Add your Firebase configuration files (`google-services.json` for Android and `GoogleService-Info.plist` for iOS).
   - Update `firebase.json` and `firestore.rules` as needed.

5. Run the app:

   ```bash
   flutter run
   ```

## Firebase Configuration

Ensure the following Firebase services are enabled:

- Firestore Database
- Firebase Authentication
- Firebase Storage (optional for profile images)

### Firestore Rules

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /teams/{teamId} {
      allow read, write: if request.auth != null && request.auth.uid in resource.data.memberIds;
    }
    match /hackathons/{hackathonId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```
3. Make your changes and commit them:
   ```bash
   git commit -m "Add feature-name"
   ```
4. Push to your branch:
   ```bash
   git push origin feature-name
   ```
5. Create a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any inquiries, please contact:
- **Pushkar**: [pushkar@example.com](mailto:pushkar@example.com)

---

Thank you for using CodeClub! Happy hacking!
