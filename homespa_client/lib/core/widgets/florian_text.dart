import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text in the Florian display font. The Florian demo font has no real "&"
/// glyph (it draws a "DEMO" watermark instead), so every "&" is set in
/// Cormorant Garamond at the same size, weight and colour.
class FlorianText extends StatelessWidget {
  final String text;

  /// Full Florian style (fontFamily: 'Florian' is applied if missing).
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const FlorianText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      florianSpan(text, style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Splits [text] so "&" uses the fallback font and everything else Florian.
TextSpan florianSpan(String text, TextStyle style) {
  final base = style.copyWith(fontFamily: 'Florian');
  if (!text.contains('&')) return TextSpan(text: text, style: base);

  final ampersand = GoogleFonts.cormorantGaramond(textStyle: base);
  final parts = text.split('&');
  return TextSpan(
    style: base,
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0) TextSpan(text: '&', style: ampersand),
        if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
      ],
    ],
  );
}
