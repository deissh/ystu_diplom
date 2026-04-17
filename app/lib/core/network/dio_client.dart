import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  static Dio create() => Dio(
        BaseOptions(
          baseUrl: 'https://gg-api.ystuty.ru',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        ),
      );
}

final dioProvider = Provider<Dio>((ref) => DioClient.create());

String dioExceptionMessage(DioException e) => switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Превышено время ожидания соединения',
      DioExceptionType.connectionError => 'Нет подключения к сети',
      DioExceptionType.badResponse =>
        'Ошибка сервера: ${e.response?.statusCode}',
      _ => e.message ?? 'Неизвестная сетевая ошибка',
    };
