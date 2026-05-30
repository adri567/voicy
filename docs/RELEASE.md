# Voicy — Release & Auto-Update

Voicy ships **outside the Mac App Store** (it needs Accessibility, event taps and
clipboard paste). Updates run through **Sparkle 2** with its own EdDSA signing;
DMGs are hosted on **GitHub Releases**, and the update feed lives at
`https://voicy.pro/appcast.xml`.

Bundle ID: `pro.voicy.app`. Team (local signing): `D6GUJ478PV` (free Personal team).

---

## One-time setup

### 1. Generate the Sparkle EdDSA key pair (once, ever)
Sparkle signs every update with an EdDSA private key kept in your login keychain.
Run the `generate_keys` tool that ships inside the resolved Sparkle package:

```
! find ~/Library/Developer/Xcode/DerivedData -path '*/artifacts/sparkle/Sparkle/bin/generate_keys' -exec {} \;
```

It prints a **public key** (base64). Put it into the build setting
`INFOPLIST_KEY_SUPublicEDKey` for the Voicy target (currently the placeholder
`REPLACE_WITH_EDDSA_PUBLIC_KEY` in `project.pbxproj`, Debug **and** Release).

> The **private** key never leaves your keychain and is never committed. Back it
> up via `generate_keys -x private-key.pem` and store it somewhere safe — losing
> it means you can no longer ship updates your installed users will accept.

### 2. (Paid account only) Notarization profile
Once enrolled in the Apple Developer Program, store notarytool credentials once:

```
! xcrun notarytool store-credentials "VoicyNotary" \
    --apple-id "you@example.com" --team-id "<TEAMID>" --password "<app-specific-password>"
```

Then export before releasing: `export NOTARY_PROFILE=VoicyNotary` and
`export DEVELOPER_ID="Developer ID Application: <Name> (<TEAMID>)"`.

---

## Cutting a release

1. Bump `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`) on the Voicy target.
2. Run the pipeline:

   ```
   ! ./scripts/release.sh
   ```

   - **Without** `DEVELOPER_ID`/`NOTARY_PROFILE`: archives, builds an unsigned/
     locally-signed DMG into `release/`, and writes an **EdDSA-signed**
     `appcast.xml`. Use this to exercise the full Sparkle update flow locally.
   - **With** both env vars set: additionally Developer-ID-signs (hardened
     runtime), notarizes, and staples the DMG.

3. Create a GitHub release tagged `v<version>` and upload `release/Voicy-<version>.dmg`.
   The appcast's enclosure URL points at
   `https://github.com/adri567/voicy/releases/download/v<version>/` — adjust the
   `--download-url-prefix` in `release.sh` if the repo path differs.
4. Deploy the regenerated `appcast.xml` to `https://voicy.pro/appcast.xml`.

---

## Verifying notarization readiness

Project is already configured for notarization: `ENABLE_HARDENED_RUNTIME = YES`,
`ENABLE_APP_SANDBOX = NO`, minimal entitlements (`audio-input`, `network.client`).
After a signed build, verify:

```
! codesign --verify --strict --verbose=2 build/Voicy.xcarchive/Products/Applications/Voicy.app
! spctl -a -t exec -vv build/Voicy.xcarchive/Products/Applications/Voicy.app   # after notarization
```

A notarized + stapled DMG should report `source=Notarized Developer ID`.

---

## How the app finds updates

- `SUFeedURL` → `https://voicy.pro/appcast.xml`
- `SUPublicEDKey` → the public key from step 1
- `SUEnableAutomaticChecks = YES`, `SUScheduledCheckInterval = 86400` (daily)

`SparkleUpdateService` constructs `SPUStandardUpdaterController(startingUpdater: true)`,
which starts those scheduled background checks. Settings → About → **Check for
updates** triggers a user-initiated check; **Release notes** opens the GitHub
releases page.

---

## Parallel non-code tasks
- Create the GitHub repo + releases (DMG host).
- Deploy `appcast.xml` to `voicy.pro`.
- Enroll in the Apple Developer Program (only needed for codesign/notarize).
- Pick a licensing provider (Paddle / Lemon Squeezy) → separate licensing chunk.
