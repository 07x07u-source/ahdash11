import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { basename, dirname, isAbsolute, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, '..');
const mobileRoot = resolve(repositoryRoot, 'mobile');
const androidRoot = resolve(mobileRoot, 'android');
const androidAppRoot = resolve(androidRoot, 'app');
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

function loadEnvironment(envFile) {
  const fileValues = existsSync(envFile)
    ? parseEnvText(readFileSync(envFile, 'utf8'))
    : {};
  const merged = { ...fileValues };
  for (const key of Object.keys(collectEnvironmentChecks({}))) {
    const sourceKey = key.endsWith('_OFF') ? key.slice(0, -4) : key;
    if (Object.hasOwn(process.env, sourceKey)) merged[sourceKey] = process.env[sourceKey];
  }
  return merged;
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

export function runValidator(argv = process.argv.slice(2)) {
  const argumentsMap = parseArguments(argv);
  const envFile = argumentsMap.envFile
    ? resolve(process.cwd(), argumentsMap.envFile)
    : resolve(mobileRoot, '.env');
  const environmentChecks = collectEnvironmentChecks(loadEnvironment(envFile));
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
