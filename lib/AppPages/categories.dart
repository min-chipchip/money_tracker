import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/category_sheet.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/state/providers.dart';

/// Settings → Categories: expense and income categories, tap to edit or
/// delete, plus "Add category". Changes show up immediately in the Home and
/// Deposit forms because they watch the same category streams.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  String _kind = 'expense';

  Future<void> _openSheet({Category? existing}) async {
    final message = await showCategorySheet(context, existing: existing, kind: _kind);
    if (message != null && mounted) showAppSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref
        .watch(_kind == 'income' ? incomeCategoriesProvider : expenseCategoriesProvider)
        .value;

    return FormPage(
      title: 'CATEGORIES',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.shopping_bag)),
                ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.savings)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: AppSpacing.section),
            if (categories == null)
              const Center(child: CircularProgressIndicator())
            else
              for (final c in categories)
                Card(
                  elevation: 2,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: ListTile(
                    onTap: () => _openSheet(existing: c),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: c.color != null ? Color(c.color!) : AppColors.primary,
                    ),
                    title: Text(c.name, style: AppText.strong),
                    trailing: const Icon(Icons.edit, color: AppColors.muted, size: 20),
                  ),
                ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: _kind == 'income' ? 'Add income category' : 'Add expense category',
              icon: Icons.add_circle,
              onPressed: _openSheet,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
