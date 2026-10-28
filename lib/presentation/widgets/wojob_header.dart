import 'package:flutter/material.dart';

import 'package:wojob/core/theme/app_colors.dart';

class WoJobHeader extends StatelessWidget implements PreferredSizeWidget {
  const WoJobHeader({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      titleSpacing: 8,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/images/logo.png',
              width: 68,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
        ],
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      ),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white),
    );
  }
}
