import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/providers/ledger_providers.dart';
import 'package:ledger_master/screens/journal_entry_screen.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.read(journalListNotifierProvider.notifier).loadInitial();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        ref.read(journalListNotifierProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalListNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // open journal entry form
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
              );
              // refresh after return
              ref.read(journalListNotifierProvider.notifier).loadInitial();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(journalListNotifierProvider.notifier).loadInitial();
        },
        child: state.loading && state.entries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                controller: _scroll,
                itemCount: state.entries.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  if (idx >= state.entries.length) {
                    // loading indicator at bottom
                    if (state.loading) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }
                  final LedgerEntry e = state.entries[idx];
                  return ListTile(
                    title: Text(e.description),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(e.date)} — Debit: ${e.totalDebit().toStringAsFixed(2)}  Credit: ${e.totalCredit().toStringAsFixed(2)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JournalEntryScreen(entry: e),
                            ),
                          );
                          ref
                              .read(journalListNotifierProvider.notifier)
                              .loadInitial();
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete entry?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok ?? false) {
                            await ref
                                .read(journalListNotifierProvider.notifier)
                                .deleteEntry(e.id);
                          }
                        } else if (v == 'view') {
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Journal: ${e.description}'),
                              content: SizedBox(
                                width: 400,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${DateFormat.yMMMd().format(e.date)}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Lines:'),
                                    ...e.lines.map(
                                      (l) => ListTile(
                                        dense: true,
                                        title: Text(l.accountId),
                                        subtitle: Text(l.narration ?? ''),
                                        trailing: Text(
                                          'D:${l.debit.toStringAsFixed(2)} C:${l.credit.toStringAsFixed(2)}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Balanced: ${e.isBalanced() ? "Yes" : "No"}',
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'view', child: Text('View')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () async {
                      // quick view
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(e.description),
                          content: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: e.lines
                                  .map(
                                    (l) => ListTile(
                                      title: Text(l.accountId),
                                      subtitle: Text(l.narration ?? ''),
                                      trailing: Text(
                                        'D:${l.debit.toStringAsFixed(2)} C:${l.credit.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
