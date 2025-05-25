import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use clientId instead of serverClientId for web
    clientId:
        '894403809910-54q1iesdkppkg3f2m438bsb01dp8p0fa.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Send email verification link
  Future<void> sendEmailVerificationLink() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is logged in.");
      }
      if (user.emailVerified) {
        throw Exception("Email is already verified.");
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty ||
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception("Invalid email address.");
      }
      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters long.");
      }

      // Create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await userCredential.user?.sendEmailVerification();

      // Store user data in Realtime Database
      final DatabaseReference userRef = _database.ref(
        "users/${userCredential.user!.uid}",
      );
      try {
        await userRef.set({
          "email": email.trim(),
          "createdAt": ServerValue.timestamp,
          "role": "user",
          "membershipPlan": "false",
          "membershipExpiry": "none",
          "profileImage":
              "https://res.cloudinary.com/dnedosgc6/image/upload/v1747375531/ivsknjzcnwu5emninkm2.png",
        });
      } catch (e) {
        // Rollback user creation if database write fails
        await userCredential.user?.delete();
        throw Exception("Failed to store user data: $e");
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  // Log in with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await userCredential.user?.reload();
      if (!userCredential.user!.emailVerified) {
        throw Exception("Email is not verified. Please verify your email.");
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google Sign-In cancelled by user.");
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check email verification (optional, align with email/password login)
      await userCredential.user?.reload();
      if (userCredential.user!.email != null &&
          !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        throw Exception("Email is not verified. Verification link sent.");
      }

      // Store or update data in Firebase Realtime Database
      String uid = userCredential.user!.uid;
      DatabaseReference userRef = _database.ref("users/$uid");
      DatabaseReference sessionRef = _database.ref("users/$uid/session");
      final userSnapshot = await userRef.get();
      final sessionSnapshot = await sessionRef.get();

      // Check for existing session
      if (sessionSnapshot.exists) {
        throw Exception("You are already logged in on another device.");
      }

      // If user exists, update only session data
      if (userSnapshot.exists) {
        await sessionRef.set({
          "active": true,
          "timestamp": ServerValue.timestamp,
        });
      } else {
        // If user doesn't exist, create full profile
        await userRef.set({
          "email": userCredential.user!.email?.trim() ?? "",
          "createdAt": ServerValue.timestamp,
          "role": "user",
          "membershipPlan": "false",
          "membershipExpiry": "none",
          "profileImage":
              userCredential.user!.photoURL ??
              "https://res.cloudinary.com/dnedosgc6/image/upload/v1747375531/ivsknjzcnwu5emninkm2.png",
        });
        await sessionRef.set({
          "active": true,
          "timestamp": ServerValue.timestamp,
        });
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Google Sign-In failed: $e");
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty ||
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception("Invalid email address.");
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  // Log out with session removal
  Future<void> logout() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _database.ref("users/${user.uid}/session").remove();
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception("Failed to log out: $e");
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Handle Firebase Auth errors
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "The email address is not valid.";
      case 'user-disabled':
        return "The user account has been disabled.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'email-already-in-use':
        return "The email is already registered.";
      case 'weak-password':
        return "The password is too weak. Please choose a stronger one.";
      case 'operation-not-allowed':
        return "This operation is not allowed. Contact support.";
      case 'account-exists-with-different-credential':
        return "An account already exists with a different sign-in method.";
      default:
        return "An unknown error occurred: ${e.message ?? e.code}";
    }
  }
}
