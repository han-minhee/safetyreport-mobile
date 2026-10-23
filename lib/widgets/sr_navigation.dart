import 'package:flutter/material.dart';
import '../navigation/main_tabs.dart';
import '../theme/sr_tokens.dart';
import '../theme/sr_colors.dart';

class SrNavigation extends StatelessWidget {
  const SrNavigation({
    super.key,
    required this.destination,
    required this.onSelect,
    this.unread = 0,
    this.rail = false,
  });
  final AppDestination destination;
  final ValueChanged<AppDestination> onSelect;
  final int unread;
  final bool rail;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(AppDestination d) {
      final selected = destination == d;
      final icon = Icon(d.icon, size: 24);
      return Semantics(
        selected: selected,
        button: true,
        label: d == AppDestination.activity && unread > 0
            ? '${d.label}, 읽지 않음 $unread건'
            : d.label,
        excludeSemantics: true,
        onTap: () => onSelect(d),
        child: Tooltip(
          message: d.label,
          child: InkWell(
            borderRadius: BorderRadius.circular(SrRadius.lg),
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SrRadius.lg),
                color: selected ? scheme.primaryContainer : Colors.transparent,
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    d == AppDestination.activity && unread > 0
                        ? Badge(
                            label: Text(unread > 99 ? '99+' : '$unread'),
                            child: icon,
                          )
                        : icon,
                    const SizedBox(height: 4),
                    Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: context.sr.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: rail ? BorderSide.none : BorderSide(color: context.sr.border),
            right: rail
                ? BorderSide(color: context.sr.border)
                : BorderSide.none,
          ),
        ),
        child: SafeArea(
          top: rail,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: rail
                ? SizedBox(
                    width: 88,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final d in AppDestination.values) item(d),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      for (final d in AppDestination.values)
                        Expanded(child: item(d)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
