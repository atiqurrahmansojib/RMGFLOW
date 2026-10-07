import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../common/widgets/widgets.dart';
import '../application/report_controller.dart';
import '../data/report_file_saver.dart';
import '../domain/report.dart';
import 'widgets/report_category_style.dart';
import 'widgets/report_data_view.dart';

final _apiDate = DateFormat('yyyy-MM-dd');
final _displayDate = DateFormat('dd MMM yyyy');
final _generatedAt = DateFormat('dd MMM yyyy, HH:mm');

/// Document 14: one report — filter form, summary cards, data table, and
/// CSV/PDF download. Downloads always use the filters of the result on
/// screen, so the file matches what the user is looking at.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.definition});

  final ReportDefinition definition;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  /// Current form values, already in API form (yyyy-MM-dd, numeric ids).
  final Map<String, String> _values = {};

  /// Filters of the last run — what downloads and pull-to-refresh use.
  Map<String, String>? _applied;

  final Map<String, TextEditingController> _textControllers = {};
  bool _showRequiredErrors = false;

  /// Bumped on Clear so dropdowns (which only read initialValue once) rebuild.
  int _formGeneration = 0;

  ReportDefinition get _def => widget.definition;
  String get _code => _def.code;

  @override
  void initState() {
    super.initState();
    for (final f in _def.filters.where((f) => f.type == ReportFilterType.text)) {
      _textControllers[f.key] = TextEditingController();
    }
    if (_missingRequired.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<ReportFilterDefinition> get _missingRequired =>
      _def.filters.where((f) => f.required && (_values[f.key]?.isEmpty ?? true)).toList();

  Future<void> _apply() async {
    FocusScope.of(context).unfocus();
    if (_missingRequired.isNotEmpty) {
      setState(() => _showRequiredErrors = true);
      return;
    }
    final filters = Map<String, String>.from(_values)..removeWhere((_, v) => v.isEmpty);
    setState(() {
      _showRequiredErrors = false;
      _applied = filters;
    });
    await ref.read(reportResultControllerProvider(_code).notifier).run(filters);
  }

  void _reset() {
    setState(() {
      _values.clear();
      for (final c in _textControllers.values) {
        c.clear();
      }
      _showRequiredErrors = false;
      _formGeneration++;
    });
    if (_missingRequired.isEmpty) _apply();
  }

  Future<void> _refresh() async {
    final applied = _applied;
    if (applied == null) return _apply();
    await ref.read(reportResultControllerProvider(_code).notifier).run(applied);
  }

  void _download(ReportExportFormat format) {
    final applied = _applied;
    if (applied == null) return;
    ref.read(reportExportControllerProvider(_code).notifier).download(format, applied);
  }

  @override
  Widget build(BuildContext context) {
    final resultState = ref.watch(reportResultControllerProvider(_code));
    final exportState = ref.watch(reportExportControllerProvider(_code));

    ref.listen<ReportExportState>(reportExportControllerProvider(_code), (_, next) {
      if (next is ReportExportSuccess) {
        _showSavedSnackBar(next.file);
        ref.read(reportExportControllerProvider(_code).notifier).reset();
      } else if (next is ReportExportFailed) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Download failed: ${next.failure.message}')));
        ref.read(reportExportControllerProvider(_code).notifier).reset();
      }
    });

    final canDownload = resultState is ReportResultLoaded && exportState is! ReportExportInProgress;

    return Scaffold(
      appBar: AppBar(
        title: Text(_def.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: resultState is ReportResultLoading ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            GradientHeader.module(
              AppModules.reports,
              eyebrow: _def.category.toUpperCase(),
              title: _def.name,
              subtitle: _def.description == null || _def.description!.isEmpty ? null : _def.description,
              trailing: Icon(reportCategoryModule(_def.category).icon, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_def.filters.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildFilterPanel(context),
                  ],
                  SectionHeader(
                    'Results',
                    icon: Icons.insights_rounded,
                    accentColor: AppModules.reports.color,
                    count: resultState is ReportResultLoaded ? resultState.result.rows.length : null,
                  ),
                  _buildResult(context, resultState),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              for (final format in ReportExportFormat.values) ...[
                if (format != ReportExportFormat.values.first) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Download ${format.label}',
                    icon: format == ReportExportFormat.pdf ? Icons.picture_as_pdf_outlined : Icons.table_view_outlined,
                    variant: format == ReportExportFormat.values.first ? ButtonVariant.filled : ButtonVariant.tonal,
                    loading: exportState is ReportExportInProgress && exportState.format == format,
                    onPressed: canDownload ? () => _download(format) : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, ReportResultState state) {
    switch (state) {
      case ReportResultIdle():
        return EmptyStateView(
          icon: Icons.tune_rounded,
          color: AppModules.reports.color,
          title: 'Ready when you are',
          message: 'Fill in the required filters (*) and tap Apply to run this report.',
        );
      case ReportResultLoading():
        return const SizedBox(height: 240, child: LoadingView());
      case ReportResultError(:final failure):
        return SizedBox(height: 320, child: ErrorStateView(failure: failure, onRetry: _refresh));
      case ReportResultLoaded(:final result):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result.generatedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Generated ${_generatedAt.format(result.generatedAt!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ReportDataView(result: result),
          ],
        );
    }
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  Widget _buildFilterPanel(BuildContext context) {
    final activeCount = _values.values.where((v) => v.isNotEmpty).length;
    final hasRequired = _def.filters.any((f) => f.required);
    final accent = AppModules.reports.color;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: accent,
        leading: Icon(Icons.filter_list_rounded, color: accent),
        title: Text(activeCount == 0 ? 'Filters' : 'Filters ($activeCount active)'),
        initiallyExpanded: hasRequired,
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          for (final filter in _def.filters)
            Padding(
              key: ValueKey('${filter.key}-$_formGeneration'),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _buildFilterField(context, filter),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              TextButton.icon(
                onPressed: activeCount == 0 ? null : _reset,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Apply',
                icon: Icons.check_rounded,
                expand: false,
                onPressed: _apply,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelFor(ReportFilterDefinition f) => f.required ? '${f.label} *' : f.label;

  String? _errorFor(ReportFilterDefinition f) =>
      _showRequiredErrors && f.required && (_values[f.key]?.isEmpty ?? true) ? 'Required' : null;

  void _set(String key, String? value) => setState(() {
        if (value == null || value.isEmpty) {
          _values.remove(key);
        } else {
          _values[key] = value;
        }
      });

  Widget _buildFilterField(BuildContext context, ReportFilterDefinition filter) {
    switch (filter.type) {
      case ReportFilterType.date:
        return _DateFilterField(
          label: _labelFor(filter),
          errorText: _errorFor(filter),
          value: _values[filter.key],
          onChanged: (v) => _set(filter.key, v),
        );
      case ReportFilterType.status:
        return DropdownButtonFormField<String?>(
          initialValue: _values[filter.key],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _labelFor(filter),
            errorText: _errorFor(filter),
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Any')),
            for (final option in filter.options)
              DropdownMenuItem<String?>(value: option, child: Text(_humanize(option))),
          ],
          onChanged: (v) => _set(filter.key, v),
        );
      case ReportFilterType.buyer:
      case ReportFilterType.factory:
        final provider =
            filter.type == ReportFilterType.buyer ? reportBuyerChoicesProvider : reportFactoryChoicesProvider;
        return _ChoiceFilterField(
          label: _labelFor(filter),
          errorText: _errorFor(filter),
          choices: ref.watch(provider),
          value: _values[filter.key],
          onChanged: (v) => _set(filter.key, v),
          onRetry: () => ref.invalidate(provider),
        );
      case ReportFilterType.text:
        return TextField(
          controller: _textControllers[filter.key],
          decoration: InputDecoration(
            labelText: _labelFor(filter),
            errorText: _errorFor(filter),
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) => _set(filter.key, v.trim()),
          onSubmitted: (_) => _apply(),
        );
    }
  }

  // -------------------------------------------------------------------------
  // Download result
  // -------------------------------------------------------------------------

  void _showSavedSnackBar(SavedReportFile file) {
    final messenger = ScaffoldMessenger.of(context);
    final where = file.publicLocation != null
        ? 'Saved to ${file.publicLocation}'
        : 'Downloaded ${file.fileName} — use Share to save or send it';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            Expanded(child: Text(where)),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                _share(file);
              },
              child: const Text('SHARE'),
            ),
          ],
        ),
        action: SnackBarAction(label: 'OPEN', onPressed: () => _open(file)),
      ));
  }

  Future<void> _open(SavedReportFile file) async {
    final result = await OpenFilex.open(file.localPath, type: file.mimeType);
    if (!mounted || result.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.type == ResultType.noAppToOpen
          ? 'No app installed can open ${file.mimeType == 'application/pdf' ? 'PDF' : 'CSV'} files. Try Share instead.'
          : 'Could not open the file: ${result.message}'),
    ));
  }

  Future<void> _share(SavedReportFile file) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.localPath, mimeType: file.mimeType)],
      subject: _def.name,
    ));
  }
}

