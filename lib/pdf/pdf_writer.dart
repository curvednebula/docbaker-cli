import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'para_style.dart';
import 'package:intl/intl.dart';

class PdfWriter {
  
  late pw.Document _doc;
  String? topRightText;

  final List<pw.Widget> content = [];

  static const _indent = 25.0;
  static const _accentColor = PdfColors.blue;
  static const _varTypeColor = PdfColor.fromInt(0xFF5577BB);
  static const _commentColor = PdfColor.fromInt(0xFF999999);

  final _defaultStyle = ParaStyle(
    padding: ParaInsets(top: 2, bottom: 2, left: 10),
    textAligh: pw.TextAlign.left,
    textStyle: pw.TextStyle.defaultStyle().copyWith(fontSize: 10)
  );

  final _styleH0 = ParaStyle(textStyle: pw.TextStyle(fontSize: 18, color: _accentColor),
    padding: ParaInsets(top: 25, bottom: 6));

  final _styleH1 = ParaStyle(textStyle: pw.TextStyle(fontSize: 14, color: _accentColor), 
    padding: ParaInsets(top: 20, bottom: 5));
  
  final _styleH2 = ParaStyle(textStyle: pw.TextStyle(fontSize: 13, color: _accentColor), 
    padding: ParaInsets(top: 15, bottom: 4, left: 5));
  
  final _styleH3 = ParaStyle(textStyle: pw.TextStyle(fontSize: 12, color: _accentColor), 
    padding: ParaInsets(top: 10, bottom: 4, left: 5));

