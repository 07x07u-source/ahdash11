import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { basename, dirname, isAbsolute, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, '..');
const mobileRoot = resolve(repositoryRoot, 'mobile');
const androidRoot = resolve(mobileRoot, 'android');
const androidAppRoot = resolve(androidRoot, 'app');
const iosRoot = resolve(mobileRoot, 'ios');
const iosRunnerRoot = resolve(iosRoot, 'Runner');
const expectedPackage = 'com.ahdash.eleven';
const googleTestPublisher = '3940256099942544';

export function parseEnvText(text) {
  return Object.fromEntries(
    text
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const separator = line.indexOf('=');
        const key = line.slice(0, separator).trim();
        const value = line
          .slice(separator + 1)
          .trim()
          .replace(/^['"]|['"]$/g, '');
        return [key, value];
      }),
  );
}

function parseArguments(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (argv[index] === '--env-file') {
      result.envFile = argv[index + 1];
      index += 1;
    } else if (argv[index] === '--platform') {
      result.platform = argv[index + 1];
      index += 1;
    }
  }
  return result;
}

function usable(value) {
  const normalized = String(value ?? '').trim().toLowerCase();
  return Boolean(normalized) &&
    !normalized.includes('replace_me') &&
    !normalized.includes('your_') &&
    !normalized.includes('placeholder') &&
    normalized !== 'todo';
}

function presentOrInvalid(value, validator = () => true) {
  if (!usable(value)) return 'MISSING';
  return validator(String(value).trim()) ? 'PRESENT' : 'INVALID';
}

function productionUrl(value) {
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase();
    return url.protocol === 'https:' &&
      Boolean(host) &&
      host !== 'localhost' &&
      !host.endsWith('.localhost') &&
      !host.includes('example.com') &&
      !host.endsWith('.invalid');
  } catch {
    return false;
  }
}

function jwtRole(value) {
  const parts = String(value ?? '').split('.');
  if (parts.length !== 3) return null;
  try {
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')).role ?? null;
  } catch {
    return null;
  }
}

function publicSupabaseKey(value) {
  if (!usable(value) || String(value).startsWith('sb_secret_')) return false;
  const role = jwtRole(value);
  return role === null || role === 'anon';
}

function adMobAppId(value) {
  return /^ca-app-pub-\d{16}~\d{10}$/.test(value) &&
    !value.includes(googleTestPublisher);
}

function adMobUnitId(value) {
  return /^ca-app-pub-\d{16}\/\d{10}$/.test(value) &&
    !value.includes(googleTestPublisher);
}

