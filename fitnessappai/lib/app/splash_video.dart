import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Полноэкранная видео-заставка, проигрываемая во время инициализации.
///
/// Видео зациклено и без звука, растягивается на весь экран с сохранением
/// пропорций ([BoxFit.cover]). До завершения инициализации показывает фон
/// темы, чтобы избежать мигания.
class SplashVideo extends StatefulWidget {
  const SplashVideo({super.key, this.asset = 'assets/videos/splash.mp4'});

  /// Путь к ассету с видео.
  final String asset;

  @override
  State<SplashVideo> createState() => _SplashVideoState();
}

class _SplashVideoState extends State<SplashVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.asset);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          _controller
            ..setLooping(true)
            ..setVolume(0);
          setState(() {});
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _controller.play();
            }
          });
        })
        .catchError((Object _) {
          // На платформах без поддержки видео заставка остаётся пустой, а
          // запуск приложения продолжается без блокировки.
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
