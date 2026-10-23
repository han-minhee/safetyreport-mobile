import 'package:flutter/material.dart';
import '../theme/sr_colors.dart';
import '../theme/sr_tokens.dart';

/// Opaque grouping surface shared by forms, filters and action panels.
class SrSurface extends StatelessWidget {
  const SrSurface({
    super.key,
    required this.child,
    this.radius = SrRadius.xl,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: context.sr.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: context.sr.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class SrSectionHeader extends StatelessWidget {
  const SrSectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Compact workspace switch with variable height for system text scaling.
class SrWorkspaceSwitch extends StatelessWidget implements PreferredSizeWidget {
  const SrWorkspaceSwitch({
    super.key,
    required this.management,
    required this.onChanged,
    required this.textScaler,
  });
  final bool management;
  final ValueChanged<bool> onChanged;
  final TextScaler textScaler;

  @override
  Size get preferredSize => Size.fromHeight(64 + (textScaler.scale(14) - 14));

  @override
  Widget build(BuildContext context) {
    final sr = context.sr;
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: sr.surfaceAlt,
            borderRadius: BorderRadius.circular(SrRadius.lg),
          ),
          child: Row(
            children: [
              for (final value in [false, true])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Semantics(
                      selected: management == value,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: management == value
                              ? sr.surface
                              : null,
                          foregroundColor: management == value
                              ? sr.textPrimary
                              : sr.textSecondary,
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: management == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        onPressed: () => onChanged(value),
                        child: Text(value ? '관리' : '내역'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
