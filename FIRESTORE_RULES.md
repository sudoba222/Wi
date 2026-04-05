# Firestore Security Rules

Rules are configured in Firebase Console under:
work-interconnected > Firestore Database > Rules

## Current Rules
- Only authenticated users can read/write data
- Users can only edit their own profile
- Users can only delete their own posts and comments
- Comments follow the same rules as posts