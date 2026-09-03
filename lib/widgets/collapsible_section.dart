// Groovy Chord Generator
// Collapsible Section Widget
// Version 2.7

import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (_isExpanded) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.title.replaceAll(RegExp(r'^[^A-Za-z0-9]+\s*'), '');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isExpanded
              ? const [Color(0xFF232139), Color(0xFF141522)]
              : const [Color(0xFF191A29), Color(0xFF11121D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isExpanded
              ? AppTheme.accentPrimary.withValues(alpha: 0.27)
              : AppTheme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 6,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: _isExpanded ? AppTheme.accentGradient : null,
                        color: _isExpanded ? null : AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cleanTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: _isExpanded
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.bgPrimary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: RotationTransition(
                        turns: _iconRotation,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 19,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _heightFactor,
                builder: (context, child) => Align(
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