  final _styleSubHeader = ParaStyle(textStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold), 
    padding: ParaInsets(top: 10, bottom: 4, left: 5));

  final _textStyleComment = pw.TextStyle(color: _commentColor);

  final _styleCode = ParaStyle(
    textStyle: pw.TextStyle(fontStyle: pw.FontStyle.normal),
    padding: ParaInsets(left: _indent, top: 0, bottom: 0)
  );


  PdfWriter() {
    _doc = pw.Document(pageMode: PdfPageMode.none);
  }

  void flush() {

    // NOTE: this assignment is required to allow _buildHeader() to capture its value,
    // it won't happen to class member
    final rightText = topRightText;

    _doc.addPage(pw.MultiPage(
      orientation: pw.PageOrientation.portrait,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      pageFormat: PdfPageFormat.a4,
      header: (context) => _buildHeader(context, rightText: rightText),
      footer: _buildFooter,
      build: (context) => content
    ));
    
    content.clear();
  }

  Future<Uint8List> exportAsBytes() {
    return _doc.save();
  }

  void addHeader(int level, String text, {String? anchor}) {
    assert(level >= 0 && level <= 3);

    late ParaStyle style;

    switch (level) {
      case 0: style = _styleH0; break;
      case 1: style = _styleH1; break;
      case 2: style = _styleH2; break;
      case 3: style = _styleH3; break;
    }

    anchor ??= text;

    content.add(pw.Anchor(name: anchor, child: pw.Header(
      level: level, 
      text: text,
      textStyle: style.textStyle,
      padding: paraToEdgeInsets(style.padding),
      margin: pw.EdgeInsets.all(0),
      decoration: pw.BoxDecoration()
    )));
  }

  void addSubHeader(String text) {
    _addPara(text, style: _styleSubHeader);
  }

  void addPara(String text) {
    _addPara(text);
  }

  void addComment(String text) {
    _addParaSpans([Span(_stripHtml(text), style: _textStyleComment)]);
  }

  void addSchemaType(String type, String? schemaName) {
    _addParaSpans([
      Span('Type: $type'),
      schemaName != null ? Span(' ($schemaName)', style: pw.TextStyle(color: _varTypeColor)) : Span('')
    ]);
  }

  void addVariable({required String name, String? type, String? description, String? typeAnchor}) {
    
    var codeStyle = _paraStyleWith(_styleCode);
    final nameTs = codeStyle.textStyle;
    final typeTs = nameTs?.copyWith(color: _varTypeColor);
    final typeLinkTs = nameTs?.copyWith(color: _varTypeColor, decoration: pw.TextDecoration.underline);
    var commentTs = nameTs?.merge(_textStyleComment);

    content.add(pw.Container(padding: paraToEdgeInsets(codeStyle.padding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start, 
        children: [
          pw.Text(name + (type != null ? ': ':''), style: nameTs),
          typeAnchor != null 
            ? _buildLink('${type ?? ''};', anchor: typeAnchor, style: typeLinkTs)
            : pw.Text('${type ?? ''};', style: typeTs),
          description != null 
            ? pw.Expanded(child: pw.Padding(padding: pw.EdgeInsets.only(left: 10), 
                child: pw.Text('// $description', style: commentTs)
              ))
            : pw.SizedBox.shrink()
        ]
      )
    ));
  }

  void addEnumValues(List<String> values) {
    List<Span> spans = [];

    for (var i=0; i<values.length; i++) {
      spans.add(Span(values[i]));
      if (i != values.length-1) {
        spans.add(Span(', '));
      }
    }
    _addParaSpans(spans, style: _styleCode);
  }

  void addTitlePage(String title, {String? subTitle}) {

    _doc.addPage(
      pw.Page(
        orientation: pw.PageOrientation.portrait,
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(left: 60, right: 60, bottom: 30),
            child: pw.Column(
              children: [
                pw.Spacer(),
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                      text: '$title\n',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                        fontSize: 24,
                      ),
                    ),
                    pw.TextSpan(
                      text: subTitle != null ? '$subTitle. ' : '',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    pw.TextSpan(
                      text: DateFormat.yMMMd().format(DateTime.now()),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.normal,
                        color: _commentColor,
                        fontSize: 12,
                      ),
                    ),
                  ]),
                ),
                pw.Spacer(flex: 2)
              ],
            ),
          );
        },
      ),
    );
  }

  void addTableOfContent() {
    _doc.addPage(pw.Page(
      orientation: pw.PageOrientation.portrait,
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(children: [
        pw.Center(child: pw.Text('Table of content', style: pw.Theme.of(context).header0)),
        pw.SizedBox(height: 20),
        pw.TableOfContent()
      ])
    ));
  }

  void _addPara(String text, {ParaStyle? style}) {
    _addParaSpans([Span(text)], style: style);
  }

  void _addParaSpans(List<Span> spans, {ParaStyle? style}) {
    content.add(_buildRichText(spans, style: style));
  }

  String _stripHtml(String str) {
    return Bidi.stripHtmlIfNeeded(str).replaceAll(RegExp('\\s+'), ' ');
  }

  pw.Widget _buildRichText(List<Span> spans, {ParaStyle? style}) {

    var paraStyle = _paraStyleWith(style);

    final richText = pw.RichText(
      textAlign: paraStyle.textAligh,
      textScaleFactor: paraStyle.textScale,
      text: pw.TextSpan(children: spans.map((span) {
        // merge more specific style with paragraph style
        pw.TextStyle? lineStyle = paraStyle.textStyle?.merge(span.style) ?? span.style;
        return pw.TextSpan(text: span.text, style: lineStyle);
      }).toList())
    );

    return pw.Padding(
      padding: paraToEdgeInsets(paraStyle.padding), 
      child: richText
    );
  }

  pw.Widget _buildHeader(pw.Context context, {String? rightText}) {
    if (rightText != null) {
      return pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
        padding: const pw.EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
        child: pw.Text(rightText,
          style: _defaultTextStyle.copyWith(fontSize: 8, color: PdfColors.grey)
        )
      );
    } else {
      return pw.SizedBox.shrink();
    }
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 2.0 * PdfPageFormat.mm),
      padding: const pw.EdgeInsets.only(top: 2.0 * PdfPageFormat.mm),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
        style: _defaultTextStyle.copyWith(fontSize: 8, color: PdfColors.grey)
      )
    );
  }

  pw.Widget _buildLink(String text, {required String anchor, pw.TextStyle? style}) {
    return pw.Link(
      destination: anchor,
      child: pw.Text(text, style: style)
    );
  }

  ParaStyle _paraStyleWith(ParaStyle? style) {
    return _defaultStyle.merge(style);
  }

  pw.TextStyle get _defaultTextStyle => _defaultStyle.textStyle!;
}