export function collectEnvironmentChecks(env) {
  const interval = Number.parseInt(env.ADMOB_INTERSTITIAL_EVERY_MATCHES ?? '', 10);
  return {
    APP_ENV: presentOrInvalid(env.APP_ENV, (value) => value === 'production'),
    SUPABASE_URL: presentOrInvalid(
      env.SUPABASE_URL,
      (value) => productionUrl(value) && value.endsWith('.supabase.co'),
    ),
    SUPABASE_ANON_KEY: presentOrInvalid(env.SUPABASE_ANON_KEY, publicSupabaseKey),
    FIREBASE_ENABLED: presentOrInvalid(
      env.FIREBASE_ENABLED,
      (value) => value === 'true',
    ),
    GOOGLE_AUTH_ENABLED: presentOrInvalid(
      env.GOOGLE_AUTH_ENABLED,
      (value) => value === 'true',
    ),
    REVENUECAT_ANDROID_API_KEY: presentOrInvalid(env.REVENUECAT_ANDROID_API_KEY),
    REVENUECAT_ENTITLEMENT_ID: presentOrInvalid(
      env.REVENUECAT_ENTITLEMENT_ID,
      (value) => value === 'premium',
    ),
    ADMOB_ENABLED: presentOrInvalid(env.ADMOB_ENABLED, (value) => value === 'true'),
    ADMOB_ANDROID_APP_ID: presentOrInvalid(env.ADMOB_ANDROID_APP_ID, adMobAppId),
    ADMOB_REWARDED_ANDROID_ID: presentOrInvalid(
      env.ADMOB_REWARDED_ANDROID_ID,
      adMobUnitId,
    ),
    ADMOB_INTERSTITIAL_ANDROID_ID: presentOrInvalid(
      env.ADMOB_INTERSTITIAL_ANDROID_ID,
      adMobUnitId,
    ),
    ADMOB_INTERSTITIAL_EVERY_MATCHES: presentOrInvalid(
      env.ADMOB_INTERSTITIAL_EVERY_MATCHES,
      () => Number.isInteger(interval) && interval >= 1 && interval <= 20,
    ),
    PRIVACY_POLICY_URL: presentOrInvalid(env.PRIVACY_POLICY_URL, productionUrl),
    TERMS_URL: presentOrInvalid(env.TERMS_URL, productionUrl),
    PREMIUM_VOUCHERS_ENABLED_OFF:
      env.PREMIUM_VOUCHERS_ENABLED === undefined ||
      env.PREMIUM_VOUCHERS_ENABLED === '' ||
      env.PREMIUM_VOUCHERS_ENABLED === 'false'
        ? 'PRESENT'
        : 'INVALID',
    PREMIUM_VOUCHERS_POLICY_APPROVED_OFF:
      env.PREMIUM_VOUCHERS_POLICY_APPROVED === undefined ||
      env.PREMIUM_VOUCHERS_POLICY_APPROVED === '' ||
      env.PREMIUM_VOUCHERS_POLICY_APPROVED === 'false'
        ? 'PRESENT'
        : 'INVALID',
  };
}

export function collectIosEnvironmentChecks(env) {
  const common = collectEnvironmentChecks(env);
  return {
    APP_ENV: common.APP_ENV,
    SUPABASE_URL: common.SUPABASE_URL,
    SUPABASE_ANON_KEY: common.SUPABASE_ANON_KEY,
    FIREBASE_ENABLED: common.FIREBASE_ENABLED,
    GOOGLE_AUTH_ENABLED: common.GOOGLE_AUTH_ENABLED,
    APPLE_AUTH_ENABLED: presentOrInvalid(
      env.APPLE_AUTH_ENABLED,
      (value) => value === 'true',
    ),
    REVENUECAT_IOS_API_KEY: presentOrInvalid(env.REVENUECAT_IOS_API_KEY),
    REVENUECAT_ENTITLEMENT_ID: common.REVENUECAT_ENTITLEMENT_ID,
    ADMOB_ENABLED: common.ADMOB_ENABLED,
    ADMOB_IOS_APP_ID: presentOrInvalid(env.ADMOB_IOS_APP_ID, adMobAppId),
    ADMOB_REWARDED_IOS_ID: presentOrInvalid(
      env.ADMOB_REWARDED_IOS_ID,
      adMobUnitId,
    ),
    ADMOB_INTERSTITIAL_IOS_ID: presentOrInvalid(
      env.ADMOB_INTERSTITIAL_IOS_ID,
      adMobUnitId,
    ),
    ADMOB_INTERSTITIAL_EVERY_MATCHES:
      common.ADMOB_INTERSTITIAL_EVERY_MATCHES,
    PRIVACY_POLICY_URL: common.PRIVACY_POLICY_URL,
    TERMS_URL: common.TERMS_URL,
    PREMIUM_VOUCHERS_ENABLED_OFF: common.PREMIUM_VOUCHERS_ENABLED_OFF,
    PREMIUM_VOUCHERS_POLICY_APPROVED_OFF:
      common.PREMIUM_VOUCHERS_POLICY_APPROVED_OFF,
  };
}

function loadEnvironment(envFile, checkNames) {
  const fileValues = existsSync(envFile)
    ? parseEnvText(readFileSync(envFile, 'utf8'))
    : {};
  const merged = { ...fileValues };
  for (const key of checkNames) {
    const sourceKey = key.endsWith('_OFF') ? key.slice(0, -4) : key;
    if (Object.hasOwn(process.env, sourceKey)) merged[sourceKey] = process.env[sourceKey];
  }
  return merged;
}

