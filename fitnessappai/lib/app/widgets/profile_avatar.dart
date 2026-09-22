import 'package:flutter/material.dart';

/// Аватар профиля пользователя (картинка в `assets/images/`).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 12, this.onTap});

  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      backgroundImage: const AssetImage('assets/images/profile_avatar.jpg'),
    );
    if (onTap == null) {
      return avatar;
    }
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: avatar,
    );
  }
}
