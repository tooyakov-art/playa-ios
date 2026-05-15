# Playa — App Store Submission Walkthrough

This is a step-by-step for shipping V1.0 of Playa to App Store Connect / TestFlight from a Windows machine. The build runs on GitHub Actions macOS runners. No local Mac required.

Total active time: ~2.5 hours setup + 30 min per submission. Apple review wait: 1–3 days.

---

## 0. One-time prerequisites

- **Apple Developer Program** membership (Team `F8LA8PC4U6`)
- **GitHub** account with repo admin rights to `tooyakov-art/playa-ios`
- **Supabase** Dashboard access to project `yteqnagkxbbaqjdgoqeu`

---

## 1. Apply the SQL migration

1. Open Supabase Dashboard → SQL Editor on project `yteqnagkxbbaqjdgoqeu`.
2. Paste the contents of `supabase/001_delete_own_account.sql`.
3. Click **Run**. Verify with:
   ```sql
   select proname from pg_proc where proname = 'delete_own_account';
   ```

---

## 2. Register the Bundle ID

1. Apple Developer Portal → Certificates, Identifiers & Profiles → **Identifiers** → **+**
2. App IDs → App → Continue
3. Description: `Playa`, Bundle ID: **explicit** `com.playastudio.app`
4. Capabilities — enable **Sign in with Apple**
5. Continue → Register

---

## 3. Create the App Store Connect entry

1. App Store Connect → **My Apps** → **+** → New App
2. Platform: iOS, Name: **Playa**, Primary Language: Russian, Bundle ID: `com.playastudio.app`, SKU: `playa-ios-1`
3. User Access: Full Access
4. App Information → Category: **Social Networking**
5. Save

---

## 4. Create distribution certificate

1. Apple Developer Portal → Certificates → **+**
2. Type: **Apple Distribution**
3. Generate a CSR via Keychain (or use existing X5 cert if same team)
4. Download `.cer`, double-click to install in Keychain
5. Right-click in Keychain → Export → **.p12** with a strong password
6. Encode to base64:
   ```bash
   base64 -w 0 dist.p12 > dist.p12.b64
   ```

---

## 5. Create provisioning profile

1. Apple Developer Portal → Profiles → **+**
2. Distribution → **App Store Connect**
3. App ID: `com.playastudio.app`
4. Certificate: the Distribution cert from step 4
5. Profile Name: **Playa App Store Profile** (must match `ExportOptions.plist`)
6. Generate → Download `.mobileprovision`
7. Encode to base64:
   ```bash
   base64 -w 0 Playa_App_Store_Profile.mobileprovision > profile.b64
   ```

---

## 6. Create App Store Connect API key

1. App Store Connect → Users and Access → **Keys** tab → **+**
2. Name: `Playa CI`, Access: **Developer**
3. Download `.p8` (one-time only)
4. Note the **Key ID** and **Issuer ID**
5. Encode the .p8 to base64:
   ```bash
   base64 -w 0 AuthKey_XXXXXXXXXX.p8 > key.b64
   ```

---

## 7. Configure GitHub Secrets

Repo → Settings → Secrets and variables → Actions → New repository secret:

| Name | Value |
|---|---|
| `IOS_DIST_CERT_P12_BASE64` | contents of `dist.p12.b64` |
| `IOS_DIST_CERT_PASSWORD` | the .p12 password from step 4 |
| `IOS_PROVISIONING_PROFILE_BASE64` | contents of `profile.b64` |
| `IOS_KEYCHAIN_PASSWORD` | any random string |
| `ASC_API_KEY_BASE64` | contents of `key.b64` |
| `ASC_API_KEY_ID` | the Key ID from step 6 |
| `ASC_API_ISSUER_ID` | the Issuer ID from step 6 |

---

## 8. Trigger the build

```bash
git push origin main
```

Or run `iOS build & TestFlight upload` workflow manually from the Actions tab.

The build takes ~12–18 minutes. On success, the IPA appears in **TestFlight → Builds** within a few more minutes (after Apple processes the upload).

---

## 9. Submit for review

1. App Store Connect → Playa → App Store → **+ Version**
2. Version: `1.0.0`
3. Fill in:
   - **Description** — what the app does in Russian + English
   - **Keywords** — events, tickets, social, концерты, билеты
   - **Support URL** — `https://playahub.app/support`
   - **Marketing URL** — `https://playahub.app`
   - **Privacy Policy URL** — `https://playahub.app/privacy`
4. **Screenshots** — 6.7" iPhone (required), 5.5" iPhone (legacy required), iPad 12.9" (if iPad supported)
5. **App Review Information**:
   - Demo account: just use the **"Зайти как гость"** button — no credentials needed
   - Notes for review:
     ```
     Tap "Зайти как гость" on the login screen to access the app without
     Apple Sign-In. The app shows a curated event feed; ticket purchase and
     account deletion (RPC delete_own_account) are wired but UGC features
     (posts, chats) are disabled in v1.0.
     ```
6. **Build** — pick the TestFlight build that arrived from step 8
7. **Submit for Review**

---

## 10. After approval

- Tag the release: `git tag v1.0.0 && git push --tags`
- Move to V2 branch — Feed, Posts, Comments, ReportBlockMenu (see README roadmap)

---

## Common gotchas

| Symptom | Cause / fix |
|---|---|
| `Code signing failed` in archive step | Profile name in `ExportOptions.plist` must match the actual profile **Name** (not UUID), and the workflow's "Resolve provisioning profile name" step has to print it correctly. |
| `No matching provisioning profile found` | Profile expired or doesn't include the cert from step 4. Regenerate. |
| Build uploads but never appears in TestFlight | Check email — Apple often sends "Invalid Binary" reasons (missing Privacy Manifest entries, ITSAppUsesNonExemptEncryption missing, etc.) |
| `Apple Sign-In` button hangs in TestFlight | Make sure capability is enabled on the App ID **and** included in the provisioning profile. |
| `delete_own_account` returns 404 | SQL migration not applied. See step 1. |
## Social MVP update

Before submitting this build, apply these migrations in Supabase:

- Web repo: `supabase/migrations/001_extend.sql`
- Web repo: `supabase/migrations/20260424_social_onboarding.sql`
- iOS repo: `supabase/002_content_reports.sql`

The active GitHub Actions workflow is `.github/workflows/ios-build.yml` in the iOS repository. UGC is enabled in v1.0: posts, comments, direct chats, and event chats. Review notes should say that users can report posts and delete their account from Profile.