function decodeXmlText(value) {
  return value
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
}

export function parsePlistStringValues(text) {
  const values = {};
  const entries =
    /<key>\s*([^<]+?)\s*<\/key>\s*<string>\s*([^<]*?)\s*<\/string>/gs;
  for (const match of text.matchAll(entries)) {
    values[decodeXmlText(match[1].trim())] = decodeXmlText(match[2].trim());
  }
  return values;
}

function loadGoogleServicesChecks() {
  const file = resolve(androidAppRoot, 'google-services.json');
  if (!existsSync(file)) {
    return {
      FIREBASE_ANDROID_CONFIG: 'MISSING',
      FIREBASE_PACKAGE: 'MISSING',
      FIREBASE_PROJECT_METADATA: 'MISSING',
      FCM_SENDER_METADATA: 'MISSING',
      GOOGLE_SIGN_IN_ANDROID_CLIENT: 'MISSING',
    };
  }
  try {
    const config = JSON.parse(readFileSync(file, 'utf8'));
    const client = (config.client ?? []).find(
      (entry) =>
        entry.client_info?.android_client_info?.package_name === expectedPackage,
    );
    const oauthClients = client?.oauth_client ?? [];
    return {
      FIREBASE_ANDROID_CONFIG: 'PRESENT',
      FIREBASE_PACKAGE: client ? 'PRESENT' : 'INVALID',
      FIREBASE_PROJECT_METADATA:
        usable(config.project_info?.project_id) &&
        usable(client?.client_info?.mobilesdk_app_id) &&
        Array.isArray(client?.api_key) &&
        client.api_key.length > 0
          ? 'PRESENT'
          : 'INVALID',
      FCM_SENDER_METADATA: usable(config.project_info?.project_number)
        ? 'PRESENT'
        : 'INVALID',
      GOOGLE_SIGN_IN_ANDROID_CLIENT: oauthClients.some(
        (entry) => entry.client_type === 1,
      )
        ? 'PRESENT'
        : 'INVALID',
      _oauthFingerprints: oauthClients
        .filter((entry) => entry.client_type === 1)
        .map((entry) =>
          String(entry.android_info?.certificate_hash ?? '')
            .replaceAll(':', '')
            .toUpperCase(),
        ),
    };
  } catch {
    return {
      FIREBASE_ANDROID_CONFIG: 'INVALID',
      FIREBASE_PACKAGE: 'INVALID',
      FIREBASE_PROJECT_METADATA: 'INVALID',
      FCM_SENDER_METADATA: 'INVALID',
      GOOGLE_SIGN_IN_ANDROID_CLIENT: 'INVALID',
    };
  }
}

function loadIosFirebaseChecks() {
  const file = resolve(iosRunnerRoot, 'GoogleService-Info.plist');
  if (!existsSync(file)) {
    return {
      FIREBASE_IOS_CONFIG: 'MISSING',
      FIREBASE_IOS_BUNDLE_ID: 'MISSING',
      FIREBASE_IOS_PROJECT_METADATA: 'MISSING',
      GOOGLE_SIGN_IN_IOS_CLIENT: 'MISSING',
      GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT: 'MISSING',
    };
  }
  try {
    const values = parsePlistStringValues(readFileSync(file, 'utf8'));
    return {
      FIREBASE_IOS_CONFIG: 'PRESENT',
      FIREBASE_IOS_BUNDLE_ID:
        values.BUNDLE_ID === expectedPackage ? 'PRESENT' : 'INVALID',
      FIREBASE_IOS_PROJECT_METADATA:
        usable(values.PROJECT_ID) && usable(values.GOOGLE_APP_ID)
          ? 'PRESENT'
          : 'INVALID',
      GOOGLE_SIGN_IN_IOS_CLIENT: usable(values.CLIENT_ID)
        ? 'PRESENT'
        : 'INVALID',
      GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT: usable(values.REVERSED_CLIENT_ID)
        ? 'PRESENT'
        : 'INVALID',
      _clientId: values.CLIENT_ID ?? '',
      _reversedClientId: values.REVERSED_CLIENT_ID ?? '',
    };
  } catch {
    return {
      FIREBASE_IOS_CONFIG: 'INVALID',
      FIREBASE_IOS_BUNDLE_ID: 'INVALID',
      FIREBASE_IOS_PROJECT_METADATA: 'INVALID',
      GOOGLE_SIGN_IN_IOS_CLIENT: 'INVALID',
      GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT: 'INVALID',
    };
  }
}

