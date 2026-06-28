import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/use_case/use_case.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/use_cases/watch_pair_status_use_case.dart';

class _MockPairingRepository extends Mock implements PairingRepository {}

void main() {
  late _MockPairingRepository repository;
  late WatchPairStatusUseCase useCase;

  setUp(() {
    repository = _MockPairingRepository();
    useCase = WatchPairStatusUseCase(repository);
  });

  final tPair = Pair(
    id: 'pair-id',
    userAId: 'user-a',
    userBId: 'user-b',
    createdAt: DateTime(2024),
  );

  test('emits null then Pair when user becomes paired', () async {
    when(() => repository.watchPairStatus()).thenAnswer(
      (_) => Stream.fromIterable([
        const Right(null),
        Right(tPair),
      ]),
    );

    final results = await useCase.execute(const NoParams()).toList();

    expect(results.length, 2);
    expect(results[0].isRight(), isTrue);
    expect(results[0].getOrElse((_) => throw Exception()), isNull);
    expect(results[1].getOrElse((_) => throw Exception()), tPair);
  });

  test('emits unpaired when user has no pair', () async {
    when(() => repository.watchPairStatus()).thenAnswer(
      (_) => Stream.value(const Right(null)),
    );

    final result =
        await useCase.execute(const NoParams()).first;

    expect(result.getOrElse((_) => throw Exception()), isNull);
  });
}
