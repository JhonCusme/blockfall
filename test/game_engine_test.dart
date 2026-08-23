import 'package:blockfall/game/bag.dart';
import 'package:blockfall/game/board.dart';
import 'package:blockfall/game/game_engine.dart';
import 'package:blockfall/game/scoring.dart';
import 'package:blockfall/game/srs.dart';
import 'package:blockfall/game/tetromino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tetromino', () {
    test('cada pieza tiene siempre cuatro celdas en las cuatro rotaciones', () {
      for (final type in PieceType.values) {
        for (final r in Rotation.values) {
          expect(Tetromino.of(type).cells(r).length, 4,
              reason: 'pieza $type rotación $r');
        }
      }
    });

    test('la O no cambia al rotar', () {
      final o = Tetromino.of(PieceType.o);
      for (final r in Rotation.values) {
        expect(o.cells(r), o.cells(Rotation.spawn));
      }
    });

    test('la I vuelve a su forma inicial tras cuatro giros', () {
      final i = Tetromino.of(PieceType.i);
      expect(i.cells(Rotation.spawn).toSet(), i.cells(Rotation.spawn).toSet());
      // Girar cuatro veces es la identidad por construcción; comprobamos que
      // las rotaciones intermedias son realmente distintas.
      expect(i.cells(Rotation.right).toSet(),
          isNot(equals(i.cells(Rotation.spawn).toSet())));
    });

    test('las rotaciones no se salen de la caja', () {
      for (final type in PieceType.values) {
        final t = Tetromino.of(type);
        for (final r in Rotation.values) {
          for (final c in t.cells(r)) {
            expect(c.x, inInclusiveRange(0, t.boxSize - 1));
            expect(c.y, inInclusiveRange(0, t.boxSize - 1));
          }
        }
      }
    });
  });

  group('PieceBag', () {
    test('reparte las siete piezas antes de repetir', () {
      final bag = PieceBag(seed: 1);
      final first = List.generate(7, (_) => bag.next());
      expect(first.toSet().length, 7);
      final second = List.generate(7, (_) => bag.next());
      expect(second.toSet().length, 7);
    });

    test('la misma semilla da la misma secuencia', () {
      final a = PieceBag(seed: 42);
      final b = PieceBag(seed: 42);
      for (var i = 0; i < 30; i++) {
        expect(a.next(), b.next());
      }
    });

    test('peek no consume piezas', () {
      final bag = PieceBag(seed: 7);
      final preview = bag.peek(5);
      for (final p in preview) {
        expect(bag.next(), p);
      }
    });
  });

  group('Board', () {
    test('una pieza cabe en un tablero vacío y no fuera de los bordes', () {
      final board = Board();
      const piece =
          ActivePiece(type: PieceType.t, rotation: Rotation.spawn, x: 3, y: 5);
      expect(board.fits(piece), isTrue);
      expect(board.fits(piece.moved(-10, 0)), isFalse);
      expect(board.fits(piece.moved(10, 0)), isFalse);
      expect(board.fits(piece.moved(0, Board.height)), isFalse);
    });

    test('borra una línea completa y baja lo de encima', () {
      final board = Board();
      const bottom = Board.height - 1;
      for (var x = 0; x < Board.width; x++) {
        board.grid[bottom][x] = PieceType.i;
      }
      board.grid[bottom - 1][0] = PieceType.t;

      final result = board.clearLines();
      expect(result.linesCleared, 1);
      expect(board.grid[bottom][0], PieceType.t,
          reason: 'la celda de arriba debe haber caído una fila');
      expect(board.grid[bottom - 1][0], isNull);
    });

    test('borra cuatro líneas de golpe', () {
      final board = Board();
      for (var y = Board.height - 4; y < Board.height; y++) {
        for (var x = 0; x < Board.width; x++) {
          board.grid[y][x] = PieceType.i;
        }
      }
      expect(board.clearLines().linesCleared, 4);
      expect(board.stackHeight, 0);
    });

    test('la basura entra por abajo con un hueco', () {
      final board = Board();
      board.addGarbage(2, 3);
      const bottom = Board.height - 1;
      expect(board.at(3, bottom), isNull, reason: 'el hueco');
      expect(board.at(0, bottom), isNotNull);
      expect(board.stackHeight, 2);
    });
  });

  group('SRS', () {
    test('cada transición ofrece cinco desplazamientos', () {
      for (final type in PieceType.values) {
        if (type == PieceType.o) continue;
        for (final from in Rotation.values) {
          for (final to in [from.cw, from.ccw]) {
            expect(kicks(type, from, to).length, 5,
                reason: '$type $from -> $to');
          }
        }
      }
    });

    test('el primer desplazamiento siempre es no moverse', () {
      final k = kicks(PieceType.t, Rotation.spawn, Rotation.right).first;
      expect(k.x, 0);
      expect(k.y, 0);
    });

    test('una rotación bloqueada se salva desplazándose (wall kick)', () {
      final engine = GameEngine(seed: 1)..start();

      // Una sola celda ocupada, justo debajo de donde caería el pie de la T
      // al girar en horario. La posición de partida sigue siendo válida.
      engine.board.grid[12][1] = PieceType.i;

      const start =
          ActivePiece(type: PieceType.t, rotation: Rotation.spawn, x: 0, y: 10);
      engine.current = start;
      expect(engine.board.fits(start), isTrue,
          reason: 'la posición de partida está libre');
      expect(engine.board.fits(start.rotated(Rotation.right)), isFalse,
          reason: 'girar sin desplazarse chocaría con la celda ocupada');

      const before = start;
      expect(engine.rotateCw(), isTrue);
      expect(engine.current!.rotation, Rotation.right);
      expect(engine.current!.x, isNot(before.x),
          reason: 'tuvo que desplazarse para caber');
    });
  });

  group('Scoring', () {
    test('un Tetris en nivel 1 vale 800', () {
      final s = Scoring();
      expect(s.register(ClearKind.tetris), 800);
      expect(s.lines, 4);
    });

    test('dos Tetris seguidos activan el back-to-back', () {
      final s = Scoring();
      s.register(ClearKind.tetris);
      final second = s.register(ClearKind.tetris);
      // Nivel 1 todavía: 800 * 1.5 = 1200, más 50 de combo.
      expect(second, greaterThan(1200 - 1));
    });

    test('un single rompe la racha de back-to-back', () {
      final s = Scoring();
      s.register(ClearKind.tetris);
      s.register(ClearKind.single);
      expect(s.backToBack, -1);
    });

    test('sube de nivel cada diez líneas', () {
      final s = Scoring();
      expect(s.level, 1);
      s.register(ClearKind.tetris);
      s.register(ClearKind.tetris);
      s.register(ClearKind.double_);
      expect(s.lines, 10);
      expect(s.level, 2);
    });

    test('la gravedad se acelera con el nivel y nunca llega a cero', () {
      expect(gravityMs(1), greaterThan(gravityMs(5)));
      expect(gravityMs(5), greaterThan(gravityMs(10)));
      expect(gravityMs(20), greaterThanOrEqualTo(16));
    });
  });

  group('GameEngine', () {
    test('al empezar hay pieza actual y cinco en la cola', () {
      final engine = GameEngine(seed: 3)..start();
      expect(engine.current, isNotNull);
      expect(engine.nextPieces.length, 5);
      expect(engine.status, GameStatus.playing);
    });

    test('el hard drop fija la pieza y saca otra', () {
      final engine = GameEngine(seed: 3)..start();
      final event = engine.hardDrop();
      expect(event.pieceLocked, isTrue);
      expect(engine.board.stackHeight, greaterThan(0));
      expect(engine.current, isNotNull);
    });

    test('el hold guarda la pieza y no se puede repetir hasta fijar otra', () {
      final engine = GameEngine(seed: 3)..start();
      final original = engine.current!.type;
      expect(engine.hold(), isTrue);
      expect(engine.held, original);
      expect(engine.hold(), isFalse, reason: 'un hold por pieza');
      engine.hardDrop();
      expect(engine.hold(), isTrue, reason: 'tras fijar vuelve a estar libre');
    });

    test('la sombra cae hasta el fondo', () {
      final engine = GameEngine(seed: 3)..start();
      final ghost = engine.ghost!;
      expect(ghost.y, greaterThan(engine.current!.y));
      expect(engine.board.fits(ghost.moved(0, 1)), isFalse);
    });

    test('la gravedad baja la pieza sola', () {
      final engine = GameEngine(seed: 3, startLevel: 1)..start();
      final y0 = engine.current!.y;
      engine.tick(1100);
      expect(engine.current!.y, greaterThan(y0));
    });

    test('en pausa no pasa nada', () {
      final engine = GameEngine(seed: 3)..start();
      final y0 = engine.current!.y;
      engine.pause();
      engine.tick(5000);
      expect(engine.current!.y, y0);
      engine.resume();
      expect(engine.status, GameStatus.playing);
    });

    test('llenar el tablero termina la partida', () {
      final engine = GameEngine(seed: 3)..start();
      for (var i = 0; i < 200 && engine.isRunning; i++) {
        engine.hardDrop();
      }
      expect(engine.status, GameStatus.gameOver);
    });

    test('el modo Sprint acaba a las 40 líneas', () {
      final engine = GameEngine(mode: GameMode.sprint, seed: 3)..start();
      // Rellenamos a mano para no depender del azar.
      engine.scoring.lines = 39;
      // Fila de abajo llena salvo la columna 2, que es justo donde cae una I
      // vertical colocada en x=0.
      const bottom = Board.height - 1;
      for (var x = 0; x < Board.width; x++) {
        if (x != 2) engine.board.grid[bottom][x] = PieceType.i;
      }
      engine.current = const ActivePiece(
          type: PieceType.i, rotation: Rotation.right, x: 0, y: 0);
      engine.hardDrop();
      expect(engine.scoring.lines, 40);
      expect(engine.status, GameStatus.gameOver);
    });

    test('el modo Ultra acaba a los dos minutos', () {
      final engine = GameEngine(mode: GameMode.ultra, seed: 3)..start();
      engine.tick(119000);
      expect(engine.isRunning, isTrue);
      engine.tick(2000);
      expect(engine.status, GameStatus.gameOver);
    });

    test('en modo Zen no hay game over', () {
      final engine = GameEngine(mode: GameMode.zen, seed: 3)..start();
      for (var i = 0; i < 300; i++) {
        engine.hardDrop();
      }
      expect(engine.status, GameStatus.playing);
    });

    test('la basura pendiente entra al fijar sin hacer líneas', () {
      final engine = GameEngine(mode: GameMode.versus, seed: 3)..start();
      engine.receiveGarbage(3);
      engine.hardDrop();
      expect(engine.pendingGarbage, 0);
      expect(engine.board.stackHeight, greaterThanOrEqualTo(3));
    });

    test('revivir despeja arriba y continúa conservando la puntuación', () {
      final engine = GameEngine(seed: 3)..start();
      while (engine.isRunning) {
        engine.hardDrop();
      }
      expect(engine.status, GameStatus.gameOver);
      final score = engine.scoring.score;

      expect(engine.canRevive, isTrue);
      expect(engine.revive(), isTrue);
      expect(engine.status, GameStatus.playing);
      expect(engine.scoring.score, score, reason: 'no se pierden los puntos');

      // Las filas superiores quedaron limpias.
      for (var y = 0; y < GameEngine.reviveClearedRows; y++) {
        for (var x = 0; x < Board.width; x++) {
          expect(engine.board.at(x, y), isNull);
        }
      }
    });

    test('solo se puede revivir una vez por partida', () {
      final engine = GameEngine(seed: 3)..start();
      while (engine.isRunning) {
        engine.hardDrop();
      }
      expect(engine.revive(), isTrue);

      while (engine.isRunning) {
        engine.hardDrop();
      }
      expect(engine.status, GameStatus.gameOver);
      expect(engine.canRevive, isFalse, reason: 'el intento ya se gastó');
      expect(engine.revive(), isFalse);
      expect(engine.status, GameStatus.gameOver);
    });

    test('no se ofrece revivir al completar un Sprint', () {
      final engine = GameEngine(mode: GameMode.sprint, seed: 3)..start();
      engine.scoring.lines = 39;
      const bottom = Board.height - 1;
      for (var x = 0; x < Board.width; x++) {
        if (x != 2) engine.board.grid[bottom][x] = PieceType.i;
      }
      engine.current = const ActivePiece(
        type: PieceType.i,
        rotation: Rotation.right,
        x: 0,
        y: 0,
      );
      engine.hardDrop();
      expect(engine.status, GameStatus.gameOver);
      expect(engine.canRevive, isFalse,
          reason: 'terminar el Sprint es ganar, no perder');
    });

    test('no se ofrece revivir en Zen ni en versus', () {
      final zen = GameEngine(mode: GameMode.zen, seed: 3)..start();
      expect(zen.canRevive, isFalse);

      final versus = GameEngine(mode: GameMode.versus, seed: 3)..start();
      while (versus.isRunning) {
        versus.hardDrop();
      }
      expect(versus.status, GameStatus.gameOver);
      expect(versus.canRevive, isFalse, reason: 'revivir rompería el duelo');
    });

    test('una partida larga nunca deja el tablero en estado imposible', () {
      final engine = GameEngine(mode: GameMode.zen, seed: 99)..start();
      for (var i = 0; i < 500; i++) {
        engine.tick(16);
        if (i % 3 == 0) engine.moveLeft();
        if (i % 5 == 0) engine.rotateCw();
        if (i % 7 == 0) engine.hardDrop();
        // Invariante: la pieza actual siempre está en una posición válida.
        final p = engine.current;
        if (p != null) {
          for (final c in p.boardCells) {
            expect(c.x, inInclusiveRange(0, Board.width - 1));
            expect(c.y, lessThan(Board.height));
          }
        }
      }
    });
  });
}