function readProperties(file) {
  return parseEnvText(readFileSync(file, 'utf8'));
}

function inspectSigning(googleChecks) {
  const localPropertiesFile = resolve(androidRoot, 'key.properties');
  const ciSigning = {
    storeFile: process.env.CM_KEYSTORE_PATH,
    storePassword: process.env.CM_KEYSTORE_PASSWORD,
    keyAlias: process.env.CM_KEY_ALIAS,
    keyPassword: process.env.CM_KEY_PASSWORD,
  };
  let properties;
  let storeFile;
  if (existsSync(localPropertiesFile)) {
    properties = readProperties(localPropertiesFile);
    storeFile = isAbsolute(properties.storeFile ?? '')
      ? properties.storeFile
      : resolve(androidAppRoot, properties.storeFile ?? '');
  } else if (Object.values(ciSigning).every(usable)) {
    properties = ciSigning;
    storeFile = ciSigning.storeFile;
  } else {
    return {
      RELEASE_SIGNING_CONFIG: 'MISSING',
      RELEASE_KEYSTORE: 'MISSING',
      RELEASE_CERTIFICATE_SHA1: 'MISSING',
      RELEASE_CERTIFICATE_SHA256: 'MISSING',
      GOOGLE_SIGN_IN_RELEASE_SHA1: 'MISSING',
    };
  }

  const fieldsPresent = ['storeFile', 'storePassword', 'keyAlias', 'keyPassword'].every(
    (key) => usable(properties[key]),
  );
  if (!fieldsPresent || !existsSync(storeFile)) {
    return {
      RELEASE_SIGNING_CONFIG: fieldsPresent ? 'PRESENT' : 'INVALID',
      RELEASE_KEYSTORE: existsSync(storeFile) ? 'PRESENT' : 'MISSING',
      RELEASE_CERTIFICATE_SHA1: 'MISSING',
      RELEASE_CERTIFICATE_SHA256: 'MISSING',
      GOOGLE_SIGN_IN_RELEASE_SHA1: 'MISSING',
    };
  }

  const childEnvironment = {
    ...process.env,
    AHDASH_VALIDATOR_STORE_PASS: properties.storePassword,
    AHDASH_VALIDATOR_KEY_PASS: properties.keyPassword,
  };
  const keytool = spawnSync(
    'keytool',
    [
      '-list',
      '-v',
      '-keystore',
      storeFile,
      '-alias',
      properties.keyAlias,
      '-storepass:env',
      'AHDASH_VALIDATOR_STORE_PASS',
      '-keypass:env',
      'AHDASH_VALIDATOR_KEY_PASS',
    ],
    { encoding: 'utf8', env: childEnvironment },
  );
  const output = `${keytool.stdout ?? ''}\n${keytool.stderr ?? ''}`;
  const sha1 = output.match(/^\s*SHA1:\s*([0-9A-F:]+)$/m)?.[1] ?? '';
  const sha256 = output.match(/^\s*SHA256:\s*([0-9A-F:]+)$/m)?.[1] ?? '';
  const normalizedSha1 = sha1.replaceAll(':', '').toUpperCase();
  const fingerprints = googleChecks._oauthFingerprints ?? [];

  return {
    RELEASE_SIGNING_CONFIG: 'PRESENT',
    RELEASE_KEYSTORE: 'PRESENT',
    RELEASE_CERTIFICATE_SHA1: sha1 ? 'PRESENT' : 'INVALID',
    RELEASE_CERTIFICATE_SHA256: sha256 ? 'PRESENT' : 'INVALID',
    GOOGLE_SIGN_IN_RELEASE_SHA1:
      sha1 && fingerprints.includes(normalizedSha1) ? 'PRESENT' : 'INVALID',
  };
}

