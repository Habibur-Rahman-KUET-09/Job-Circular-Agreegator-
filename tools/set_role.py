"""Grant an app role by setting a Firebase Auth custom claim.

Usage:
    python tools/set_role.py <email> <admin|moderator|recruiter|user> [company]

The user must already have signed up in the app. Needs a service-account key:
set GOOGLE_APPLICATION_CREDENTIALS, or put firebase-credentials.json in the
repo root. The user has to sign out and back in (or reopen the app) for the
new role to take effect.
"""

import os
import sys

import firebase_admin
from firebase_admin import auth, credentials, firestore

ROLES = ("admin", "moderator", "recruiter", "user")


def main() -> int:
    if len(sys.argv) not in (3, 4) or sys.argv[2] not in ROLES:
        print(__doc__)
        return 2
    email, role = sys.argv[1], sys.argv[2]
    company = sys.argv[3] if len(sys.argv) == 4 else None
    if role == "recruiter" and not company:
        print("A recruiter needs a company name.")
        return 2

    key_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or os.path.join(
        os.path.dirname(__file__), "..", "firebase-credentials.json"
    )
    firebase_admin.initialize_app(credentials.Certificate(key_path))

    try:
        user = auth.get_user_by_email(email)
    except auth.UserNotFoundError:
        print(f"No account for {email}. Sign up in the app first.")
        return 1
    except auth.ConfigurationNotFoundError:
        print("Firebase Authentication is not enabled. Firebase Console -> "
              "Authentication -> Get started, then enable Email/Password.")
        return 1

    claims = {"role": role}
    if company:
        claims["company"] = company
    auth.set_custom_user_claims(user.uid, claims)
    # Mirrored for Cloud Functions that read the role from the user document.
    firestore.client().collection("users").document(user.uid).set(claims, merge=True)

    print(f"{email} is now {role}" + (f" at {company}" if company else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
