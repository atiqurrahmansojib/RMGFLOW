import 'package:flutter/material.dart';

/// Design tokens — "Indigo & Thread".
///
/// Palette rooted in the garments trade: indigo dye (denim / jamdani), the teal
/// of factory-floor signage, marigold thread and a coral swatch accent. Every
/// colour used outside the theme should come from here, never inline hex.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color indigo = Color(0xFF3B3FB6); // primary
  static const Color indigoDeep = Color(0xFF262A85); // gradients, pressed
  static const Color indigoSoft = Color(0xFFE3E4FB); // primary container
  static const Color indigoNight = Color(0xFFA9ADFF); // primary on dark

  static const Color teal = Color(0xFF0E8C7F); // secondary
  static const Color tealSoft = Color(0xFFCFF1EC);
  static const Color tealNight = Color(0xFF5FD4C4);

  static const Color coral = Color(0xFFE8505B); // tertiary / highlight
  static const Color coralSoft = Color(0xFFFFE0E2);
  static const Color coralNight = Color(0xFFFF8A92);

  static const Color marigold = Color(0xFFF4A62A); // accent (KPIs, badges)
  static const Color marigoldSoft = Color(0xFFFFEDCC);

  // ── Neutrals (cool, slightly blue-tinted) ──────────────────────────────
  static const Color ink = Color(0xFF1A1C2E); // text on light
  static const Color inkMuted = Color(0xFF5B5F78); // secondary text
  static const Color outline = Color(0xFFC7C9DA);
  static const Color outlineSoft = Color(0xFFE4E5EF);
  static const Color canvas = Color(0xFFF5F6FB); // scaffold light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFEEF0F8); // filled inputs, tonal

  static const Color canvasNight = Color(0xFF0F1020);
  static const Color surfaceNight = Color(0xFF181A2E);
  static const Color surfaceNightHigh = Color(0xFF232540);
  static const Color inkNight = Color(0xFFE6E7F5);
  static const Color inkNightMuted = Color(0xFFA3A6C2);
  static const Color outlineNight = Color(0xFF3A3D5C);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFE08A00);
  static const Color danger = Color(0xFFD63A3A);
  static const Color info = Color(0xFF2F7CE0);
  static const Color neutral = Color(0xFF6E7391);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigoDeep, indigo, Color(0xFF5A4FCF)],
  );

  /// Two-stop gradient from an accent colour — used by tiles, headers, KPIs.
  static LinearGradient accentGradient(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, Color.lerp(c, const Color(0xFF1A1C2E), 0.28)!],
      );

  /// Soft shadow tinted with [tint] (defaults to indigo) — never pure grey.
  static List<BoxShadow> softShadow([Color tint = indigo, double strength = 1]) => [
        BoxShadow(color: tint.withValues(alpha: 0.10 * strength), blurRadius: 18, offset: const Offset(0, 6)),
        BoxShadow(color: tint.withValues(alpha: 0.05 * strength), blurRadius: 4, offset: const Offset(0, 1)),
      ];
}

/// Semantic tone of a status — drives chip colour.
enum StatusTone {
  success(AppColors.success),
  warning(AppColors.warning),
  danger(AppColors.danger),
  info(AppColors.info),
  progress(AppColors.indigo),
  neutral(AppColors.neutral);

  const StatusTone(this.color);
  final Color color;

  /// Foreground (text/icon) colour readable on [background] for [brightness].
  Color foreground(Brightness brightness) =>
      brightness == Brightness.dark ? Color.lerp(color, Colors.white, 0.45)! : Color.lerp(color, Colors.black, 0.18)!;

  /// Tinted chip/badge background for [brightness].
  Color background(Brightness brightness) =>
      color.withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.12);
}

/// Resolved look of a status string: tone, readable label, icon.
@immutable
class StatusStyle {
  const StatusStyle(this.tone, this.label, this.icon);
  final StatusTone tone;
  final String label;
  final IconData icon;
  Color get color => tone.color;
}

/// Maps any status string (API `IN_PROGRESS`, enum `inProgress`, `in progress`,
/// `in-progress`) to a [StatusStyle]. Unknown statuses fall back to neutral
/// with a humanised label, so it is always safe to call.
class AppStatus {
  AppStatus._();