function sourceChecks() {
  const gradle = readFileSync(resolve(androidAppRoot, 'build.gradle.kts'), 'utf8');
  return {
    ANDROID_APPLICATION_ID: gradle.includes(`applicationId = "${expectedPackage}"`)
      ? 'PRESENT'
      : 'INVALID',
    RELEASE_SIGNING_FAIL_CLOSED:
      gradle.includes('Release signing configuration is required')
        ? 'PRESENT'
        : 'INVALID',
    RELEASE_ADMOB_APP_ID_FAIL_CLOSED:
      gradle.includes('Production ADMOB_ANDROID_APP_ID is required')
        ? 'PRESENT'
        : 'INVALID',
  };
}

function iosSourceChecks(firebaseChecks, environment) {
  const infoFile = resolve(iosRunnerRoot, 'Info.plist');
  const entitlementsFile = resolve(iosRunnerRoot, 'Runner.entitlements');
  const projectFile = resolve(iosRoot, 'Runner.xcodeproj', 'project.pbxproj');
  const podfile = resolve(iosRoot, 'Podfile');
  const frameworkInfoFile = resolve(iosRoot, 'Flutter', 'AppFrameworkInfo.plist');
  if (
    !existsSync(infoFile) ||
    !existsSync(entitlementsFile) ||
    !existsSync(projectFile) ||
    !existsSync(podfile) ||
    !existsSync(frameworkInfoFile)
  ) {
    return {
      IOS_APPLICATION_ID: 'MISSING',
      IOS_DEPLOYMENT_TARGET: 'MISSING',
      IOS_RELEASE_ENTITLEMENTS: 'MISSING',
      IOS_APPLE_SIGN_IN_ENTITLEMENT: 'MISSING',
      IOS_APS_ENTITLEMENT: 'MISSING',
      IOS_FIREBASE_RESOURCE: 'MISSING',
      GOOGLE_SIGN_IN_IOS_INFO_CLIENT: 'MISSING',
      GOOGLE_SIGN_IN_IOS_URL_SCHEME: 'MISSING',
      RELEASE_ADMOB_IOS_APP_ID: 'MISSING',
      IOS_CRASHLYTICS_DSYM_UPLOAD: 'MISSING',
    };
  }

  const infoText = readFileSync(infoFile, 'utf8');
  const infoValues = parsePlistStringValues(infoText);
  const entitlements = readFileSync(entitlementsFile, 'utf8');
  const project = readFileSync(projectFile, 'utf8');
  const podfileText = readFileSync(podfile, 'utf8');
  const frameworkInfo = parsePlistStringValues(
    readFileSync(frameworkInfoFile, 'utf8'),
  );
  const bundleDeclarations =
    project.match(/PRODUCT_BUNDLE_IDENTIFIER = [^;]+;/g) ?? [];
  const bundleIdsMatch =
    bundleDeclarations.length > 0 &&
    bundleDeclarations.every((entry) =>
      entry.includes('PRODUCT_BUNDLE_IDENTIFIER = ' + expectedPackage + ';'),
    );
  const clientId = firebaseChecks._clientId ?? '';
  const reversedClientId = firebaseChecks._reversedClientId ?? '';

  return {
    IOS_APPLICATION_ID: bundleIdsMatch ? 'PRESENT' : 'INVALID',
    IOS_DEPLOYMENT_TARGET:
      !project.includes('IPHONEOS_DEPLOYMENT_TARGET = 13.0;') &&
      project.includes('IPHONEOS_DEPLOYMENT_TARGET = 15.0;') &&
      podfileText.includes("platform :ios, '15.0'") &&
      podfileText.includes(
        "config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'",
      ) &&
      frameworkInfo.MinimumOSVersion === '15.0'
        ? 'PRESENT'
        : 'INVALID',
    IOS_RELEASE_ENTITLEMENTS:
      project.includes('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')
        ? 'PRESENT'
        : 'INVALID',
    IOS_APPLE_SIGN_IN_ENTITLEMENT:
      /<key>\s*com\.apple\.developer\.applesignin\s*<\/key>\s*<array>\s*<string>\s*Default\s*<\/string>\s*<\/array>/s.test(
        entitlements,
      )
        ? 'PRESENT'
        : 'INVALID',
    IOS_APS_ENTITLEMENT:
      /<key>\s*aps-environment\s*<\/key>\s*<string>\s*\$\(APS_ENVIRONMENT\)\s*<\/string>/s.test(
        entitlements,
      )
        ? 'PRESENT'
        : 'INVALID',
    IOS_FIREBASE_RESOURCE:
      project.includes('GoogleService-Info.plist in Resources')
        ? 'PRESENT'
        : 'INVALID',
    GOOGLE_SIGN_IN_IOS_INFO_CLIENT:
      usable(clientId) && infoValues.GIDClientID === clientId
        ? 'PRESENT'
        : 'INVALID',
    GOOGLE_SIGN_IN_IOS_URL_SCHEME:
      usable(reversedClientId) &&
      infoText.includes('<string>' + reversedClientId + '</string>')
        ? 'PRESENT'
        : 'INVALID',
    RELEASE_ADMOB_IOS_APP_ID:
      adMobAppId(infoValues.GADApplicationIdentifier ?? '') &&
      infoValues.GADApplicationIdentifier === environment.ADMOB_IOS_APP_ID
        ? 'PRESENT'
        : 'INVALID',
    IOS_CRASHLYTICS_DSYM_UPLOAD:
      project.includes('FirebaseCrashlytics/run') ? 'PRESENT' : 'INVALID',
  };
}

