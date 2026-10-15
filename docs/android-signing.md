# Android signing

`build.yml` builds and signs the Android release files in GitHub Actions with a key
that belongs to the environment: the **staging key** for the staging app and the
**production key** (the Play *upload* key) for the production app
([`environments.md`](environments.md)). Nothing needs to be uploaded to Google Play for
this to work. It is a per-project step, because the keys, the Play Console and the
Gradle files belong to the app, not to the template.

The snippets are adapted from the official
[Flutter Android deployment guide](https://docs.flutter.dev/deployment/android) and
[Flutter flavors guide](https://docs.flutter.dev/deployment/flavors); check them against
the guides for your Flutter version.

| Build | Signed with | Produces |
| --- | --- | --- |
| Pull request | the debug key (test build, no secret) | one APK and one App Bundle, kept 14 days |
| Push to `develop`, or manual staging run | the staging key | signed APKs and App Bundle in the draft release "Staging" |
| Push to `main`, or manual production run | the production key | signed APKs and App Bundle in the draft release `v<version>` |

Only the signing job reads the secrets. Each GitHub environment is restricted to one
branch, so a pull request or another branch can never read a key. Keeping two keys means
a leak of the staging key cannot sign a production build.

## 1. Create the two keystores (once, on your machine)

```bash
mkdir -p .signing

keytool -genkey -v -keystore .signing/production-keystore.jks -keyalg RSA \
        -storetype JKS -keysize 2048 -validity 10000 -alias <app>-upload

keytool -genkey -v -keystore .signing/staging-keystore.jks -keyalg RSA \
        -storetype JKS -keysize 2048 -validity 10000 -alias <app>-staging
```

Keep the files outside the repository, or in the folder `.signing/` of the workspace,
which Git ignores and which survives a rebuild of the dev container. Use a different
password for each key, without a backslash.

**Choose a distinctive alias** such as `<app>-upload` (your app's name), not the common
`upload` or `staging`. GitHub hides the value of every secret in its logs, so an alias
that is an everyday word blanks that word wherever it appears in the build output.

**Back up both `.jks` files and all passwords** in a password manager straight away:
the dev container's home folder is lost when the container is rebuilt, and without a key
no later build can carry the same signature. The repository ignores `*.jks`,
`*.keystore`, `android/key.*.properties` and `.signing/`; never commit them.

Print the certificate fingerprint (SHA-256) of each key. It is public information and
is used in section 4:

```bash
keytool -list -v -keystore .signing/production-keystore.jks -alias <app>-upload | grep "SHA256:"
keytool -list -v -keystore .signing/staging-keystore.jks -alias <app>-staging | grep "SHA256:"
```

## 2. Teach Gradle the flavors and the keys

Create `android/key.production.properties` and `android/key.staging.properties`
locally (both are ignored by Git; CI writes the file of its environment from that
environment's secrets):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<app>-upload
storeFile=/absolute/path/to/production-keystore.jks
```

In `android/app/build.gradle.kts`, load the files that exist, create one signing
configuration per flavor, and let each flavor fall back to the debug key when its file
is missing, so pull requests and a fresh clone still build. Keep what `flutter create`
generated (`namespace`, `defaultConfig`, ...) and add the rest:

```kotlin
import java.io.FileInputStream
import java.util.Properties

// ... plugins { ... } as generated

fun loadKeyProperties(fileName: String): Properties? {
    val file = rootProject.file(fileName)
    if (!file.exists()) return null
    return Properties().also { properties ->
        FileInputStream(file).use { properties.load(it) }
    }
}

val stagingKeyProperties = loadKeyProperties("key.staging.properties")
val productionKeyProperties = loadKeyProperties("key.production.properties")

android {
    // namespace, compileSdk, defaultConfig { applicationId = "com.yourcompany.myapp" ... }
    // as generated

    signingConfigs {
        stagingKeyProperties?.let { keys ->
            create("staging") {
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
                storeFile = keys.getProperty("storeFile")?.let { file(it) }
                storePassword = keys.getProperty("storePassword")
            }
        }
        productionKeyProperties?.let { keys ->
            create("production") {
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
                storeFile = keys.getProperty("storeFile")?.let { file(it) }
                storePassword = keys.getProperty("storePassword")
            }
        }
    }

    // The flavor names are the environment names (see environments.md). Production
    // keeps the plain application ID, because that is the ID in the stores.
    flavorDimensions += "default"
    productFlavors {
        create("staging") {
            dimension = "default"
            applicationIdSuffix = ".staging"
            signingConfig =
                signingConfigs.findByName("staging") ?: signingConfigs.getByName("debug")
        }
        create("production") {
            dimension = "default"
            signingConfig =
                signingConfigs.findByName("production") ?: signingConfigs.getByName("debug")
        }
    }
}
```

Two details that are easy to miss:

- Delete the `buildTypes { release { signingConfig = ... } }` block that `flutter create`
  generates. A signing configuration on the build type would override the flavor's one.
- With Firebase, also apply the Google services plugin
  (`id("com.google.gms.google-services")` in `plugins`) and see
  [`environments.md`](environments.md) for the per-flavor `google-services.json`.
  `build.yml` detects the plugin by itself.

After changing the Gradle file or a key, run `flutter clean`.

### Check a signed build on your machine (optional)

```bash
flutter build apk --release --flavor production --split-per-abi
flutter build appbundle --release --flavor production
"$ANDROID_HOME"/build-tools/*/apksigner verify --print-certs build/app/outputs/flutter-apk/app-*arm64-v8a*-release.apk
keytool -printcert -jarfile build/app/outputs/bundle/productionRelease/app-production-release.aab
```

The certificate must be yours, not `CN=Android Debug`.

## 3. Prepare GitHub (once)

Create two environments under **Settings → Environments → New environment** before the
first merge that builds them. An environment that GitHub creates on the fly from a
workflow run has no branch restriction.

| Environment | Deployment branches and tags |
| --- | --- |
| `staging` | selected branches and tags: `develop` only |
| `production` | selected branches and tags: `main` only (optionally require a reviewer) |

On each environment, untick **Allow administrators to bypass configured protection
rules** and click **Save protection rules**, so nobody can skip the branch restriction.
Leave **Required reviewers** and **Wait timer** off for `staging` (they would hold every
build on `develop`); for `production` a reviewer is optional.

Each environment gets the same four **secrets**, with the values of its own key
(`base64 -w0 <file>.jks`; on macOS `base64 -i <file>.jks`):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore, base64 encoded |
| `ANDROID_STORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_PASSWORD` | the key password |
| `ANDROID_KEY_ALIAS` | `<app>-staging` or `<app>-upload` |

A project with Firebase adds `GOOGLE_SERVICES_JSON_BASE64` (the environment's
`google-services.json`, base64 encoded) the same way.

And one **variable** (not a secret) per environment:

| Variable | Value |
| --- | --- |
| `ANDROID_CERT_SHA256` | the SHA-256 fingerprint of that environment's key (section 1) |

With the variable set, a build fails if any file is signed with another key. Without it,
the build still fails for the debug key and prints the fingerprint in the run summary.

If a secret is missing, the signing job stops with a message naming it, before anything
is built. Set the environments up before the first merge into `develop` of an app whose
flavors exist.

## 4. Builds and releases

[`environments.md`](environments.md) describes what each event builds and how the draft
releases work. In short: a merge into `develop` refreshes the draft "Staging", and a
merge into `main` refreshes the draft `v<version>`, which you publish when it is final.
The first production build comes with the first pull request from `develop` into `main`,
so set up section 3 before it. The signed files are also kept for 30 days as the workflow
artifact `android-release-signed-<environment>`.

Raise the version in `pubspec.yaml` for every new release. The build number needs no
attention: CI uses its own run number.

## 5. Which APK to install

| Phone | File |
| --- | --- |
| Almost every current phone | `arm64-v8a` |
| Older 32-bit phones | `armeabi-v7a` |
| Emulators on a PC | `x86_64` |

Install with `adb install <file>.apk` or copy the file to the phone and open it. The
staging and production apps can be installed together. Signed with a stable key, each one
updates in place.

## 6. Debug symbols

The signed builds are obfuscated, so a stack trace shows meaningless names. The symbol
files that translate it back are kept as the workflow artifact
`android-debug-symbols-<environment>` for 30 days. They are not attached to a release,
because anyone who can read the release could then undo the obfuscation (and a
repository can be public). To read a trace:

```bash
flutter symbolize -i stack-trace.txt -d build/symbols/app.android-arm64.symbols
```

Download the artifact into `build/symbols/` first.

## 7. Google Play (later)

The production key works as the Play **upload key**. With Play App Signing (the
default), you upload the `.aab` signed with it and Google re-signs what users receive
with its own key. Two consequences:

- The first release of a new app is set up in the Play Console by hand; automating
  uploads comes afterwards (for example with fastlane `supply` and a service-account key
  stored as an environment secret).
- An APK installed from Play carries Google's signature, so it cannot be updated over an
  APK installed from GitHub (and the other way round); uninstall one before installing
  the other. Play can also accept your own key as the app signing key, but only when the
  app is first set up; check the Play Console help before relying on it.

The application ID cannot be changed after the first upload. The staging app has its own
ID, so it can get its own Play listing or internal track later without touching the
production app.
