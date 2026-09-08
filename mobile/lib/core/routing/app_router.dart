import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/guest_capability_policy.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/football/presentation/football_preferences_screen.dart';
import '../../features/game/domain/game_mode.dart';
import '../../features/game/presentation/game_setup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/match/presentation/question_screen.dart';
import '../../features/match/presentation/results_screen.dart';
import '../../features/match/presentation/solo_setup_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/launch_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/party/domain/party_game.dart';
import '../../features/party/presentation/party_catalog_provider.dart';
import '../../features/party/presentation/party_game_controller.dart';
import '../../features/party/presentation/party_game_screens.dart';
import '../../features/party/presentation/party_setup_flow.dart';
import '../../features/party/presentation/party_setup_screens.dart';
import '../../features/party/presentation/party_support_screens.dart';
import '../../features/play/presentation/play_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/premium/presentation/premium_voucher_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ranking/presentation/ranking_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/social/presentation/blocked_players_screen.dart';
import '../../features/social/presentation/friends_screen.dart';
import '../../features/social/presentation/social_hub_screen.dart';
import '../../features/social/presentation/social_join_team_screen.dart';
import '../../features/social/presentation/social_team_screen.dart';
import '../../features/social/presentation/team_challenge_screen.dart';
import '../../features/support/presentation/report_problem_screen.dart';
import '../../features/tournament/presentation/tournament_controller.dart';
import '../../features/tournament/presentation/tournament_flow.dart';
import '../../features/tournament/presentation/tournament_join_screen.dart';
import '../../features/tournament/presentation/tournament_registrations_screen.dart';
import '../../features/tournament/presentation/tournament_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  Future<String?> setupRedirect(
    PartySetupStep step, {
    bool allowReview = false,
  }) async {
    final controller = ref.read(partyGameControllerProvider.notifier);
    await controller.restore();
    var activeHelperIds = PartyHelperId.values.toSet();
    var playableCategoryIds = <String>{};
    try {
      final definitions = await ref
          .read(partyHelperCatalogProvider.future)
          .timeout(const Duration(seconds: 6));
      activeHelperIds = definitions.map((definition) => definition.id).toSet();
    } catch (_) {
      // The domain defaults remain the safe compatibility set.
    }
    try {
      final catalog = await ref
          .read(partyCatalogProvider.future)
          .timeout(const Duration(seconds: 6));
      final premium = await ref
          .read(partyEntitlementProvider.future)
          .timeout(const Duration(seconds: 6));
      playableCategoryIds = catalog
          .playableCategories(premium: premium)
          .map((category) => category.id)
          .toSet();
    } catch (_) {
      // An unavailable catalog truthfully resolves back to category selection.
    }
    return PartySetupFlowResolver.redirectFor(
      step,
      ref.read(partyGameControllerProvider),
      activeHelperIds: activeHelperIds,
      playableCategoryIds: playableCategoryIds,
      allowReview: allowReview,
    );
  }

  Future<String?> gameplayRedirect(PartyGameplayStep step) async {
    final controller = ref.read(partyGameControllerProvider.notifier);
    await controller.restore();
    final state = ref.read(partyGameControllerProvider);
    return PartySetupFlowResolver.redirectGameplay(step, state);
  }

  Future<String?> tournamentRedirect(
    TournamentFlowStep step, {
    String? matchId,
  }) async {
    await ref.read(tournamentControllerProvider.notifier).restore();
    if (matchId != null) {
      await ref
          .read(tournamentControllerProvider.notifier)
          .restoreMatch(matchId);
    }
    return TournamentFlowResolver.redirectFor(
      step,
      ref.read(tournamentControllerProvider),
      matchId: matchId,
    );
  }

  final authRefresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => authRefresh.value++);
  ref.onDispose(authRefresh.dispose);
  final router = GoRouter(
    initialLocation: '/launch',
    refreshListenable: authRefresh,
    redirect: (_, state) {
      final path = state.uri.path;
      final policy = GuestCapabilityPolicy(
        ref.read(authControllerProvider).asData?.value,
      );
      if (path == '/account-required') {
        return policy.hasAccount
            ? GuestCapabilityPolicy.safeReturnTo(
                state.uri.queryParameters['next'],
              )
            : null;
      }
      if (const {'/launch', '/onboarding', '/auth'}.contains(path) ||
          path == '/online' ||
          path.startsWith('/online/') ||
          path.startsWith('/room/')) {
        return null;
      }
      return policy.allowsLocation(state.uri.toString())
          ? null
          : GuestCapabilityPolicy.gateLocation(state.uri.toString());
    },
    routes: [
      GoRoute(path: '/launch', builder: (_, _) => const LaunchScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, state) => AuthScreen(
          returnTo: state.uri.queryParameters['next'],
          initialMode: state.uri.queryParameters['mode'] == 'create'
              ? AuthMode.createAccount
              : AuthMode.signIn,
        ),
      ),
      GoRoute(
        path: '/account-required',
        builder: (_, state) => AuthGateScreen(
          destination: state.uri.queryParameters['next'] ?? '/home',
          requiredCapability: AppCapability.values
              .where((c) => c.name == state.uri.queryParameters['feature'])
              .firstOrNull,
        ),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/tournaments',
        builder: (_, _) => const TournamentHubScreen(),
      ),
      GoRoute(
        path: '/tournaments/create',
        builder: (_, _) => const TournamentCreateScreen(),
      ),
      GoRoute(
        path: '/tournaments/join',
        builder: (_, state) => TournamentJoinScreen(
          initialCode: state.uri.queryParameters['code'],
          initialPlayersPerTeam: int.tryParse(
            state.uri.queryParameters['players'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/tournaments/teams',
        redirect: (_, _) => tournamentRedirect(TournamentFlowStep.teams),
        builder: (_, _) => const TournamentTeamsScreen(),
      ),
      GoRoute(
        path: '/tournaments/registrations',
        builder: (_, _) => const TournamentRegistrationsScreen(),
      ),
      GoRoute(
        path: '/tournaments/draw',
        redirect: (_, _) => tournamentRedirect(TournamentFlowStep.draw),
        builder: (_, _) => const TournamentDrawScreen(),
      ),
      GoRoute(
        path: '/tournaments/bracket',
        redirect: (_, _) => tournamentRedirect(TournamentFlowStep.bracket),
        builder: (_, _) => const TournamentBracketScreen(),
      ),
      GoRoute(
        path: '/tournaments/champion',
        redirect: (_, _) => tournamentRedirect(TournamentFlowStep.champion),
        builder: (_, _) => const TournamentChampionScreen(),
      ),
      GoRoute(
        path: '/tournaments/match/:matchId',
        redirect: (_, state) => tournamentRedirect(
          TournamentFlowStep.match,
          matchId: state.pathParameters['matchId'],
        ),
        builder: (_, state) =>
            TournamentMatchScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/party/categories',
        redirect: (_, state) => setupRedirect(
          PartySetupStep.categories,
          allowReview: state.uri.queryParameters['review'] == '1',
        ),
        builder: (_, _) => const PartyCategorySelectionScreen(),
      ),
      GoRoute(
        path: '/party/teams',
        redirect: (_, state) => setupRedirect(
          PartySetupStep.teams,
          allowReview: state.uri.queryParameters['review'] == '1',
        ),
        builder: (_, _) => const PartyTeamSetupScreen(),
      ),
      GoRoute(
        path: '/party/splitter',
        redirect: (_, state) => setupRedirect(
          PartySetupStep.splitter,
          allowReview: state.uri.queryParameters['review'] == '1',
        ),
        builder: (_, _) => const PartyTeamSplitterScreen(),
      ),
      GoRoute(
        path: '/party/helpers',
        redirect: (_, state) => setupRedirect(
          PartySetupStep.helpers,
          allowReview: state.uri.queryParameters['review'] == '1',
        ),
        builder: (_, _) => const PartyHelperSelectionScreen(),
      ),
      GoRoute(
        path: '/party/ready',
        redirect: (_, state) => setupRedirect(
          PartySetupStep.ready,
          allowReview: state.uri.queryParameters['review'] == '1',
        ),
        builder: (_, _) => const PartyReadyScreen(),
      ),
      GoRoute(
        path: '/party/board',
        redirect: (_, _) => gameplayRedirect(PartyGameplayStep.board),
        builder: (_, _) => const PartyBoardScreen(),
      ),
      GoRoute(
        path: '/party/question',
        redirect: (_, _) => gameplayRedirect(PartyGameplayStep.question),
        builder: (_, _) => const PartyQuestionScreen(),
      ),
      GoRoute(
        path: '/party/reveal',
        redirect: (_, _) => gameplayRedirect(PartyGameplayStep.reveal),
        builder: (_, _) => const PartyRevealScreen(),
      ),
      GoRoute(
        path: '/party/result',
        redirect: (_, _) => gameplayRedirect(PartyGameplayStep.result),
        builder: (_, _) => const PartyResultScreen(),
      ),
      GoRoute(
        path: '/party/games',
        builder: (_, _) => const PartyGamesScreen(),
      ),
      GoRoute(path: '/how-to-play', builder: (_, _) => const HowToPlayScreen()),
      GoRoute(path: '/play', builder: (_, _) => const PlayScreen()),
      GoRoute(
        path: '/play/setup/:gameType',
        builder: (_, state) {
          final type = GameTypeCopy.fromSlug(
            state.pathParameters['gameType'] ?? '',
          );
          return GameSetupScreen(
            gameType: type ?? GameType.classic,
            initialFormat: state.uri.queryParameters['format'],
          );
        },
      ),
      GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(
        path: '/solo',
        builder: (_, state) => SoloSetupScreen(
          gameType:
              GameTypeCopy.fromSlug(
                state.uri.queryParameters['gameType'] ?? '',
              ) ??
              GameType.classic,
          initialCategoryId: state.uri.queryParameters['categoryId'],
        ),
      ),
      GoRoute(path: '/solo/match', builder: (_, _) => const QuestionScreen()),
      GoRoute(path: '/solo/result', builder: (_, _) => const ResultsScreen()),
      // Compatibility tombstones keep old notification/deep links safe while
      // live online matches are no longer part of the product.
      GoRoute(path: '/online', redirect: (_, _) => '/home'),
      GoRoute(path: '/online/match/:matchId', redirect: (_, _) => '/home'),
      GoRoute(path: '/room/:roomId', redirect: (_, _) => '/home'),
      GoRoute(path: '/ranking', builder: (_, _) => const RankingScreen()),
      GoRoute(path: '/store', builder: (_, _) => const PremiumScreen()),
      GoRoute(path: '/premium', builder: (_, _) => const PremiumScreen()),
      GoRoute(
        path: '/premium/voucher',
        builder: (_, _) => const PremiumVoucherScreen(),
      ),
      GoRoute(path: '/wallet', redirect: (_, _) => '/store'),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/friends',
        builder: (_, state) =>
            FriendsScreen(inviteTeamId: state.uri.queryParameters['teamId']),
      ),
      GoRoute(
        path: '/football-preferences',
        builder: (_, _) => const FootballPreferencesScreen(),
      ),
      GoRoute(path: '/teams', builder: (_, _) => const SocialHubScreen()),
      GoRoute(
        path: '/teams/join',
        builder: (_, state) => SocialJoinTeamScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/blocked-players',
        builder: (_, _) => const BlockedPlayersScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder: (_, state) =>
            SocialTeamScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/challenges/:challengeId',
        builder: (_, state) => TeamChallengeScreen(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/report-problem',
        builder: (_, state) => ReportProblemScreen(
          sourceScreen: state.uri.queryParameters['source'] ?? '/settings',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
