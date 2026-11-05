import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/AppAPI/receipt_reader.dart';
import 'package:money_tracker/AppAPI/receipt_scanner.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/currency_sheet.dart';
import 'package:money_tracker/AppItem/transaction_form.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';
import 'package:money_tracker/state/transaction_actions.dart';

const _scanner = ReceiptScanner();

/// Turns what the AI read into values for the transaction form.
@visibleForTesting
TransactionPrefill prefillFromReading(
  ReceiptReading reading, {
  required List<Category> categories,
  required Set<String> knownCurrencies,
}) {
  final category = categories.where((c) => c.name.toLowerCase() == reading.category?.toLowerCase()).firstOrNull;
  // A total in a currency the app doesn't have can't be entered as-is:
  // labelling 181,440 VND as HKD would record a huge wrong amount. Leave the
  // amount for the user to type instead.
  final currencyKnown = reading.currency == null || knownCurrencies.contains(reading.currency);
  return TransactionPrefill(
    amount: currencyKnown ? reading.total : null,
    currency: reading.currency,
    date: reading.date,
    categoryId: category?.id,
    note: reading.merchant,
  );
}

/// Receipt tab: a "Take New Receipt" button that opens the camera scanner,
/// and below it the history of receipts taken so far.
///
/// Tapping a receipt opens it; "Read with AI" there turns it into a
/// pre-filled transaction form.
class MyReceiptForm extends StatefulWidget {
  const MyReceiptForm({super.key});

  @override
  State<MyReceiptForm> createState() => _MyReceiptFormState();
}

class _MyReceiptFormState extends State<MyReceiptForm> {
  late Future<List<File>> _history = _scanner.history();
  bool _busy = false;

  void _reload() => setState(() => _history = _scanner.history());

  Future<void> _scan(ScannerSource source) async {
    setState(() => _busy = true);
    try {
      final file = await _scanner.scan(source: source);
      if (file != null) {
        _reload();
        if (mounted) showAppSnackBar(context, 'Receipt saved!');
      }
    } on PlatformException catch (e) {
      // Usually: camera permission denied, or no camera (e.g. the simulator).
      if (mounted) {
        showAppSnackBar(context, 'Could not open the scanner: ${e.message ?? e.code}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(File receipt) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReceiptViewer(receipt: receipt)),
    );
    if (deleted == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 25, AppSpacing.page, 0),
            sliver: SliverList.list(
              children: [
                const Text('Receipts', style: AppText.headline),
                const Text('SCAN TO ADD', style: AppText.bodyMuted),
                const SizedBox(height: 20),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  PrimaryButton(
                    label: 'Take New Receipt',
                    icon: Icons.photo_camera,
                    onPressed: () => _scan(ScannerSource.camera),
                  ),
                  TextButton.icon(
                    onPressed: () => _scan(ScannerSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Import from Photos'),
                  ),
                ],
                const SizedBox(height: 10),
                const Text('History', style: AppText.title),
                const SizedBox(height: 10),
              ],
            ),
          ),
          FutureBuilder<List<File>>(
            future: _history,
            builder: (context, snap) {
              final receipts = snap.data;
              if (receipts == null) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (receipts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: EmptyState(
                      icon: Icons.receipt_long,
                      title: 'No receipts yet',
                      message: 'Lay the receipt flat on a dark surface with good light, then tap Take New Receipt.',
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 30),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: AppSpacing.gap,
                    crossAxisSpacing: AppSpacing.gap,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: receipts.length,
                  itemBuilder: (context, i) => _ReceiptTile(
                    receipt: receipts[i],
                    onTap: () => _open(receipts[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _formatTaken(File f) => DateFormat('d MMM yyyy, HH:mm').format(f.lastModifiedSync());

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.onTap});

  final File receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // cacheWidth keeps memory low: thumbnails don't need full resolution.
              child: Image.file(receipt, fit: BoxFit.cover, cacheWidth: 400),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_formatTaken(receipt), style: AppText.caption, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of one receipt, with "Read with AI" to turn
/// it into a transaction. Pops `true` if the receipt was deleted.
class ReceiptViewer extends ConsumerStatefulWidget {
  const ReceiptViewer({super.key, required this.receipt});

  final File receipt;

  @override
  ConsumerState<ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends ConsumerState<ReceiptViewer> {
  bool _reading = false;

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: const Text('This removes the photo from the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _scanner.delete(widget.receipt);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _readWithAi() async {
    if (!GeminiReceiptReader.isConfigured) {
      showAppSnackBar(context, 'AI is not set up: run the app with --dart-define=GEMINI_API_KEY=...', isError: true);
      return;
    }
    setState(() => _reading = true);
    try {
      // Read once from the repositories: a provider nobody is watching is
      // paused in Riverpod 3, so awaiting its .future here would hang.
      final categories = await ref.read(categoryRepositoryProvider).watchAll(kind: 'expense').first;
      final fallbackCurrency = await ref.read(settingsRepositoryProvider).watchMainCurrency().first;
      final knownCurrencies = {
        for (final c in await ref.read(settingsRepositoryProvider).watchCurrencies().first) c.code,
      };
      final reading = await const GeminiReceiptReader().read(
        widget.receipt,
        categories: [for (final c in categories) c.name],
        fallbackCurrency: fallbackCurrency,
      );

      final prefill = prefillFromReading(reading, categories: categories, knownCurrencies: knownCurrencies);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptReviewPage(receipt: widget.receipt, reading: reading, prefill: prefill),
        ),
      );
    } on ReceiptReadException catch (e) {
      debugPrint('Receipt read failed: ${e.message}');
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatTaken(widget.receipt), style: AppText.strong),
        actions: [
          IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.file(widget.receipt)),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, 10),
        child: _reading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                    SizedBox(width: 12),
                    Text('Reading receipt...', style: AppText.bodyMuted),
                  ],
                ),
              )
            : PrimaryButton(label: 'Read with AI', icon: Icons.auto_awesome, onPressed: _readWithAi),
      ),
    );
  }
}