export function runValidator(argv = process.argv.slice(2)) {
  const argumentsMap = parseArguments(argv);
  const platform = argumentsMap.platform ?? 'android';
  if (platform !== 'android' && platform !== 'ios') {
    console.log('INVALID RELEASE_PLATFORM');
    return false;
  }
  const envFile = argumentsMap.envFile
    ? resolve(process.cwd(), argumentsMap.envFile)
    : resolve(mobileRoot, '.env');
  const collector =
    platform === 'ios' ? collectIosEnvironmentChecks : collectEnvironmentChecks;
  const checkNames = Object.keys(collector({}));
  const environment = loadEnvironment(envFile, checkNames);
  const environmentChecks = collector(environment);
  if (platform === 'ios') {
    const firebaseChecks = loadIosFirebaseChecks();
    const source = iosSourceChecks(firebaseChecks, environment);
    delete firebaseChecks._clientId;
    delete firebaseChecks._reversedClientId;
    const checks = {
      ...environmentChecks,
      ...firebaseChecks,
      ...source,
    };
    for (const [name, status] of Object.entries(checks)) {
      console.log(status + ' ' + name);
    }
    return Object.values(checks).every((status) => status === 'PRESENT');
  }
  const googleChecks = loadGoogleServicesChecks();
  const signingChecks = inspectSigning(googleChecks);
  delete googleChecks._oauthFingerprints;
  const checks = {
    ...environmentChecks,
    ...googleChecks,
    ...signingChecks,
    ...sourceChecks(),
  };

  for (const [name, status] of Object.entries(checks)) {
    console.log(`${status} ${name}`);
  }
  return Object.values(checks).every((status) => status === 'PRESENT');
}

if (process.argv[1] && basename(process.argv[1]) === 'check-release-integrations.mjs') {
  if (!runValidator()) process.exitCode = 1;
}
