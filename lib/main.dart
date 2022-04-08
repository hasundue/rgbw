import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:RGBW/card.dart';
import 'package:RGBW/game.dart';
import 'package:RGBW/provider.dart';
import 'package:RGBW/gamemaster.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGBW',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends ConsumerWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    ref.setGameMaster();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RGBW - Red Green Black and White'),
      ),
      body: Center(
        child: Row (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ 
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const AliceCards(),
                const FieldCards(),
                const PlayerCards(),
                Row (
                  children: const [
                    Discards(),
                    DeckCards(),
                  ],
                ), // Row
              ],
            ), // Column
          ],
        ), // Row
      ), // Center
      floatingActionButton: FloatingActionButton (
        onPressed: () => initGame(ref),
        child: const Icon(Icons.play_arrow_rounded)
      ),
    ); // Scaffold
  } // build

  void initGame(WidgetRef ref) {
    ref.read(gameStateProvider.notifier).init();
  }
}

class AliceCards extends ConsumerWidget {
  const AliceCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameCards cards = ref.watch(gameStateProvider).alice;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < cards.length; i++)
          AliceCard(id: i),
      ],
    );
  }
}

class FieldCards extends ConsumerWidget {
  const FieldCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameCards cards = ref.watch(gameStateProvider).field;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < cards.length; i++)
          FieldCard(id: i),
      ],
    );
  }
}

class PlayerCards extends ConsumerWidget {
  const PlayerCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GameCards cards = ref.watch(gameStateProvider).player;
    return DragTarget(
      builder: (context, accepted, rejected) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
            PlayerCard(id: i),
          ],
        );
      },
      onAccept: (GameCard data) {
        ref.read(gameStateProvider.notifier).draw();
      },
    );
  }
}

class AliceCard extends ConsumerWidget {
  const AliceCard({Key? key, required this.id}) : super(key: key);

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final GamePhase phase = ref.watch(gamePhaseProvider);
    final GameCard card = ref.watch(gameStateProvider).alice[id];
    // return ColoredCard(color: card.color(), facedown: phase != GamePhase.aliceWin);
    return ColoredCard(color: card.color());
  }
}

class PlayerCard extends ConsumerWidget {
  const PlayerCard({Key? key, required this.id}) : super(key: key);

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameCard card = ref.watch(gameStateProvider).player[id];

    return Draggable(
      data: {'id': id, 'color': card},
      child: ColoredCard(color: card.color()),
      feedback: ColoredCard(color: card.color()),
      childWhenDragging: const ColoredCard(show: false),
    );
  }
}

class FieldCard extends ConsumerWidget {
  const FieldCard({Key? key, required this.id}) : super(key: key);

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GamePhase phase = ref.watch(gamePhaseProvider);
    final GameCard card = ref.watch(gameStateProvider).field[id];

    if (phase == GamePhase.replace) {
      return DragTarget(
        builder: (context, accepted, rejected) {
          return ColoredCard(color: card.color());
        },
        onAccept: (Map data) {
          if (data['color'] != card.color()) {
            ref.read(gameStateProvider.notifier).exchangePlayer(data['id'], id);
            ref.read(gamePhaseProvider.notifier).state = GamePhase.alice;
          }
        },
      );
    } else {
      return ColoredCard(color: card.color());
    }
  }
}

class DeckCards extends ConsumerWidget {
  const DeckCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GamePhase phase = ref.watch(gamePhaseProvider);
    final GameCards deck = List.from(ref.watch(gameStateProvider).deck.reversed);

    if (deck.isNotEmpty) {
      return Row(
        children: [
          Stack(
            children: [
              for (var i = 0; i < deck.length - 1; i++)
                ColoredCard(color: deck[i].color(), facedown: true),
              if (phase == GamePhase.draw)
                Draggable(
                  data: deck.last,
                  child: ColoredCard(color: deck.last.color(), facedown: true),
                  feedback: ColoredCard(color: deck.last.color(), facedown: true),
                  childWhenDragging: const ColoredCard(show: false),
                ),
              if (phase != GamePhase.draw)
                ColoredCard(color: deck.last.color(), facedown: true),
            ],
          ),
          Text(
            deck.length.toString(),
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ); // Row
    } else {
      return const ColoredCard(show: false);
    }
  } // build
}

class Discards extends ConsumerWidget {
  const Discards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GamePhase phase = ref.watch(gamePhaseProvider);

    final GameCards cards = ref.watch(gameStateProvider).discards;

    final GameCards red = cards.where((card) => card == GameCard.red).toList();
    final GameCards green = cards.where((card) => card == GameCard.green).toList();
    final GameCards black = cards.where((card) => card == GameCard.black).toList();

    return DragTarget(
      builder: (context, accepted, rejected) {
        return Row(
          children: [
            for (var color in [red, green, black])
              Row(
                children: [ 
                  Stack(
                    children: [
                      const ColoredCard(show: false),
                      for (var i = 0; i < color.length; i++)
                        ColoredCard(color: color[0].color()),
                    ],
                  ),
                  if (color.isNotEmpty)
                    Text(
                      color.length.toString(),
                      style: const TextStyle(fontSize: 20),
                    ),
                ],
              ), // Row
          ],
        ); // Row
      }, // builder
      onAccept: (Map data) {
        if (phase == GamePhase.discard && data['color'] != GameCard.white) {
          ref.read(gameStateProvider.notifier).discard(data['id']);
          ref.read(gamePhaseProvider.notifier).state = GamePhase.replace;
        }
      },
    ); // DragTarget
  } // Widget
}
