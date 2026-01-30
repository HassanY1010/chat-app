import 'package:flutter/material.dart';

/// A wrapper that ensures content is within SafeArea and scrollable if needed.
/// Prevents Overflow errors on small screens.
class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final ScrollPhysics? physics;

  const SafeColumn({
    Key? key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding = EdgeInsets.zero,
    this.scrollable = true,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: physics,
        child: Padding(
          padding: padding,
          child: content,
        ),
      );
    } else {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    return SafeArea(child: content);
  }
}

/// A Text widget that scales down if it overflows its bounds.
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final double minScale;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.minScale = 0.8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}

/// A Grid view that calculates the number of columns based on available width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double desiredItemWidth;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.desiredItemWidth = 150,
    this.spacing = 10,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0) return const SizedBox();
        
        final width = constraints.maxWidth;
        final crossAxisCount = (width / desiredItemWidth).floor().clamp(1, 10);
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          shrinkWrap: shrinkWrap,
          physics: physics,
          childAspectRatio: 1.0, // Default to square, can be improved or parameterized
          children: children,
        );
      },
    );
  }
}

// Extension to help with responsive sizing
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  bool get isSmallScreen => screenWidth < 600;
  
  double percentWidth(double p) => screenWidth * p;
  double percentHeight(double p) => screenHeight * p;
}
