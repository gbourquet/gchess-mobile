import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gchess_mobile/core/network/network_info.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late NetworkInfoImpl networkInfo;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = NetworkInfoImpl(mockConnectivity);
  });

  group('NetworkInfoImpl.isConnected', () {
    test('returns true when wifi is connected', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns true when mobile is connected', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.mobile]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns true when ethernet is connected', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.ethernet]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns false when no connection', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await networkInfo.isConnected, isFalse);
    });

    test('returns false when only bluetooth is connected', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.bluetooth]);

      expect(await networkInfo.isConnected, isFalse);
    });

    test('returns true when one of multiple results is wifi', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer(
        (_) async => [ConnectivityResult.none, ConnectivityResult.wifi],
      );

      expect(await networkInfo.isConnected, isTrue);
    });
  });

  group('NetworkInfoImpl.onConnectivityChanged', () {
    test('emits true when connectivity changes to wifi', () async {
      final controller =
          StreamController<List<ConnectivityResult>>.broadcast();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      final stream = networkInfo.onConnectivityChanged;
      final future = stream.first;

      controller.add([ConnectivityResult.wifi]);

      expect(await future, isTrue);
      await controller.close();
    });

    test('emits false when connectivity changes to none', () async {
      final controller =
          StreamController<List<ConnectivityResult>>.broadcast();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      final stream = networkInfo.onConnectivityChanged;
      final future = stream.first;

      controller.add([ConnectivityResult.none]);

      expect(await future, isFalse);
      await controller.close();
    });
  });
}
