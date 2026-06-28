import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair_invite_code.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/use_cases/generate_invite_code_use_case.dart';

class _MockPairingRepository extends Mock implements PairingRepository {}

void main() {
  late _MockPairingRepository repository;
  late GenerateInviteCodeUseCase useCase;

  setUp(() {
    repository = _MockPairingRepository();
    useCase = GenerateInviteCodeUseCase(repository);
  });

  final tCode = PairInviteCode(
    id: 'code-id',
    code: 'ABCD1234',
    creatorId: 'user-a',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    used: false,
    createdAt: DateTime.now(),
  );

  test('returns PairInviteCode on success', () async {
    when(() => repository.generateInviteCode())
        .thenAnswer((_) async => Right(tCode));

    final result = await useCase.execute();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => throw Exception()), tCode);
    verify(() => repository.generateInviteCode()).called(1);
  });

  test('returns Failure when repository fails', () async {
    when(() => repository.generateInviteCode())
        .thenAnswer((_) async => const Left(ServerFailure.noConnection()));

    final result = await useCase.execute();

    expect(result.isLeft(), isTrue);
  });
}
