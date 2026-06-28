import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/use_cases/accept_invite_code_use_case.dart';

class _MockPairingRepository extends Mock implements PairingRepository {}

void main() {
  late _MockPairingRepository repository;
  late AcceptInviteCodeUseCase useCase;

  setUp(() {
    repository = _MockPairingRepository();
    useCase = AcceptInviteCodeUseCase(repository);
  });

  const tCode = 'ABCD1234';

  final tPair = Pair(
    id: 'pair-id',
    userAId: 'user-a',
    userBId: 'user-b',
    createdAt: DateTime(2024),
  );

  test('returns Pair on success', () async {
    when(() => repository.acceptInviteCode(tCode))
        .thenAnswer((_) async => Right(tPair));

    final result = await useCase.execute(tCode);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => throw Exception()), tPair);
    verify(() => repository.acceptInviteCode(tCode)).called(1);
  });

  test('returns PairFailure.invalidCode for invalid code', () async {
    when(() => repository.acceptInviteCode(tCode))
        .thenAnswer((_) async => const Left(PairFailure.invalidCode()));

    final result = await useCase.execute(tCode);

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<PairFailure>());
  });

  test('returns PairFailure.ownCode when using own code', () async {
    when(() => repository.acceptInviteCode(tCode))
        .thenAnswer((_) async => const Left(PairFailure.ownCode()));

    final result = await useCase.execute(tCode);

    expect(result.isLeft(), isTrue);
  });

  test('returns PairFailure.alreadyPaired when user is already paired',
      () async {
    when(() => repository.acceptInviteCode(tCode))
        .thenAnswer((_) async => const Left(PairFailure.alreadyPaired()));

    final result = await useCase.execute(tCode);

    expect(result.isLeft(), isTrue);
  });
}
