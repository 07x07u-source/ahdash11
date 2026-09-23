import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  collectEnvironmentChecks,
  collectIosEnvironmentChecks,
  parseEnvText,
  parsePlistStringValues,
} from './check-release-integrations.mjs';

test('env parser keeps values private and ignores comments', () => {
  assert.deepEqual(parseEnvText('# comment\nAPP_ENV=production\nEMPTY=\n'), {
    APP_ENV: 'production',
    EMPTY: '',
  });
});

test('missing Production inputs fail closed', () => {
  const checks = collectEnvironmentChecks({});
  assert.equal(checks.APP_ENV, 'MISSING');
  assert.equal(checks.SUPABASE_URL, 'MISSING');
  assert.equal(checks.REVENUECAT_ANDROID_API_KEY, 'MISSING');
  assert.equal(checks.ADMOB_ANDROID_APP_ID, 'MISSING');
  assert.equal(checks.PRIVACY_POLICY_URL, 'MISSING');
  assert.equal(checks.TERMS_URL, 'MISSING');
  assert.equal(checks.PREMIUM_VOUCHERS_ENABLED_OFF, 'PRESENT');
  assert.equal(checks.PREMIUM_VOUCHERS_POLICY_APPROVED_OFF, 'PRESENT');
});

test('Development and Google test AdMob values are invalid for Production', () => {
  const checks = collectEnvironmentChecks({
    APP_ENV: 'development',
    ADMOB_ENABLED: 'true',
    ADMOB_ANDROID_APP_ID: 'ca-app-pub-3940256099942544~3347511713',
    ADMOB_REWARDED_ANDROID_ID: 'ca-app-pub-3940256099942544/5224354917',
    ADMOB_INTERSTITIAL_ANDROID_ID: 'ca-app-pub-3940256099942544/1033173712',
  });
  assert.equal(checks.APP_ENV, 'INVALID');
  assert.equal(checks.ADMOB_ANDROID_APP_ID, 'INVALID');
  assert.equal(checks.ADMOB_REWARDED_ANDROID_ID, 'INVALID');
  assert.equal(checks.ADMOB_INTERSTITIAL_ANDROID_ID, 'INVALID');
});

test('voucher gates fail when either Production switch is enabled', () => {
  const checks = collectEnvironmentChecks({
    PREMIUM_VOUCHERS_ENABLED: 'true',
    PREMIUM_VOUCHERS_POLICY_APPROVED: 'true',
  });
  assert.equal(checks.PREMIUM_VOUCHERS_ENABLED_OFF, 'INVALID');
  assert.equal(checks.PREMIUM_VOUCHERS_POLICY_APPROVED_OFF, 'INVALID');
});

test('iOS Production inputs require Apple, RevenueCat, and iOS AdMob values', () => {
  const checks = collectIosEnvironmentChecks({
    APP_ENV: 'production',
    FIREBASE_ENABLED: 'true',
    GOOGLE_AUTH_ENABLED: 'true',
    APPLE_AUTH_ENABLED: 'true',
    ADMOB_ENABLED: 'true',
    REVENUECAT_ENTITLEMENT_ID: 'premium',
    ADMOB_IOS_APP_ID: 'ca-app-pub-3940256099942544~1458002511',
  });
  assert.equal(checks.APP_ENV, 'PRESENT');
  assert.equal(checks.APPLE_AUTH_ENABLED, 'PRESENT');
  assert.equal(checks.REVENUECAT_IOS_API_KEY, 'MISSING');
  assert.equal(checks.ADMOB_IOS_APP_ID, 'INVALID');
});

test('plist parser reads public Firebase metadata without logging values', () => {
  const values = parsePlistStringValues(
    '<dict><key>BUNDLE_ID</key><string>com.ahdash.eleven</string>' +
      '<key>CLIENT_ID</key><string>client&amp;id</string></dict>',
  );
  assert.deepEqual(values, {
    BUNDLE_ID: 'com.ahdash.eleven',
    CLIENT_ID: 'client&id',
  });
});

test('command-line validator executes and blocks an incomplete environment', () => {
  const directory = mkdtempSync(join(tmpdir(), 'ahdash-config-validator-'));
  const envFile = join(directory, 'production.env');
  writeFileSync(envFile, 'APP_ENV=production\n', 'utf8');
  try {
    const result = spawnSync(
      process.execPath,
      ['scripts/check-release-integrations.mjs', '--env-file', envFile],
      { cwd: process.cwd(), encoding: 'utf8' },
    );
    assert.equal(result.status, 1);
    assert.match(result.stdout, /^PRESENT APP_ENV$/m);
    assert.match(result.stdout, /^MISSING REVENUECAT_ANDROID_API_KEY$/m);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
