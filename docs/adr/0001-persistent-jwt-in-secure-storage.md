# The JWT persists in the device's secure storage

Unlike the web client, which drops the token when the tab closes (front ADR-0001), the phone app keeps it in `FlutterSecureStorage` (Keychain on iOS, Keystore on Android) across restarts. A phone is personal and locked, whereas a browser is easily shared; the OS-backed secure store is safe enough, and asking for the password at every app launch would be unacceptable on mobile.

Do not align this with the web client (or vice versa) without revisiting both decisions.
