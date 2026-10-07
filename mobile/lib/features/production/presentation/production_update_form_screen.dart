import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/widgets.dart';
import '../application/production_controller.dart';
import '../domain/production_update.dart';

/// Document 7 (#53): daily production-update entry — one row per line stage.
class ProductionUpdateFormScreen extends ConsumerStatefulWidget {
  const ProductionUpdateFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ProductionUpdateFormScreen> createState() => _ProductionUpdateFormScreenState();
}

class _ProductionUpdateFormScreenState extends ConsumerState<ProductionUpdateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _updateDate = DateTime.now();
  final _cuttingController = TextEditingController(text: '0');
  final _sewingController = TextEditingController(text: '0');
  final _finishingController = TextEditingController(text: '0');
  final _packingController = TextEditingController(text: '0');
  final _rejectionController = TextEditingController(text: '0');
  final _alterationController = TextEditingController(text: '0');

  @override
  void dispose() {
    _cuttingController.dispose();
    _sewingController.dispose();
    _finishingController.dispose();
    _packingController.dispose();
    _rejectionController.dispose();
    _alterationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = ProductionUpdateDraft(
      updateDate: toApiDate(_updateDate)!,
      cuttingQty: int.parse(_cuttingController.text.trim()),
      sewingQty: int.parse(_sewingController.text.trim()),
      finishingQty: int.parse(_finishingController.text.trim()),
      packingQty: int.parse(_packingController.text.trim()),
      rejectionQty: int.parse(_rejectionController.text.trim()),
      alterationQty: int.parse(_alterationController.text.trim()),
    );
    ref.read(productionUpdateFormControllerProvider.notifier).submit(widget.orderId, draft);
  }

  Widget _qtyField(TextEditingController controller, String label, IconData icon, bool isSubmitting,
          {bool last = false}) =>
      TextFormField(
        controller: controller,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: last ? (_) => _submit() : null,
        enabled: !isSubmitting,
        keyboardType: TextInputType.number,
        inputFormatters: NumberInput.integer,
        // Select-all on tap so overwriting the default 0 is one keystroke.
        onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixText: 'pcs'),
        validator: Validators.positiveInt(allowZero: true, what: label),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(productionUpdateFormControllerProvider, (previous, next) {
      if (next is ProductionUpdateFormSuccess) {
        showSuccessSnack(context, 'Production update saved');
        Navigator.of(context).pop(true);
      } else if (next is ProductionUpdateFormFailed) {
        showErrorSnack(context, next.failure.message);
      }
    });
    final formState = ref.watch(productionUpdateFormControllerProvider);
    final isSubmitting = formState is ProductionUpdateFormSubmitting;

    Widget pair(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: b),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Production Update')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SectionHeader('Date', icon: Icons.event_rounded, accentColor: AppModules.production.color),
            AppCard(
              child: DateField(
                label: 'Update date',
                required: true,
                enabled: !isSubmitting,
                value: _updateDate,
                lastDate: DateTime.now(),
                onChanged: (d) => setState(() => _updateDate = d ?? _updateDate),
              ),
            ),
            SectionHeader("Today's output",
                subtitle: 'Pieces completed at each stage today (not cumulative)',
                icon: Icons.precision_manufacturing_rounded,
                accentColor: AppModules.production.color),
            AppCard(
              accentColor: AppModules.production.color,
              child: Column(children: [
                pair(
                  _qtyField(_cuttingController, 'Cutting', Icons.content_cut_rounded, isSubmitting),
                  _qtyField(_sewingController, 'Sewing', Icons.dry_cleaning_outlined, isSubmitting),
                ),
                pair(
                  _qtyField(_finishingController, 'Finishing', Icons.iron_outlined, isSubmitting),
                  _qtyField(_packingController, 'Packing', Icons.inventory_2_outlined, isSubmitting),
                ),
              ]),
            ),
            const SectionHeader('Quality loss', icon: Icons.report_gmailerrorred_rounded, accentColor: AppColors.danger),
            AppCard(
              accentColor: AppColors.danger,
              child: pair(
                _qtyField(_rejectionController, 'Rejection', Icons.block_rounded, isSubmitting),
                _qtyField(_alterationController, 'Alteration', Icons.build_outlined, isSubmitting, last: true),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Save update', icon: Icons.check_rounded, loading: isSubmitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
