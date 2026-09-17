import 'package:flutter/material.dart';
import '../../core/theme/rose_pine_theme.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface;
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = isDark ? RosePineColors.darkMuted : RosePineColors.dawnMuted;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: activeColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Plan',
                      isActive: currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(1),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Tutor',
                      isActive: currentIndex == 2,
                      activeColor: RosePineColors.dawnIris,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.timer_rounded,
                      label: 'Focus',
                      isActive: currentIndex == 3,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.quiz_rounded,
                      label: 'Tests',
                      isActive: currentIndex == 4,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(4),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Notes',
                      isActive: currentIndex == 5,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(5),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Settings',
                      isActive: currentIndex == 6,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTap(6),
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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
