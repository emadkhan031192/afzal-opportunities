import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official WhatsApp logo glyph (from the WhatsApp brand SVG path),
/// tintable via [color].
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  static const _svgPath =
      'M12.012 2c-5.506 0-9.989 4.478-9.99 9.984 0 1.763.459 3.484 1.332 5.001L2 22l5.129-1.335A9.957 9.957 0 0012.012 22c5.508 0 9.989-4.478 9.99-9.985 0-5.507-4.482-9.985-9.99-9.985zm0 18.163c-1.503 0-2.977-.404-4.264-1.168l-.306-.182-3.167.825.845-3.088-.2-.317A8.147 8.147 0 013.84 11.984c0-4.498 3.66-8.156 8.172-8.156 4.512 0 8.172 3.658 8.172 8.156 0 4.498-3.66 8.162-8.172 8.162zm4.482-6.118c-.246-.123-1.458-.718-1.684-.801-.225-.082-.389-.123-.553.123-.164.246-.635.801-.778.965-.143.164-.287.185-.533.062a6.726 6.726 0 01-1.977-1.219c-.832-.74-1.395-1.654-1.559-1.935-.164-.281-.017-.433.106-.556.111-.111.246-.287.369-.431.123-.144.164-.246.246-.41.082-.164.041-.308-.021-.431-.062-.123-.553-1.333-.758-1.826-.2-.48-.403-.415-.553-.423h-.472c-.164 0-.431.062-.656.308-.225.246-.861.841-.861 2.052 0 1.21.882 2.38 1.005 2.544.123.164 1.735 2.65 4.204 3.714.588.254 1.047.406 1.406.52.59.187 1.127.16 1.552.097.473-.07 1.458-.596 1.663-1.17.205-.574.205-1.067.144-1.17-.062-.103-.226-.165-.472-.288z';

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24"><path d="$_svgPath" fill="$hex"/></svg>',
      width: size,
      height: size,
    );
  }
}
