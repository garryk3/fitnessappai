import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fitnessappai/core/domain/models/muscle_group.dart';

/// Интерактивная SVG-схема мускулатуры с подсветкой групп.
///
/// Использует SVG-пути для отрисовки реалистичной схемы тела
/// (вид спереди и сзади) с подсветкой активных мышечных групп.
class MuscleMap extends StatelessWidget {
  const MuscleMap({
    super.key,
    this.view = MuscleView.front,
    this.highlighted = const {},
    this.intensity = 1.0,
    this.primaryColor,
    this.bodyColor,
    this.outlineColor,
    this.backgroundColor = Colors.transparent,
  });

  /// Вид схемы: передний или задний.
  final MuscleView view;

  /// Ключи подсвечиваемых мышечных групп (ключи regionKey).
  final Set<String> highlighted;

  /// Интенсивность подсветки 0..1.
  final double intensity;

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
          intensity: intensity,
          primaryColor: effectivePrimary,
          bodyColor: effectiveBody,
          outlineColor: effectiveOutline,
        ),
        fit: BoxFit.contain,
      ),
    );
  }
}

String _buildSvg({
  required MuscleView view,
  required Set<String> highlighted,
  required double intensity,
  required Color primaryColor,
  required Color bodyColor,
  required Color outlineColor,
}) {
  final body = _hex(bodyColor);
  final outline = _hex(outlineColor);
  final active = _hex(primaryColor);

  String fill(String group) => highlighted.contains(group) && intensity > 0
      ? 'url(#activeGradient)'
      : 'url(#bodyGradient)';

  String p(String group, String d, {double opacity = 1}) =>
      '''
    <path
      d="$d"
      fill="${fill(group)}"
      fill-opacity="$opacity"
      stroke="$outline"
      stroke-width="3"
      stroke-linejoin="round"/>
  ''';

  if (view == MuscleView.front) {
    return _buildFrontSvg(body, outline, active, fill, p);
  } else {
    return _buildBackSvg(body, outline, active, fill, p);
  }
}

