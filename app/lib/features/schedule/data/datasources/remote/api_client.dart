import 'package:dio/dio.dart';

import '../../../domain/entities/lesson.dart';

/// HTTP-клиент для получения расписания от API ЯГТУ.
///
/// Stub: пока не реализован реальный URL и парсинг.
/// TODO: добавить baseUrl и реализовать fetchSchedule.
class ApiClient {
  // ignore: unused_field — будет использоваться при реализации реального API
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Lesson>> fetchSchedule(String groupId) async => [];
}
