# Physical Device QA Checklist

Run only after the Production validator passes and a new signed Release APK is built.

## Auth

- [ ] Google Sign-In with a real release-signed installation
- [ ] Create Account
- [ ] Email Sign In
- [ ] Logout and account switch
- [ ] Guest flow and gated-route resume

## Party

- [ ] Categories, search, and Premium lock
- [ ] Helpers selection and consumption
- [ ] Ready screen and start-once behavior
- [ ] Board fresh/mid/near-complete states
- [ ] Text Question
- [ ] Image Question, loaded and fallback
- [ ] Answer Reveal
- [ ] Final Result and resume/reopen behavior

## Tournament

- [ ] Create
- [ ] Teams
- [ ] Draw
- [ ] Bracket
- [ ] Match
- [ ] Champion
- [ ] App close/reopen and tournament resume

## Social

- [ ] Friends list and search
- [ ] Add Friend
- [ ] Block with confirmation
- [ ] Unblock
- [ ] Ranking
- [ ] Profile and team detail

## Premium

- [ ] Monthly plan only where expected
- [ ] Annual plan only where expected
- [ ] Localized Google Play prices
- [ ] Premium category remains locked before purchase
- [ ] Active subscriber gets entitlement after app restart
- [ ] Active subscriber sees no purchase CTA
- [ ] Restore Purchases
- [ ] Ads-free behavior for active subscriber
- [ ] Non-subscriber rewarded/interstitial behavior and interval

## Voucher

- [ ] Voucher entry remains disabled/unreachable in Production
- [ ] Both Production voucher gates remain off

## Notifications

- [ ] Permission request, denial, and later settings behavior
- [ ] FCM token registration
- [ ] Foreground notification
- [ ] Background notification
- [ ] Terminated-app notification/deep-link behavior where available

## Device and resilience

- [ ] Keyboard on all text-input surfaces
- [ ] SafeArea and edge-to-edge layout
- [ ] Reduced-motion fallback
- [ ] App close/reopen
- [ ] Background/resume
- [ ] Weak network and request retry
- [ ] Offline startup and truthful unavailable states
- [ ] Package is `com.ahdash.eleven`
- [ ] Release build is non-debug and signed with intended certificate
