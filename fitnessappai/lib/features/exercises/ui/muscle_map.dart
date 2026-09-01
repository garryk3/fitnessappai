import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fitnessappai/core/domain/models/muscle_group.dart';

/// Интерактивная SVG-схема мускулатуры с подсветкой групп.
///
/// Отрисовывает анатомически корректную фигуру (вид спереди/сзади) и
/// подсвечивает активные мышечные группы по ключам regionKey.
///
/// Region-ключи соответствуют справочнику `muscle_groups`:
/// `neck`, `shoulders`, `shoulders_front`, `shoulders_middle`,
/// `shoulders_rear`, `chest`, `chest_upper`, `chest_center`, `chest_lower`,
/// `biceps`, `triceps`, `forearms`, `abs`,
/// `obliques`, `traps`, `lats`, `lower_back`, `glutes`, `quads`,
/// `hamstrings`, `calves`.
class MuscleMap extends StatelessWidget {
  const MuscleMap({
    super.key,
    this.view = MuscleView.front,
    this.highlighted = const {},
    this.primaryColor,
    this.bodyColor,
    this.outlineColor,
    this.backgroundColor = Colors.transparent,
  });

  /// Вид схемы: передний или задний.
  final MuscleView view;

  /// Ключи подсвечиваемых мышечных групп (regionKey).
  final Set<String> highlighted;

  /// Цвет подсветки (по умолчанию — primary из темы).
  final Color? primaryColor;

  /// Цвет тела (по умолчанию — surfaceContainerHighest).
  final Color? bodyColor;

  /// Цвет контура (по умолчанию — outlineVariant).
  final Color? outlineColor;

  /// Цвет фона.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimary = primaryColor ?? theme.colorScheme.primary;
    final effectiveBody =
        bodyColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveOutline = outlineColor ?? theme.colorScheme.outlineVariant;

