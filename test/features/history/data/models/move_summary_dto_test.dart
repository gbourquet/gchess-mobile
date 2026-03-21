import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/features/history/data/models/move_summary_dto.dart';

void main() {
  group('MoveSummaryDTO', () {
    test('fromJson parse les champs obligatoires', () {
      final json = {'from': 'e2', 'to': 'e4', 'moveNumber': 1};
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.from, 'e2');
      expect(dto.to, 'e4');
      expect(dto.moveNumber, 1);
      expect(dto.promotion, isNull);
    });

    test('fromJson parse la promotion', () {
      final json = {
        'from': 'e7',
        'to': 'e8',
        'moveNumber': 40,
        'promotion': 'q',
      };
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.promotion, 'q');
    });

    test('fromJson accepte moveNumber comme double', () {
      final json = {'from': 'a1', 'to': 'a2', 'moveNumber': 5.0};
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.moveNumber, 5);
    });

    test('toUci sans promotion', () {
      const dto = MoveSummaryDTO(from: 'e2', to: 'e4', moveNumber: 1);
      expect(dto.toUci(), 'e2-e4');
    });

    test('toUci avec promotion', () {
      const dto = MoveSummaryDTO(
        from: 'e7',
        to: 'e8',
        moveNumber: 40,
        promotion: 'q',
      );
      expect(dto.toUci(), 'e7-e8-q');
    });

    test('promotion null n\'apparaît pas dans toUci', () {
      const dto = MoveSummaryDTO(from: 'd5', to: 'e6', moveNumber: 20);
      expect(dto.toUci(), 'd5-e6');
      expect(dto.toUci().contains('null'), isFalse);
    });

    test('fromJson parse timeSpentMs', () {
      final json = {
        'from': 'e2',
        'to': 'e4',
        'moveNumber': 1,
        'timeSpentMs': 3500,
      };
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.timeSpentMs, 3500);
    });

    test('fromJson timeSpentMs null si absent', () {
      final json = {'from': 'e2', 'to': 'e4', 'moveNumber': 1};
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.timeSpentMs, isNull);
    });

    test('fromJson accepte timeSpentMs comme double (JSON number)', () {
      final json = {
        'from': 'e2',
        'to': 'e4',
        'moveNumber': 1,
        'timeSpentMs': 1200.0,
      };
      final dto = MoveSummaryDTO.fromJson(json);
      expect(dto.timeSpentMs, 1200);
    });
  });
}
