import 'package:pdf/widgets.dart' as pw;

class Span {
  String text;
  pw.TextStyle? style;

  Span(this.text, {this.style});

  Span.bold(this.text, {pw.TextStyle? style})
    : style = style?.copyWith(fontWeight: pw.FontWeight.bold) ?? pw.TextStyle(fontWeight: pw.FontWeight.bold);
}

class ParaInsets {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  ParaInsets({this.top, this.bottom, this.left, this.right});

  ParaInsets merge(ParaInsets? other) {
    if (other == null) {
      return this;
    }
    return ParaInsets(
      top: other.top ?? top,
      bottom: other.bottom ?? bottom,
      left: other.left ?? left,
      right: other.right ?? right
    );
  }

  pw.EdgeInsets toEdgeInsets() {
    return pw.EdgeInsets.fromLTRB(left ?? 0, top ?? 0, right ?? 0, bottom ?? 0);
  }
}

pw.EdgeInsets paraToEdgeInsets(ParaInsets? para) {
  return pw.EdgeInsets.fromLTRB(
    para?.left ?? 0, 
    para?.top ?? 0, 
    para?.right ?? 0, 
    para?.bottom ?? 0
  );
}

class ParaStyle {

  final ParaInsets? padding;
  final pw.TextAlign? textAligh;
  final pw.TextStyle? textStyle;
  final double textScale;

  ParaStyle({this.padding, this.textAligh, this.textStyle, this.textScale = 1.0});

  ParaStyle merge(ParaStyle? other) {
    if (other == null) {
      return this;
    }
    return ParaStyle(
      padding: padding?.merge(other.padding) ?? other.padding,
      textAligh: other.textAligh ?? textAligh,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      textScale: textScale * other.textScale
    );
  }
}