    return ColoredBox(
      color: backgroundColor,
      child: SvgPicture.string(
        _buildSvg(
          view: view,
          highlighted: highlighted,
          primaryColor: effectivePrimary,
          bodyColor: effectiveBody,
          outlineColor: effectiveOutline,
        ),
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Определяет, активна ли группа: либо явно присутствует в [highlighted],
/// либо входит в родительскую группу, которая подсвечена.
bool _isActive(String group, Set<String> highlighted) {
  if (highlighted.contains(group)) {
    return true;
  }

  const parentChildren = <String, Set<String>>{
    'shoulders': {'shoulders_front', 'shoulders_middle', 'shoulders_rear'},
    'chest': {'chest_upper', 'chest_center', 'chest_lower'},
    'arms': {'biceps', 'triceps', 'forearms'},
    'back': {'traps', 'lats', 'lower_back'},
    'legs': {'quads', 'hamstrings', 'calves', 'glutes'},
  };

  for (final entry in parentChildren.entries) {
    if (highlighted.contains(entry.key) && entry.value.contains(group)) {
      return true;
    }
  }

  return false;
}

String _buildSvg({
  required MuscleView view,
  required Set<String> highlighted,
  required Color primaryColor,
  required Color bodyColor,
  required Color outlineColor,
}) {
  final body = _hex(bodyColor);
  final outline = _hex(outlineColor);
  final active = _hex(primaryColor);

  String fill(String group) => _isActive(group, highlighted)
      ? 'url(#activeGradient)'
      : 'url(#bodyGradient)';

  String p(String group, String d) =>
      '<path d="$d" fill="${fill(group)}" stroke="$outline" '
      'stroke-width="3" stroke-linejoin="round"/>';

  final defs =
      '''
  <defs>
    <linearGradient id="bodyGradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#47444C"/>
      <stop offset=".52" stop-color="$body"/>
      <stop offset="1" stop-color="#27252B"/>
    </linearGradient>
    <linearGradient id="activeGradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E5D6FF"/>
      <stop offset=".42" stop-color="$active"/>
      <stop offset="1" stop-color="#8060C5"/>
    </linearGradient>
  </defs>
  ''';

  if (view == MuscleView.front) {
    return _frontSvg(outline, p, defs);
  }
  return _backSvg(outline, p, defs);
}

String _frontSvg(
  String outline,
  String Function(String, String) p,
  String defs,
) {
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 540 1200">
  $defs

  <!-- Голова -->
  <ellipse cx="270" cy="93" rx="43" ry="55"
           fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Шея -->
  ${p('neck', 'M250 145L250 178L220 205L270 221L320 205L290 178L290 145Z')}

  <!-- Трапеции (перед, контур тела) -->
  <path d="M220 180L178 207L216 248L270 220L324 248L362 207L320 180L292 207L270 220L248 207Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Передняя дельта -->
  ${p('shoulders_front', 'M178 205C145 204 122 225 125 245C127 258 138 265 158 264L195 250L213 233L220 220Z')}
  ${p('shoulders_front', 'M362 205C395 204 418 225 415 245C413 258 402 265 382 264L345 250L327 233L320 220Z')}

  <!-- Средняя дельта -->
  ${p('shoulders_middle', 'M158 264C138 265 127 258 125 245C125 263 128 292 151 307L177 294L195 250Z')}
  ${p('shoulders_middle', 'M382 264C402 265 413 258 415 245C415 263 412 292 389 307L363 294L345 250Z')}

  <!-- Грудь: верх -->
  ${p('chest_upper', 'M216 245C233 224 257 221 268 236L268 265C247 271 220 268 206 253C201 250 208 247 216 245Z')}
  ${p('chest_upper', 'M324 245C307 224 283 221 272 236L272 265C293 271 320 268 334 253C339 250 332 247 324 245Z')}

  <!-- Грудь: центр -->
  ${p('chest_center', 'M206 253C220 268 247 271 268 265L268 300C247 306 220 303 207 288C199 276 200 264 206 253Z')}
  ${p('chest_center', 'M334 253C320 268 293 271 272 265L272 300C293 306 320 303 333 288C341 276 340 264 334 253Z')}

  <!-- Грудь: низ -->
  ${p('chest_lower', 'M207 288C220 303 247 306 268 300L268 317C248 327 214 316 198 292C202 290 205 289 207 288Z')}
  ${p('chest_lower', 'M333 288C320 303 293 306 272 300L272 317C292 327 326 316 342 292C338 290 335 289 333 288Z')}

  <!-- Бицепс -->
  ${p('biceps', 'M181 292C164 295 155 316 159 345L173 400C181 416 199 411 206 394L214 335C212 311 201 296 181 292Z')}
  ${p('biceps', 'M359 292C376 295 385 316 381 345L367 400C359 416 341 411 334 394L326 335C328 311 339 296 359 292Z')}

  <!-- Предплечья -->
  ${p('forearms', 'M157 343C141 365 137 398 143 434L154 483C160 496 176 493 181 478L187 421L174 400Z')}
  ${p('forearms', 'M383 343C399 365 403 398 397 434L386 483C380 496 364 493 359 478L353 421L366 400Z')}
  ${p('forearms', 'M154 483C146 497 145 535 149 574L156 618C163 631 178 628 182 613L183 558L176 503Z')}
  ${p('forearms', 'M386 483C394 497 395 535 391 574L384 618C377 631 362 628 358 613L357 558L364 503Z')}

  <!-- Пресс -->
  ${p('abs', 'M218 316C234 307 254 314 270 322L270 406C247 414 224 406 211 389L210 345Z')}
  ${p('abs', 'M322 316C306 307 286 314 270 322L270 406C293 414 316 406 329 389L330 345Z')}
  ${p('abs', 'M214 390C228 405 249 410 270 407L270 487C247 492 224 482 211 463Z')}
  ${p('abs', 'M326 390C312 405 291 410 270 407L270 487C293 492 316 482 329 463Z')}

  <!-- Косые -->
  ${p('obliques', 'M207 329L181 342L190 417L211 463L218 392Z')}
  ${p('obliques', 'M333 329L359 342L350 417L329 463L322 392Z')}

  <!-- Таз -->
  <path d="M208 462C230 477 251 487 270 487C289 487 310 477 332 462L346 523C320 545 296 555 270 555C244 555 220 545 194 523Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Квадрицепсы -->
  ${p('quads', 'M196 518C218 524 241 535 264 554L252 683C233 717 206 706 195 676L183 591Z')}
  ${p('quads', 'M344 518C322 524 299 535 276 554L288 683C307 717 334 706 345 676L357 591Z')}

  <!-- Колени -->
  <path d="M194 676C209 697 232 705 252 683C256 708 249 733 228 739C207 735 194 711 194 676Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M346 676C331 697 308 705 288 683C284 708 291 733 312 739C333 735 346 711 346 676Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Икры (перед) -->
  ${p('calves', 'M198 735C182 758 181 815 192 864C200 885 221 883 230 862L239 780C236 751 221 737 198 735Z')}
  ${p('calves', 'M342 735C358 758 359 815 348 864C340 885 319 883 310 862L301 780C304 751 319 737 342 735Z')}

  <!-- Ступни -->
  <path d="M192 860C177 875 169 895 178 910C193 920 225 919 239 908L236 883L217 867Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M348 860C363 875 371 895 362 910C347 920 315 919 301 908L304 883L323 867Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Линии сепарации -->
  <g fill="none" stroke="#77717F" stroke-width="2" opacity=".45">
    <path d="M270 323V485"/>
    <path d="M214 430C230 445 247 450 270 449"/>
    <path d="M326 430C310 445 293 450 270 449"/>
  </g>
</svg>
''';
}

String _backSvg(
  String outline,
  String Function(String, String) p,
  String defs,
) {
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 540 1200">
  $defs

  <!-- Голова -->
  <ellipse cx="270" cy="93" rx="43" ry="55"
           fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Шея -->
  ${p('neck', 'M249 145L249 180L210 207L230 239L270 217L310 239L330 207L291 180L291 145Z')}

  <!-- Задняя дельта -->
  ${p('shoulders_rear', 'M211 205C178 205 156 226 160 264C163 292 186 305 212 293L239 248L234 219Z')}
  ${p('shoulders_rear', 'M329 205C362 205 384 226 380 264C377 292 354 305 328 293L301 248L306 219Z')}

  <!-- Трапеции -->
  ${p('traps', 'M249 180L270 217L291 180L344 221L310 318L270 346L230 318L196 221Z')}

  <!-- Широчайшие -->
  ${p('lats', 'M232 254L270 346L270 445C234 437 210 411 200 372L190 303Z')}
  ${p('lats', 'M308 254L270 346L270 445C306 437 330 411 340 372L350 303Z')}

  <!-- Трицепс -->
  ${p('triceps', 'M160 291C142 316 138 355 143 397L151 456C159 470 175 465 180 450L185 389L175 319Z')}
  ${p('triceps', 'M380 291C398 316 402 355 397 397L389 456C381 470 365 465 360 450L355 389L365 319Z')}

  <!-- Предплечья -->
  ${p('forearms', 'M151 456C142 475 143 523 147 566L155 615C163 628 178 624 181 608L180 552L173 474Z')}
  ${p('forearms', 'M389 456C398 475 397 523 393 566L385 615C377 628 362 624 359 608L360 552L367 474Z')}

  <!-- Поясница -->
  ${p('lower_back', 'M230 402C247 421 258 438 270 445L270 525C246 531 226 516 215 493Z')}
  ${p('lower_back', 'M310 402C293 421 282 438 270 445L270 525C294 531 314 516 325 493Z')}

  <!-- Ягодицы -->
  ${p('glutes', 'M216 500C234 490 254 495 270 510L270 592C246 604 218 591 206 568Z')}
  ${p('glutes', 'M324 500C306 490 286 495 270 510L270 592C294 604 322 591 334 568Z')}

  <!-- Бицепс бедра -->
  ${p('hamstrings', 'M208 585C227 596 249 603 266 598L254 705C238 732 215 722 205 696L194 631Z')}
  ${p('hamstrings', 'M332 585C313 596 291 603 274 598L286 705C302 732 325 722 335 696L346 631Z')}

  <!-- Колени -->
  <path d="M205 696C219 718 240 727 254 705C258 731 249 748 230 752C212 746 204 727 205 696Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M335 696C321 718 300 727 286 705C282 731 291 748 310 752C328 746 336 727 335 696Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Икры (зад) -->
  ${p('calves', 'M209 748C192 775 193 824 202 865C211 887 231 884 240 862L248 785C244 759 230 748 209 748Z')}
  ${p('calves', 'M331 748C348 775 347 824 338 865C329 887 309 884 300 862L292 785C296 759 310 748 331 748Z')}

  <!-- Ступни -->
  <path d="M202 860C189 878 182 898 192 911C209 919 236 918 248 907L246 883L224 866Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M338 860C351 878 358 898 348 911C331 919 304 918 292 907L294 883L316 866Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Линии сепарации -->
  <g fill="none" stroke="#77717F" stroke-width="2" opacity=".45">
    <path d="M270 218V525"/>
    <path d="M230 430C245 442 258 447 270 447"/>
    <path d="M310 430C295 442 282 447 270 447"/>
  </g>
</svg>
''';
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
