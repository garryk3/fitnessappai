import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/widgets/profile_avatar.dart';

void main() {
  testWidgets('ProfileAvatar показывает картинку из assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ProfileAvatar())),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    final image = avatar.backgroundImage! as AssetImage;
    expect(image.assetName, 'assets/images/profile_avatar.jpg');
  });

  testWidgets('ProfileAvatar вызывает onTap при нажатии', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ProfileAvatar(onTap: () => tapped++)),
        ),
      ),
    );

    await tester.tap(find.byType(ProfileAvatar));
    expect(tapped, 1);
  });
}
