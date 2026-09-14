import 'package:flutter/material.dart';

/// A small dot stacked over an icon to flag state.
///
/// This came from the `badges` package. Flutter has shipped its own [Badge]
/// since 3.7 and both export the name, so with `material.dart` in scope the
/// reference is ambiguous - a hard compile error, not something an import
/// prefix should paper over over. Flutter's [Badge] draws a plain filled circle
/// when [Badge.label] is null, which is what the old `badgeContent: Text('')`
/// was reaching for, so the third-party dependency is dropped rather than
/// prefixed.
class ShowBadge extends StatelessWidget {
  const ShowBadge({super.key, required this.showBadge, required this.icon});

  final Widget icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      // Hiding the label leaves the child rendered on its own, which is the
      // same shape as returning `icon` unwrapped.
      isLabelVisible: showBadge,
      child: icon,
    );
  }
}
