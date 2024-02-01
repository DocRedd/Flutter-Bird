import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'dart:ui' as ui;  // Alias for 'dart:ui'

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setOrientation(DeviceOrientation.portraitUp);
  String backgroundImagePath = 'assets/images/flappy_background.jpg'; // Path to your background image
  runApp(MaterialApp(
    home: MainMenuScreen(backgroundImage: AssetImage(backgroundImagePath)),
  ));
}
class MyGame extends Game with TapDetector {
  final BuildContext context;
  MyGame(this.context);
  bool isPaused = false;


  late Rect rectangle;
  late Paint paint;
  late Vector2 screenSize;
  double velocity = 0.0;
  double gravity = 1500.0;
  double moveDistance = -600.0; // Distance to move the square upwards on tap

  late ui.Image backgroundImage;  // Use 'ui.Image' here

  int highScore = 0; // Variable to hold the high score
  int tapCount = 0; // Variable to hold the tap count
  late TextPainter  textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
  late TextStyle textStyle = const TextStyle(color: Color(0xFFFFFFFF), fontSize: 24);
  late Offset textPosition = Offset.zero; // Temporary position, will be updated in onGameResize


  late double originalGreenRectY;  // Add a property to store the original Y position
  double greenRectVelocity = -300.0; // Negative for leftward movement, adjust the value as needed
  late Rect greenRectangle;
  late Paint greenPaint;

  late Rect secondGreenRectangle;

  double distanceBetweenRects = 260.0; // Define the distance as a class member


  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    screenSize = size;

    // Update and layout the text
    textPainter.text = TextSpan(text: 'Tap count: $tapCount', style: textStyle);
    textPainter.layout();  // Calculate the layout

    // Position the text at the top center of the screen
    textPosition = Offset((size.x - textPainter.width) / 2, 20);