String _buildFrontSvg(
  String body,
  String outline,
  String active,
  String Function(String) fill,
  String Function(String, String) p,
) {
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 1000">
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

    <filter id="glow" x="-100%" y="-100%" width="300%" height="300%">
      <feGaussianBlur stdDeviation="11"/>
    </filter>
  </defs>

  <!-- Head / neck -->
  <ellipse cx="250" cy="80" rx="35" ry="45"
           fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M235 122L235 150L210 172L250 186L290 172L265 150L265 122Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Traps -->
  <path d="M210 152L175 175L210 208L250 186L290 208L325 175L290 152L268 175L250 186L232 175Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Shoulders -->
  ${p('shoulders', 'M175 172C145 171 125 190 128 225C131 250 150 263 173 252L203 215L210 190Z')}
  ${p('shoulders', 'M325 172C355 171 375 190 372 225C369 250 350 263 327 252L297 215L290 190Z')}

  <!-- Chest -->
  ${p('chest', 'M210 205C225 188 247 185 257 198L257 265C240 273 210 264 196 244C193 230 198 216 210 205Z')}
  ${p('chest', 'M290 205C275 188 253 185 243 198L243 265C260 273 290 264 304 244C307 230 302 216 290 205Z')}

  <!-- Biceps -->
  ${p('biceps', 'M178 250C163 253 155 270 158 295L170 343C177 356 193 352 199 338L206 290C204 270 195 257 178 250Z')}
  ${p('biceps', 'M322 250C337 253 345 270 342 295L330 343C323 356 307 352 301 338L294 290C296 270 305 257 322 250Z')}

  <!-- Triceps / forearms -->
  ${p('triceps', 'M157 293C143 312 140 340 145 370L154 410C159 421 172 419 176 406L180 360L170 343Z')}
  ${p('triceps', 'M343 293C357 312 360 340 355 370L346 410C341 421 328 419 324 406L320 360L330 343Z')}
  ${p('triceps', 'M154 410C147 422 146 450 149 480L155 515C160 526 173 524 176 512L177 468L171 425Z')}
  ${p('triceps', 'M346 410C353 422 354 450 351 480L345 515C340 526 327 524 324 512L323 468L329 425Z')}

  <!-- Abs -->
  ${p('abs', 'M213 265C227 258 244 263 257 270L257 340C237 347 218 340 207 326L206 290Z')}
  ${p('abs', 'M287 265C273 258 256 263 243 270L243 340C263 347 282 340 293 326L294 290Z')}
  ${p('abs', 'M210 327C222 338 240 342 257 340L257 405C237 410 218 402 207 386Z')}
  ${p('abs', 'M290 327C278 338 260 342 243 340L243 405C263 410 282 402 293 386Z')}

  <!-- Obliques -->
  ${p('obliques', 'M204 278L181 289L188 350L207 386L212 327Z')}
  ${p('obliques', 'M296 278L319 289L312 350L293 386L288 327Z')}

  <!-- Pelvis -->
  <path d="M205 385C225 398 243 406 257 406C271 406 289 398 309 385L320 435C298 453 278 462 257 462C236 462 216 453 194 435Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Quads -->
  ${p('quads', 'M195 430C214 435 233 444 252 460L242 568C226 597 203 588 194 563L183 497Z')}
  ${p('quads', 'M319 430C300 435 281 444 262 460L272 568C288 597 311 588 320 563L331 497Z')}
  ${p('quads', 'M252 460L257 459L262 460L266 560C264 590 250 602 238 585L242 568Z')}

  <!-- Knees -->
  <path d="M193 563C206 581 226 588 242 568C245 589 239 610 221 615C204 611 193 592 193 563Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M321 563C308 581 288 588 272 568C269 589 275 610 293 615C310 611 321 592 321 563Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Calves -->
  ${p('calves', 'M196 612C182 632 181 680 190 720C197 738 215 736 223 718L230 650C228 626 215 614 196 612Z')}
  ${p('calves', 'M318 612C332 632 333 680 324 720C317 738 299 736 291 718L284 650C286 626 299 614 318 612Z')}

  <!-- Feet -->
  <path d="M190 716C177 730 170 748 178 760C191 768 219 767 231 758L228 738L212 724Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M324 716C337 730 344 748 336 760C323 768 295 767 283 758L286 738L302 724Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Separator lines -->
  <g fill="none" stroke="#77717F" stroke-width="2" opacity=".45">
    <path d="M257 270V405"/>
  </g>
</svg>
''';
}

String _buildBackSvg(
  String body,
  String outline,
  String active,
  String Function(String) fill,
  String Function(String, String) p,
) {
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 1000">
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

    <filter id="glow" x="-100%" y="-100%" width="300%" height="300%">
      <feGaussianBlur stdDeviation="11"/>
    </filter>
  </defs>

  <!-- Head -->
  <ellipse cx="250" cy="80" rx="35" ry="45"
           fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Neck / traps -->
  <path d="M235 122L235 150L200 175L218 200L250 182L282 200L300 175L265 150L265 122Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Rear deltoids -->
  ${p('shoulders', 'M200 172C170 172 152 190 155 225C158 250 177 262 200 252L223 212L220 190Z')}
  ${p('shoulders', 'M300 172C330 172 348 190 345 225C342 250 323 262 300 252L277 212L280 190Z')}

  <!-- Trapezius -->
  ${p('back', 'M235 150L250 182L265 150L310 185L282 265L250 288L218 265L190 185Z')}

  <!-- Lats -->
  ${p('back', 'M220 210L250 288L250 370C220 363 200 342 192 310L185 255Z')}
  ${p('back', 'M280 210L250 288L250 370C280 363 300 342 308 310L315 255Z')}

  <!-- Triceps -->
  ${p('triceps', 'M155 250C140 272 137 305 141 340L148 388C154 400 167 396 171 384L174 338L166 272Z')}
  ${p('triceps', 'M345 250C360 272 363 305 359 340L352 388C346 400 333 396 329 384L326 338L334 272Z')}

  <!-- Forearms -->
  ${p('triceps', 'M148 388C140 405 141 445 144 480L150 518C156 530 169 527 172 515L172 470L167 410Z')}
  ${p('triceps', 'M352 388C360 405 359 445 356 480L350 518C344 530 331 527 328 515L328 470L333 410Z')}

  <!-- Lower back -->
  ${p('back', 'M218 335C233 352 243 365 250 370L250 435C230 440 214 428 205 410Z')}
  ${p('back', 'M282 335C267 352 257 365 250 370L250 435C270 440 286 428 295 410Z')}

  <!-- Glutes -->
  ${p('glutes', 'M208 420C223 412 240 416 250 428L250 495C230 505 210 494 200 475Z')}
  ${p('glutes', 'M292 420C277 412 260 416 250 428L250 495C270 505 290 494 300 475Z')}

  <!-- Hamstrings -->
  ${p('hamstrings', 'M202 490C218 500 237 506 250 502L240 590C226 613 207 604 199 582L190 525Z')}
  ${p('hamstrings', 'M298 490C282 500 263 506 250 502L260 590C274 613 293 604 301 582L310 525Z')}

  <!-- Knees -->
  <path d="M199 582C210 600 228 607 240 590C243 612 235 628 219 632C204 627 198 610 199 582Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M301 582C290 600 272 607 260 590C257 612 265 628 281 632C296 627 302 610 301 582Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Calves -->
  ${p('calves', 'M200 630C186 655 187 698 194 735C201 752 217 750 224 732L230 668C227 646 215 634 200 630Z')}
  ${p('calves', 'M300 630C314 655 313 698 306 735C299 752 283 750 276 732L270 668C273 646 285 634 300 630Z')}

  <!-- Feet -->
  <path d="M194 732C183 748 177 765 184 775C197 782 221 781 232 773L230 756L214 742Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>
  <path d="M306 732C317 748 323 765 316 775C303 782 279 781 268 773L270 756L286 742Z"
        fill="url(#bodyGradient)" stroke="$outline" stroke-width="3"/>

  <!-- Separator lines -->
  <g fill="none" stroke="#77717F" stroke-width="2" opacity=".45">
    <path d="M250 183V435"/>
  </g>
</svg>
''';
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
