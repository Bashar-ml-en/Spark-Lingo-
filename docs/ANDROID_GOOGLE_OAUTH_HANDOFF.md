# Android launch — Google OAuth setup handoff

Status: PREPARED 2026-08-28. Keystore + SDK done on this machine.
Package id: com.sparklingo.spark_lingo
Upload keystore: android/upload-keystore.jks (password in android/key.properties — NEVER commit, already git-ignored)

## Upload-key fingerprints (from the keystore we generated)
- SHA1:   8F:3C:FE:64:84:E5:E3:DF:8D:95:45:B1:B7:99:E3:05:09:A7:F6:CD
- SHA256: 07:CC:FE:2A:EE:8A:F2:54:7B:8D:26:B4:E8:94:F4:AF:AA:E4:A3:9C:AF:7A:57:14:E8:0C:3D:B9:C2:B7:4C:D9

> NOTE: Play App Signing (recommended) re-signs your AAB with a Play
> app-signing key. AFTER enrolling in Play App Signing, the fingerprint
> that Google sign-in needs is the PLAY APP SIGNING key's SHA-1, shown in
> Play Console -> Setup -> App signing. Add BOTH the upload-key SHA-1
> (above) and the Play app-signing SHA-1 to the OAuth client.

## Steps for you (human) in Google Cloud Console
Project: "Spark Lingo" (existing)

1. APIs & Services -> Credentials -> CREATE CREDENTIALS -> OAuth client ID.
2. Application type: ANDROID.
3. Package name: com.sparklingo.spark_lingo
4. SHA-1 certificate fingerprint: paste the upload-key SHA-1 above.
   (Add a second Android client later with the Play app-signing SHA-1.)
5. OAuth consent screen: confirm Spark Lingo is listed; keep it in
   Testing until launch day, and add team emails as test users so QA
   logins don't hit "Access blocked".

## Steps for me once you tell me it's done
- Configure Supabase project dioisitgohusggmwowft with the same Google
  client id/secret (already done for the web client — Android reuses the
  SAME client id/secret; Google validates the caller by package+SHA-1).
- Build a signed release AAB and verify Google sign-in on it.

## Why web login works but Android would not (yet)
Google only accepts an OAuth request from an Android app whose package
name + signing SHA-1 matches an ANDROID-type credential. The existing
credential is WEB-type (authorized origins/redirect URIs), so a Play
build without its own Android credential fails with
`developer_error` / "10: " at sign-in time.
