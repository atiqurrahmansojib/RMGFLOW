import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Shape of the skeleton shown while loading.
enum LoadingLayout { list, detail, grid, spinner }

/// Document 7 (#97-99) / 12.7: one loading widget reused by every list/detail
/// screen — do not reimplement a spinner per feature.
///
/// Default is a shimmering skeleton list of cards. Use
/// `LoadingView(layout: LoadingLayout.detail)` on detail screens,
/// `LoadingLayout.spinner` for small inline areas.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.layout = LoadingLayout.list,
    this.itemCount = 6,
    this.message,
    this.padding = AppSpacing.page,
  });

  final LoadingLayout layout;
  final int itemCount;

  /// Optional caption (only shown with [LoadingLayout.spinner]).
  final String? message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (layout == LoadingLayout.spinner) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeCap: StrokeCap.round),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      );
    }
    final Widget body = switch (layout) {
      LoadingLayout.detail => _DetailSkeleton(),
      LoadingLayout.grid => _GridSkeleton(count: itemCount),
      _ => _ListSkeleton(count: itemCount),
    };
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: Shimmer(
        child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), padding: padding, child: body),
      ),
    );
  }
}

/// Animated light sweep over its (grey placeholder) child. Respects the
/// platform "remove animations" setting.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppDurations.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final base = s.surfaceContainerHighest;
    final highlight = Color.lerp(base, s.surface, 0.7)!;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value * 3 - 1; // sweep -1 → 2
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, highlight, base],
            stops: [(t - 0.3).clamp(0.0, 1.0), t.clamp(0.0, 1.0), (t + 0.3).clamp(0.0, 1.0)],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height = 12, this.radius = 6});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => _CardShell(
          child: Row(
            children: [
              const _Bone(width: 44, height: 44, radius: 12),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: i.isEven ? 180 : 140, height: 14),
                    const SizedBox(height: 8),
                    _Bone(width: i.isEven ? 110 : 150, height: 10),
                  ],
                ),
              ),
              const _Bone(width: 64, height: 22, radius: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Bone(width: double.infinity, height: 130, radius: AppRadius.xl),
        const SizedBox(height: AppSpacing.lg),
        for (var section = 0; section < 2; section++) ...[
          const _Bone(width: 120, height: 14),
          const SizedBox(height: 4),
          _CardShell(
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _Bone(width: 70.0 + i * 12, height: 10),
                      const Spacer(),
                      _Bone(width: 110.0 - i * 10, height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(
        count,
        (_) => const _CardShell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_Bone(width: 44, height: 44, radius: 12), SizedBox(height: 10), _Bone(width: 56, height: 10)],
          ),
        ),
      ),
    );
  }
}