/// "IN_PRODUCTION" -> "In production".
String _humanize(String value) {
  if (value.isEmpty) return value;
  final words = value.replaceAll('_', ' ').toLowerCase();
  return words[0].toUpperCase() + words.substring(1);
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({required this.label, required this.value, required this.onChanged, this.errorText});

  final String label;
  final String? value;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = value == null ? null : DateTime.tryParse(value!);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: parsed ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onChanged(_apiDate.format(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: parsed == null
              ? null
              : IconButton(icon: const Icon(Icons.clear), tooltip: 'Clear date', onPressed: () => onChanged(null)),
        ),
        isEmpty: parsed == null,
        child: parsed == null ? null : Text(_displayDate.format(parsed)),
      ),
    );
  }
}

class _ChoiceFilterField extends StatelessWidget {
  const _ChoiceFilterField({
    required this.label,
    required this.choices,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    this.errorText,
  });

  final String label;
  final AsyncValue<List<ReportChoice>> choices;
  final String? value;
  final String? errorText;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return choices.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: const LinearProgressIndicator(),
      ),
      error: (_, __) => InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errorText),
        child: Row(
          children: [
            const Expanded(child: Text('Could not load choices')),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      data: (list) {
        final selected = value == null ? null : int.tryParse(value!);
        return DropdownButtonFormField<int?>(
          // Drop a stale selection that is no longer in the list.
          initialValue: list.any((c) => c.id == selected) ? selected : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, errorText: errorText, border: const OutlineInputBorder()),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All')),
            for (final c in list)
              DropdownMenuItem<int?>(value: c.id, child: Text(c.label, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => onChanged(v?.toString()),
        );
      },
    );
  }
}
