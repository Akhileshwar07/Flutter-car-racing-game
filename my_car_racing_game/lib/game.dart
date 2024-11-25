import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';     //6303056636
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarRacingGame extends FlameGame with TapDetector {
  late SpriteComponent car;
  late List<SpriteComponent> roadSegments;
  late List<RockComponent> rocks;
  late TextComponent scoreText;
  TextComponent? gameOverText;
  
  final double roadSpeed = 200;
  final double carWidth = 60;
  final double carHeight = 100;
  final double rockSize = 50;
  final double rockSpeed = 150;
  
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  Random random = Random();

  @override
  Future<void> onLoad() async {
    await Flame.images.loadAll([
      'cars.png',
      'roads.png',
      'rock.png',
    ]);

    await loadHighScore();

    // Initialize road segments
    roadSegments = List.generate(2, (index) {
      return SpriteComponent()
        ..sprite = Sprite(Flame.images.fromCache('roads.png'))
        ..size = Vector2(size.x, size.y)
        ..position = Vector2(0, -size.y + index * size.y);
    });

    roadSegments.forEach(add);

    // Initialize the car
    car = SpriteComponent()
      ..sprite = Sprite(Flame.images.fromCache('cars.png'))
      ..size = Vector2(carWidth, carHeight)
      ..position = Vector2(size.x / 2 - carWidth / 2, size.y - carHeight - 20);

    add(car);

    // Initialize rocks list
    rocks = [];

    // Initialize score text
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(size.x - 100, 20),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(scoreText);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;

    super.update(dt);

    // Move road segments
    for (var segment in roadSegments) {
      segment.position.y += roadSpeed * dt;
      if (segment.position.y >= size.y) {
        segment.position.y = -size.y;
      }
    }

    // Update rocks
    for (var rock in List.from(rocks)) {
      rock.position.y += rockSpeed * dt;

      // Check for collision with car
      if (rock.toRect().overlaps(car.toRect())) {
        gameOver();
        return;
      }

      // Check if rock passed the car
      if (rock.position.y > car.position.y + carHeight && !rock.isPassed) {
        rock.isPassed = true;
        score++;
        scoreText.text = 'Score: $score';
      }

      // Remove rock if it's off screen
      if (rock.position.y > size.y) {
        rocks.remove(rock);
        remove(rock);
      }
    }

    // Spawn new rocks
    if (rocks.isEmpty || rocks.last.position.y > rockSize * 3) {
      spawnRock();
    }
  }

  void spawnRock() {
    final rock = RockComponent(
      sprite: Sprite(Flame.images.fromCache('rock.png')),
      size: Vector2(rockSize, rockSize),
      position: Vector2(random.nextDouble() * (size.x - rockSize), -rockSize),
    );

    rocks.add(rock);
    add(rock);
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (isGameOver) {
      restartGame();
    } else {
      final touchPoint = info.eventPosition.global;
      moveCar(touchPoint.x);
    }
  }

  void moveCar(double targetX) {
    // Calculate the center of the car
    targetX = (targetX - carWidth / 2).clamp(0, size.x - carWidth);
    car.position.x = targetX;
  }

  void gameOver() {
    isGameOver = true;
    if (score > highScore) {
      highScore = score;
      saveHighScore();
    }
    gameOverText = TextComponent(
      text: 'Game Over\nTap to Restart\nScore: $score\nHigh Score: $highScore',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
    );
    add(gameOverText!);
  }

  void restartGame() {
    isGameOver = false;
    score = 0;
    scoreText.text = 'Score: 0';
    car.position = Vector2(size.x / 2 - carWidth / 2, size.y - carHeight - 20);
    
    // Remove all rocks
    rocks.forEach(remove);
    rocks.clear();
    
    // Remove the game over text
    if (gameOverText != null) {
      remove(gameOverText!);
      gameOverText = null;
    }
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }
}

class RockComponent extends SpriteComponent {
  bool isPassed = false;

  RockComponent({
    required Sprite sprite,
    required Vector2 size,
    required Vector2 position,
  }) : super(sprite: sprite, size: size, position: position);
}