import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/AppItem/app_theme.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';
import 'package:money_tracker/AppItem/input_box.dart';
import 'package:money_tracker/data/db/app_database.dart';
import 'package:money_tracker/data/repositories/category_repository.dart';
import 'package:money_tracker/state/providers.dart';

/// Opens the category sheet: "New category" (of [kind]) when [existing] is
/// null, otherwise "Edit category" with a Delete button.
///
/// Returns a short message for a snackbar, or null if nothing changed.
Future<String?> showCategorySheet(
  BuildContext context, {
  Category? existing,
  String kind = 'expense',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.boxRadius)),
    ),
    builder: (_) => _CategorySheet(existing: existing, kind: existing?.kind ?? kind),
  );
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.existing, required this.kind});

  final Category? existing;
  final String kind;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late final TextEditingController _nameController;
  late int _color;
  String? _nameError;
  String? _deleteError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? AppColors.categoryChoices.first.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the category a name');
      return;
    }
    final repo = ref.read(categoryRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(widget.existing!.id, name: name, color: _color);
      } else {
        await repo.add(name: name, kind: widget.kind, color: _color);
      }
    } on CategoryNameTaken catch (e) {
      setState(() => _nameError = e.toString());
      return;
    }
    if (mounted) Navigator.pop(context, _isEdit ? 'Saved "$name"' : 'Added "$name"');
  }

  Future<void> _delete() async {
    final category = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text('The category will disappear from your lists.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    } on CategoryDeleteBlocked catch (e) {
      setState(() => _deleteError = e.reason);
      return;
    }
    if (mounted) Navigator.pop(context, 'Deleted "${category.name}"');
  }

  @override
  Widget build(BuildContext context) {
    final kindLabel = widget.kind == 'income' ? 'income' : 'expense';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 25, AppSpacing.page, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEdit ? 'Edit category' : 'New $kindLabel category', style: AppText.headline),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'NAME',
              icon: Icons.edit,
              child: TextField(
                controller: _nameController,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: AppText.title,
                decoration: InputDecoration(
                  hintText: widget.kind == 'income' ? 'e.g. Bonus' : 'e.g. Transport',
                  border: InputBorder.none,
                  errorText: _nameError,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            InputBox(
              label: 'COLOR',
              icon: Icons.palette,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in AppColors.categoryChoices)
                      GestureDetector(
                        onTap: () => setState(() => _color = color.toARGB32()),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color.toARGB32() ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _color == color.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Create category',
              icon: _isEdit ? Icons.check_circle : Icons.add_circle,
              onPressed: _save,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete category', style: AppText.strong),
              ),
              if (_deleteError != null)
                Text(
                  _deleteError!,
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: AppColors.error),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
