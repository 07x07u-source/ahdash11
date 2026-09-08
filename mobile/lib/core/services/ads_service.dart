import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AdsService {
  bool get enabled;
  Future<void> initialize();
  Future<bool> showRewarded({required String userId});
  Future<bool> showInterstitialIfDue();
  Future<bool> showPrivacyOptions();
}

final class NoopAdsService implements AdsService {
  const NoopAdsService();

  @override
  bool get enabled => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showInterstitialIfDue() async => false;

  @override
  Future<bool> showRewarded({required String userId}) async => false;

  @override
  Future<bool> showPrivacyOptions() async => false;
}

final class GoogleAdsService implements AdsService {
  GoogleAdsService({
    required this.rewardedAdUnitId,
    required this.interstitialAdUnitId,
    required this.interstitialEveryMatches,
  });

  final String rewardedAdUnitId;
  final String interstitialAdUnitId;
  final int interstitialEveryMatches;
  var _canRequestAds = false;

  @override
  bool get enabled =>
      rewardedAdUnitId.isNotEmpty || interstitialAdUnitId.isNotEmpty;

  @override
  Future<void> initialize() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!updated.isCompleted) updated.complete();
      },
      (_) {
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future.timeout(const Duration(seconds: 12), onTimeout: () {});
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) await MobileAds.instance.initialize();
  }

  @override
  Future<bool> showRewarded({required String userId}) async {
    if (!_canRequestAds || rewardedAdUnitId.isEmpty || userId.isEmpty) {
      return false;
    }
    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => loaded.complete(ad),
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return false;
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: userId,
        customData: 'ahdash11_rewarded_store',
      ),
    );
    final completed = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        if (!completed.isCompleted) completed.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        if (!completed.isCompleted) completed.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return completed.future;
  }

  @override
  Future<bool> showInterstitialIfDue() async {
    if (!_canRequestAds || interstitialAdUnitId.isEmpty) return false;
    final preferences = await SharedPreferences.getInstance();
    final count = (preferences.getInt('completed_matches_since_ad') ?? 0) + 1;
    final interval = interstitialEveryMatches.clamp(1, 20);
    if (count < interval) {
      await preferences.setInt('completed_matches_since_ad', count);
      return false;
    }
    final loaded = Completer<InterstitialAd?>();
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => loaded.complete(ad),
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) {
      await preferences.setInt('completed_matches_since_ad', count);
      return false;
    }
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );
    await preferences.setInt('completed_matches_since_ad', 0);
    await ad.show();
    await dismissed.future;
    return true;
  }

  @override
  Future<bool> showPrivacyOptions() async {
    final completed = Completer<bool>();
    await ConsentForm.showPrivacyOptionsForm(
      (error) => completed.complete(error == null),
    );
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    return completed.future;
  }
}