/// Shows what the AI read next to a pre-filled transaction form. Nothing is
/// saved until the user checks the values and taps Save.
class ReceiptReviewPage extends ConsumerWidget {
  const ReceiptReviewPage({super.key, required this.receipt, required this.reading, required this.prefill});

  final File receipt;
  final ReceiptReading reading;
  final TransactionPrefill prefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = reading.items;
    final known = ref.watch(currenciesProvider).value?.map((c) => c.code).toSet();
    final unknownCurrency = reading.currency != null && known != null && !known.contains(reading.currency);
    // Once the receipt's currency has been added (with the button below),
    // fill in the amount that was left blank.
    final currencyNowKnown = reading.currency != null && known != null && known.contains(reading.currency);
    final effectivePrefill = prefill.amount == null && currencyNowKnown && reading.total != null
        ? TransactionPrefill(
            amount: reading.total,
            currency: reading.currency,
            date: prefill.date,
            categoryId: prefill.categoryId,
            note: prefill.note,
          )
        : prefill;
    return Scaffold(
      appBar: AppBar(title: const Text('Check & Save', style: AppText.strong)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: Image.file(receipt, width: 90, height: 120, fit: BoxFit.cover, cacheWidth: 300),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reading.merchant ?? 'Unknown shop', style: AppText.title),
                        const SizedBox(height: 4),
                        const Text('Read by AI. Check the values before saving.', style: AppText.caption),
                        const SizedBox(height: 8),
                        for (final it in items.take(6))
                          Row(
                            children: [
                              Expanded(child: Text(it.name, style: AppText.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(_plain(it.amount), style: AppText.label),
                            ],
                          ),
                        if (items.length > 6) Text('+ ${items.length - 6} more', style: AppText.caption),
                        if (unknownCurrency) ...[
                          const SizedBox(height: 8),
                          Text(
                            'This receipt is in ${reading.currency}, which is not set up in the app, '
                            'so the amount is left blank. Add ${reading.currency} or enter the amount '
                            'in your account currency.',
                            style: AppText.label.copyWith(color: AppColors.error),
                          ),
                          TextButton.icon(
                            onPressed: () => showCurrencySheet(context, code: reading.currency),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text('Add ${reading.currency}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TransactionForm(
              // A new key restarts the form when the prefill changes (after
              // the receipt's currency is added), so the amount appears.
              key: ValueKey(identical(effectivePrefill, prefill)),
              prefill: effectivePrefill,
              submitLabel: 'Save Transaction',
              onSubmit: (draft) async {
                await ref.read(transactionActionsProvider).save(draft);
                if (!context.mounted) return;
                showAppSnackBar(context, 'Transaction saved!');
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 78000.0 -> "78,000"; 12.5 -> "12.5".
String _plain(double v) => v == v.roundToDouble() ? NumberFormat.decimalPattern().format(v) : v.toString();
