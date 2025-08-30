import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/repositories/impl/ledger_repository_impl.dart';
import 'package:ledger_master/repositories/ledger_repository.dart';

// repository provider (can override in tests)
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  // Use default implementation that uses the app local DB
  return LedgerRepositoryImpl();
});

// State for journal list
class JournalListState {
  final bool loading;
  final List<LedgerEntry> entries;
  final String? error;
  final int page;
  final bool hasMore;

  JournalListState({
    this.loading = false,
    this.entries = const [],
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  JournalListState copyWith({
    bool? loading,
    List<LedgerEntry>? entries,
    String? error,
    int? page,
    bool? hasMore,
  }) => JournalListState(
    loading: loading ?? this.loading,
    entries: entries ?? this.entries,
    error: error,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
  );
}

class JournalListNotifier extends StateNotifier<JournalListState> {
  final LedgerRepository repo;
  JournalListNotifier({required this.repo}) : super(JournalListState());

  static const int pageSize = 25;

  Future<void> loadInitial() async {
    state = state.copyWith(loading: true, error: null, page: 0);
    try {
      final entries = await repo.fetchEntries(limit: pageSize, offset: 0);
      state = state.copyWith(
        loading: false,
        entries: entries,
        page: 0,
        hasMore: entries.length >= pageSize,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    try {
      final nextOffset = (state.page + 1) * pageSize;
      final entries = await repo.fetchEntries(
        limit: pageSize,
        offset: nextOffset,
      );
      final combined = [...state.entries, ...entries];
      state = state.copyWith(
        loading: false,
        entries: combined,
        page: state.page + 1,
        hasMore: entries.length >= pageSize,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> createEntry(LedgerEntry entry) async {
    await repo.createJournalEntry(entry);
    await loadInitial();
  }

  Future<void> updateEntry(LedgerEntry entry) async {
    await repo.updateJournalEntry(entry);
    await loadInitial();
  }

  Future<void> deleteEntry(String id) async {
    await repo.deleteEntry(id);
    await loadInitial();
  }
}

// provider for notifier
final journalListNotifierProvider =
    StateNotifierProvider<JournalListNotifier, JournalListState>((ref) {
      final repo = ref.watch(ledgerRepositoryProvider);
      return JournalListNotifier(repo: repo);
    });