    // Update and layout the text including high score
    updateScoreTexts();
  }

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = const Color(0xFFE1DE5B); // Example color

    final centerX = screenSize.x / 2;
    final centerY = screenSize.y / 2;
    const rectWidth = 100.0;
    const rectHeight = 100.0;
    rectangle = Rect.fromLTWH(centerX - rectWidth / 2, centerY - rectHeight / 2, rectWidth, rectHeight);
    rectangle = const Rect.fromLTWH(100, 100, 100, 100); // Initial position
    // Load the background image
    final imageLoader = Flame.images.load('flappy_background.jpg');
    backgroundImage = await imageLoader;


    // Initialize the green rectangle
    greenPaint = Paint()..color = Color(0xFF1AC500); // Green color
    final greenRectWidth = 75.0;
    final greenRectHeight = 1000.0;
    greenRectangle = Rect.fromLTWH(
      screenSize.x - greenRectWidth +500, // Positioned on the right side
      (500), // Vertically centered
      greenRectWidth,
      greenRectHeight,
    );
    // Save the original vertical position of the green rectangle
    originalGreenRectY = greenRectangle.top;


    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0; // Load the high score or default to 0



    secondGreenRectangle = Rect.fromLTWH(
        greenRectangle.left,
        greenRectangle.top - distanceBetweenRects - greenRectangle.height, // Position it above the first rectangle
        greenRectangle.width,
        greenRectangle.height
    );
  }

  @override
  void render(Canvas canvas) {
    final screenSize = size.toSize(); // Get the size of the screen
    final src = Rect.fromLTWH(
      0,
      0,
      backgroundImage.width.toDouble(),
      backgroundImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      0,
      0,
      screenSize.width,
      screenSize.height,
    );

    // Draw the scaled background image
    canvas.drawImageRect(backgroundImage, src, dst, Paint());

    // Draw other game elements
    canvas.drawRect(rectangle, paint);

    // Render the text
    textPainter.text = TextSpan(text: 'Score: $tapCount Highscore: $highScore', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, textPosition);


    // Draw the green rectangle
    canvas.drawRect(greenRectangle, greenPaint);

    // Draw the first green rectangle
    canvas.drawRect(greenRectangle, greenPaint);

    // Draw the second green rectangle
    canvas.drawRect(secondGreenRectangle, greenPaint);


  }

  @override
  void update(double dt) {
    if (isPaused) return;

    // Apply gravity to the yellow rectangle
    velocity += gravity * dt;
    double newY = rectangle.top + velocity * dt;

    // Check for collision with the bottom of the screen
    if (newY + rectangle.height > size.y) {
      newY = size.y - rectangle.height;
      velocity = 0.0;
      resetScore(); // Reset score when hitting the bottom
    }

    // Check for collision with the top of the screen
    if (newY < 0) {
      newY = 0;
      velocity = 0.0;
      resetScore(); // Reset score when hitting the top
    }

    // Update the yellow rectangle's position
    rectangle = rectangle.translate(0, newY - rectangle.top);


    // Update the position of the green rectangle
    double newX = greenRectangle.left + greenRectVelocity * dt;

    if (newX < -greenRectangle.width) {
      newX = screenSize.x; // Reset to the right side of the screen

      // Generate a random vertical offset from the original position
      var random = Random();
      double offset = random.nextDouble() * 200 * (random.nextBool() ? 1 : -1); // Random offset between -20 and +20

      // Calculate new vertical position based on the original position
      double newYGreen = originalGreenRectY + offset;

      // Update the position of the green rectangle
      greenRectangle = Rect.fromLTWH(newX, newYGreen, greenRectangle.width, greenRectangle.height);
    } else {
      greenRectangle = greenRectangle.shift(Offset(newX - greenRectangle.left, 0));
    }



    // Check for collision between yellow and green rectangles
    if (greenRectangle.overlaps(rectangle)) {
      // If there is a collision, reset the score
      resetScore();
    }
    // Check for collision between yellow and green rectangles
    if (secondGreenRectangle.overlaps(rectangle)) {
      // If there is a collision, reset the score
      resetScore();
    }
    // Update the position of the second green rectangle
    secondGreenRectangle = Rect.fromLTWH(
        greenRectangle.left, // X-coordinate remains the same as the first rectangle
        greenRectangle.top - distanceBetweenRects - greenRectangle.height, // Adjust the Y-coordinate
        greenRectangle.width,
        greenRectangle.height
    );


  }
  void updateScoreTexts() {
    textPainter.text = TextSpan(
        text: 'Score: $tapCount Highscore: $highScore',
        style: textStyle
    );
    textPainter.layout();

    textPosition = Offset((screenSize.x - textPainter.width) / 2, 20);
  }
  Future<void> resetScore() async {
    if (tapCount > highScore) {
      highScore = tapCount;
      // Save the new high score
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', highScore);
    }
    tapCount = 0;
    updateScoreTexts();
    pauseGame(); // Call this before navigating away
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => MainMenuScreen(backgroundImage: AssetImage('assets/images/flappy_background.jpg')),
    ));
  }

  @override
  void onTapDown(TapDownInfo event) {
    // Move the rectangle upwards on tap
    tapCount++;
    moveSquare();
  }

  void moveSquare() {
    // Apply an upward force
    velocity = moveDistance;
  }

  void pauseGame() {
    isPaused = true;
    // Additionally, you can pause other activities like animations, timers, etc.
  }
  void resumeGame() {
    isPaused = false;
    // Resume other paused activities if necessary
  }
  @override
  void onPause() {
    // Pause any ongoing game activities
  }

  @override
  void onResume() {
    // Resume game activities
  }


}


class MainMenuScreen extends StatefulWidget {
  final ImageProvider backgroundImage;

  MainMenuScreen({required this.backgroundImage});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => GameWidget(game: MyGame(context)),
                ));
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: Text(
                'Play?',
                style: TextStyle(fontSize: 60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