  static const Map<String, (StatusTone, IconData)> _map = {
    // neutral / not started
    'draft': (StatusTone.neutral, Icons.edit_note_rounded),
    'requested': (StatusTone.info, Icons.outbox_rounded),
    'upcoming': (StatusTone.neutral, Icons.event_rounded),
    'superseded': (StatusTone.neutral, Icons.layers_clear_rounded),
    'expired': (StatusTone.neutral, Icons.timer_off_rounded),
    'withdrawn': (StatusTone.neutral, Icons.undo_rounded),
    'hold': (StatusTone.warning, Icons.pause_circle_rounded),
    'onhold': (StatusTone.warning, Icons.pause_circle_rounded),
    'closed': (StatusTone.neutral, Icons.lock_rounded),
    'cancelled': (StatusTone.neutral, Icons.block_rounded),
    'canceled': (StatusTone.neutral, Icons.block_rounded),
    'lost': (StatusTone.neutral, Icons.trending_down_rounded),
    // waiting
    'pending': (StatusTone.warning, Icons.hourglass_top_rounded),
    'submitted': (StatusTone.info, Icons.send_rounded),
    'resubmitted': (StatusTone.info, Icons.send_rounded),
    'sent': (StatusTone.info, Icons.send_rounded),
    'quoted': (StatusTone.info, Icons.request_quote_rounded),
    'negotiating': (StatusTone.warning, Icons.forum_rounded),
    'underreview': (StatusTone.warning, Icons.manage_search_rounded),
    'returned': (StatusTone.warning, Icons.keyboard_return_rounded),
    'open': (StatusTone.info, Icons.radio_button_unchecked_rounded),
    'booked': (StatusTone.info, Icons.event_available_rounded),
    'confirmed': (StatusTone.info, Icons.verified_rounded),
    'duetoday': (StatusTone.warning, Icons.today_rounded),
    // moving
    'inprogress': (StatusTone.progress, Icons.autorenew_rounded),
    'intransit': (StatusTone.progress, Icons.local_shipping_rounded),
    'ontrack': (StatusTone.success, Icons.trending_flat_rounded),
    'partial': (StatusTone.warning, Icons.incomplete_circle_rounded),
    'partiallypaid': (StatusTone.warning, Icons.incomplete_circle_rounded),
    'partiallyshipped': (StatusTone.progress, Icons.incomplete_circle_rounded),
    // good
    'approved': (StatusTone.success, Icons.check_circle_rounded),
    'completed': (StatusTone.success, Icons.task_alt_rounded),
    'done': (StatusTone.success, Icons.task_alt_rounded),
    'resolved': (StatusTone.success, Icons.task_alt_rounded),
    'won': (StatusTone.success, Icons.emoji_events_rounded),
    'pass': (StatusTone.success, Icons.verified_rounded),
    'passed': (StatusTone.success, Icons.verified_rounded),
    'shipped': (StatusTone.success, Icons.directions_boat_rounded),
    'delivered': (StatusTone.success, Icons.inventory_rounded),
    'paid': (StatusTone.success, Icons.paid_rounded),
    'active': (StatusTone.success, Icons.bolt_rounded),
    'valid': (StatusTone.success, Icons.verified_rounded),
    'selected': (StatusTone.success, Icons.check_circle_rounded),
    'received': (StatusTone.success, Icons.paid_rounded),
    'candidate': (StatusTone.info, Icons.radio_button_unchecked_rounded),
    // bad
    'rejected': (StatusTone.danger, Icons.cancel_rounded),
    'fail': (StatusTone.danger, Icons.error_rounded),
    'failed': (StatusTone.danger, Icons.error_rounded),
    'delayed': (StatusTone.danger, Icons.schedule_rounded),
    'overdue': (StatusTone.danger, Icons.alarm_rounded),
    'criticaldelay': (StatusTone.danger, Icons.warning_rounded),
    'blocked': (StatusTone.danger, Icons.do_not_disturb_on_rounded),
    'unpaid': (StatusTone.danger, Icons.money_off_rounded),
    'inactive': (StatusTone.neutral, Icons.power_settings_new_rounded),
  };

