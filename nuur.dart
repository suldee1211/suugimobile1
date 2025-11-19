import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Nuur extends StatefulWidget {
  final int gridSize;
  final String difficulty;

  const Nuur({super.key, required this.gridSize, required this.difficulty});

  @override
  State<Nuur> createState() => _NuurState();
}

class _NuurState extends State<Nuur> with TickerProviderStateMixin {
  int get cardsPerMatch => widget.gridSize;

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("🥳 Та яллаа!"),
          content: Text("⏱ Цаг: $secondsPassed сек\n🧠 Нүүдэл: $moveCount"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  gameStarted = false;
                  _initGame();
                });
              },
              child: const Text("Дахин тоглох"),
            ),
          ],
        );
      },
    );
  }

  Timer? gameTimer;
  int secondsPassed = 0;
  int moveCount = 0;
  bool gameStarted = false;
  bool isBusy = false;

  final List<String> allImages = [
    'assets/haan.png',
    'assets/rook.png',
    'assets/zurag.png',
    'assets/hatan.png',
    'assets/bishop.png', // optional extra image
  ];

  late List<String> images; // images actually used for current game
  late List<int> assignedImages;
  late List<bool> isFlipped;
  late List<int> matchedCount;
  List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    int totalCards = widget.gridSize * widget.gridSize;

    // pick exact number of images based on grid size
    int numImages = widget.gridSize;
    images = allImages.sublist(0, numImages);

    // how many cards per match? (3x3 → 3, 4x4 → 4, 5x5 → 5)
    int cardsPerMatch = widget.gridSize;

    assignedImages = [];
    int numGroups = (totalCards / cardsPerMatch).ceil();

    for (int i = 0; i < numGroups; i++) {
      assignedImages.addAll(List.filled(cardsPerMatch, i % images.length));
    }

    // adjust if assignedImages longer than totalCards
    assignedImages = assignedImages.sublist(0, totalCards);

    assignedImages.shuffle();
    isFlipped = List.filled(totalCards, false);
    matchedCount = List.filled(images.length, 0);
    selectedIndices.clear();
    secondsPassed = 0;
    moveCount = 0;
    isBusy = false;
    _stopTimer();
  }

  void _startTimer() {
    _stopTimer();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && gameStarted) {
        setState(() {
          secondsPassed++;
        });
      }
    });
  }

  void _stopTimer() {
    gameTimer?.cancel();
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      _initGame();
      _startTimer();
      // briefly show all cards
      for (int i = 0; i < isFlipped.length; i++) {
        isFlipped[i] = true;
      }
    });

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < isFlipped.length; i++) {
          isFlipped[i] = false;
        }
      });
    });
  }

  void onTapCard(int index) {
    if (!gameStarted || isBusy || isFlipped[index]) return;

    int imageIndex = assignedImages[index];

    if (matchedCount[imageIndex] >= widget.gridSize) return;

    setState(() {
      isFlipped[index] = true;
      selectedIndices.add(index);
      moveCount++;
    });

    List<int> flippedUnmatched = selectedIndices
        .where((i) => matchedCount[assignedImages[i]] < widget.gridSize)
        .toList();

    if (flippedUnmatched.isNotEmpty) {
      bool allSame = flippedUnmatched.every(
        (i) => assignedImages[i] == assignedImages[flippedUnmatched[0]],
      );

      if (allSame && flippedUnmatched.length == widget.gridSize) {
        matchedCount[imageIndex] = widget.gridSize;
        selectedIndices.clear();

        bool allDone = matchedCount.every((m) => m == cardsPerMatch);
        if (allDone) {
          _stopTimer();
          _showWinDialog(); // <-- ADD THIS
        }
      } else if (!allSame && flippedUnmatched.length >= 2) {
        isBusy = true;
        Timer(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            for (var i in flippedUnmatched) {
              if (matchedCount[assignedImages[i]] < widget.gridSize) {
                isFlipped[i] = false;
              }
            }
            selectedIndices.clear();
            isBusy = false;
          });
        });
      }
    }
  }

  Widget buildCard(int index) {
    return GestureDetector(
      onTap: () => onTapCard(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isUnder = (ValueKey(isFlipped[index]) != child!.key);
              double tilt = (animation.value - 0.5).abs() - 0.5;
              tilt *= isUnder ? -0.003 : 0.003;
              final value = isUnder
                  ? min(rotateAnim.value, pi / 2)
                  : rotateAnim.value;
              return Transform(
                transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: isFlipped[index]
            ? Container(
                key: ValueKey(true),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    images[assignedImages[index]],
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                key: const ValueKey(false),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/back.png', fit: BoxFit.cover),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalCards = widget.gridSize * widget.gridSize;
    double containerSize = (widget.gridSize * 80)
        .clamp(200.0, MediaQuery.of(context).size.width - 40)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Түвшин: ${widget.difficulty}"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer & moves
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "⏱ Цаг: $secondsPassed сек",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 40),
                Text(
                  "🧠 Нүүдэл: $moveCount",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.gridSize,
                  childAspectRatio: 1,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: totalCards,
                itemBuilder: (context, index) => buildCard(index),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Эхлэх'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initGame();
                      gameStarted = false;
                      selectedIndices.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Дахин'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
