import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_services.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/football_repository.dart';
import '../domain/football_entities.dart';

final footballPreferencesProvider =
    AsyncNotifierProvider<FootballPreferencesController, FootballView>(
      FootballPreferencesController.new,
    );

final class FootballView {
  const FootballView({
    this.leagues = const [],
    this.clubs = const [],
    this.leagueId,
    this.clubId,
    this.showPublicly = true,
    this.canSave = false,
    this.searching = false,
    this.saving = false,
    this.query = '',
    this.message,
  });
  final List<FootballLeague> leagues;
  final List<FootballClub> clubs;
  final String? leagueId, clubId, message;
  final String query;
  final bool showPublicly, canSave, searching, saving;
  FootballView copyWith({
    String? leagueId,
    String? clubId,
    bool clearLeague = false,
    bool clearClub = false,
    List<FootballClub>? clubs,
    bool? showPublicly,
    bool? searching,
    bool? saving,
    String? query,
    String? message,
  }) => FootballView(
    leagues: leagues,
    canSave: canSave,
    clubs: clubs ?? this.clubs,
    leagueId: clearLeague ? null : leagueId ?? this.leagueId,
    clubId: clearClub ? null : clubId ?? this.clubId,
    showPublicly: showPublicly ?? this.showPublicly,
    searching: searching ?? this.searching,
    saving: saving ?? this.saving,
    query: query ?? this.query,
    message: message,
  );
}

class FootballPreferencesController extends AsyncNotifier<FootballView> {
  Timer? _debounce;
  int _request = 0;
  int _epoch = 0;
  @override
  Future<FootballView> build() async {
    final epoch = ++_epoch;
    _request++;
    _debounce?.cancel();
    ref.onDispose(() => _debounce?.cancel());
    final auth = await ref.watch(authControllerProvider.future);
    final repository = ref.watch(footballRepositoryProvider);
    if (!repository.isAvailable) throw StateError('Unavailable');
    final leagues = await repository.listLeagues();
    final signedIn = auth != null && !auth.isGuest;
    final prefs = signedIn
        ? await repository.loadPreferences()
        : const FootballPreferences();
    final leagueId = leagues.any((l) => l.id == prefs.leagueId)
        ? prefs.leagueId
        : null;
    final clubs = leagueId == null
        ? <FootballClub>[]
        : await repository.searchClubs(leagueId: leagueId);
    if (epoch != _epoch) return const FootballView();
    return FootballView(
      leagues: leagues,
      clubs: clubs,
      leagueId: leagueId,
      clubId: leagueId == null ? null : prefs.clubId,
      showPublicly: prefs.showPublicly,
      canSave: signedIn,
    );
  }

  void chooseLeague(String? id) {
    final current = state.asData?.value;
    if (current == null ||
        current.saving ||
        (id != null && !current.leagues.any((l) => l.id == id))) {
      return;
    }
    _debounce?.cancel();
    _request++;
    state = AsyncData(
      current.copyWith(
        leagueId: id,
        clearLeague: id == null,
        clearClub: true,
        clubs: const [],
        query: '',
        searching: id != null,
      ),
    );
    if (id != null) unawaited(search(''));
  }

  void chooseClub(String? id) {
    final current = state.asData?.value;
    if (current == null || current.saving) return;
    if (id != null &&
        !current.clubs.any(
          (c) => c.id == id && c.leagueId == current.leagueId,
        )) {
      return;
    }
    state = AsyncData(current.copyWith(clubId: id, clearClub: id == null));
  }

  void visibility(bool value) {
    final current = state.asData?.value;
    if (current != null && !current.saving) {
      state = AsyncData(current.copyWith(showPublicly: value));
    }
  }

  void scheduleSearch(String query) {
    _debounce?.cancel();
    _request++;
    final current = state.asData?.value;
    if (current == null || current.saving) return;
    state = AsyncData(current.copyWith(query: query, searching: true));
    _debounce = Timer(const Duration(milliseconds: 350), () => search(query));
  }

  Future<void> search(String query) async {
    final current = state.asData?.value;
    if (current?.leagueId == null || current!.saving) return;
    final request = ++_request;
    final epoch = _epoch;
    state = AsyncData(current.copyWith(query: query, searching: true));
    try {
      final clubs = await ref
          .read(footballRepositoryProvider)
          .searchClubs(query: query, leagueId: current.leagueId);
      if (epoch == _epoch && request == _request) {
        state = AsyncData(
          state.requireValue.copyWith(clubs: clubs, searching: false),
        );
      }
    } on Object {
      if (epoch == _epoch && request == _request) {
        state = AsyncData(
          state.requireValue.copyWith(
            clubs: const [],
            searching: false,
            message: 'تعذر تحميل الأندية. أعد المحاولة.',
          ),
        );
      }
    }
  }

  Future<bool> save() async {
    final current = state.asData?.value;
    final user = ref.read(authControllerProvider).asData?.value;
    if (current == null ||
        !current.canSave ||
        current.saving ||
        user == null ||
        user.isGuest) {
      return false;
    }
    final epoch = _epoch;
    state = AsyncData(current.copyWith(saving: true));
    try {
      await ref
          .read(footballRepositoryProvider)
          .savePreferences(
            leagueId: current.leagueId,
            clubId: current.clubId,
            showPublicly: current.showPublicly,
          );
      if (epoch != _epoch ||
          ref.read(authControllerProvider).asData?.value?.id != user.id) {
        return false;
      }
      state = AsyncData(current.copyWith(message: 'حُفظت اختياراتك.'));
      ref.invalidate(playerProfileProvider);
      unawaited(
        ref
            .read(appServicesProvider)
            .analytics
            .log('football_preferences_saved')
            .catchError((_) {}),
      );
      return true;
    } on Object {
      if (epoch == _epoch) {
        state = AsyncData(
          current.copyWith(
            message: 'تعذر الحفظ. احتفظنا باختياراتك؛ أعد المحاولة.',
          ),
        );
      }
      return false;
    }
  }
}