  static String _key(String raw) => raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// `IN_PROGRESS` / `inProgress` / `in progress` → `In progress`.
  static String humanize(String raw) {
    final spaced = raw
        .trim()
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[_\-\s]+'), ' ')
        .toLowerCase();
    if (spaced.isEmpty) return '—';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static StatusStyle resolve(String status) {
    final hit = _map[_key(status)];
    final label = humanize(status);
    if (hit == null) return StatusStyle(StatusTone.neutral, label, Icons.circle_outlined);
    return StatusStyle(hit.$1, label, hit.$2);
  }

  static Color color(String status) => resolve(status).color;
  static StatusTone tone(String status) => resolve(status).tone;
}

/// One operational module (Home grid tile, screen accent, header gradient).
@immutable
class AppModule {
  const AppModule({required this.id, required this.label, required this.icon, required this.color});
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  LinearGradient get gradient => AppColors.accentGradient(color);
}

/// Const registry of module accents — one hue per module, spread round the
/// colour wheel so neighbours on the Home grid never clash.
class AppModules {
  AppModules._();

  static const buyers = AppModule(id: 'buyers', label: 'Buyers', icon: Icons.storefront_rounded, color: Color(0xFF3B3FB6));
  static const factories = AppModule(id: 'factories', label: 'Factories', icon: Icons.factory_rounded, color: Color(0xFF546E7A));
  static const inquiries = AppModule(id: 'inquiries', label: 'Inquiries', icon: Icons.mark_email_unread_rounded, color: Color(0xFF2F7CE0));
  static const styles = AppModule(id: 'styles', label: 'Styles', icon: Icons.checkroom_rounded, color: Color(0xFFC2185B));
  static const costing = AppModule(id: 'costing', label: 'Costing', icon: Icons.calculate_rounded, color: Color(0xFF7B4FD6));
  static const quotation = AppModule(id: 'quotation', label: 'Quotations', icon: Icons.request_quote_rounded, color: Color(0xFF8E44AD));
  static const approvals = AppModule(id: 'approvals', label: 'Approvals', icon: Icons.approval_rounded, color: Color(0xFF1E9E5A));
  static const sampling = AppModule(id: 'sampling', label: 'Sampling', icon: Icons.content_cut_rounded, color: Color(0xFFE8505B));
  static const orders = AppModule(id: 'orders', label: 'Orders', icon: Icons.receipt_long_rounded, color: Color(0xFF0E8C7F));
  static const ta = AppModule(id: 'ta', label: 'T&A', icon: Icons.timeline_rounded, color: Color(0xFFF4A62A));
  static const production = AppModule(id: 'production', label: 'Production', icon: Icons.precision_manufacturing_rounded, color: Color(0xFFEF6C00));
  static const quality = AppModule(id: 'quality', label: 'Quality', icon: Icons.fact_check_rounded, color: Color(0xFF00897B));
  static const shipment = AppModule(id: 'shipment', label: 'Shipment', icon: Icons.directions_boat_filled_rounded, color: Color(0xFF0277BD));
  static const documents = AppModule(id: 'documents', label: 'Documents', icon: Icons.folder_copy_rounded, color: Color(0xFF5C6BC0));
  static const financial = AppModule(id: 'financial', label: 'Financial', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF2E7D32));
  static const claims = AppModule(id: 'claims', label: 'Claims', icon: Icons.gavel_rounded, color: Color(0xFFD63A3A));
  static const tasks = AppModule(id: 'tasks', label: 'Tasks', icon: Icons.checklist_rounded, color: Color(0xFF00ACC1));
  static const notifications = AppModule(id: 'notifications', label: 'Notifications', icon: Icons.notifications_active_rounded, color: Color(0xFFFF7043));
  static const reports = AppModule(id: 'reports', label: 'Reports', icon: Icons.insights_rounded, color: Color(0xFF6D4C41));

  static const List<AppModule> all = [
    buyers, factories, inquiries, styles, costing, quotation, approvals, sampling, orders, ta,
    production, quality, shipment, documents, financial, claims, tasks, notifications, reports,
  ];

  static AppModule? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
