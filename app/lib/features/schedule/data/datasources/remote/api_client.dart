import 'package:dio/dio.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/network/dio_client.dart';

/// HTTP-клиент для API расписания ЯГТУ.
///
/// Принимает [Dio] через конструктор (инжектируется из [dioProvider]).
/// Возвращает сырой JSON как [Map<String, dynamic>] — парсинг делает [ScheduleParser].
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchGroups() async {
    try {
      final r = await _dio.get('/s/schedule/v1/schedule/actual_groups');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(dioExceptionMessage(e));
    }
  }

  Future<Map<String, dynamic>> fetchTeachers() async {
    try {
      final r = await _dio.get('/s/schedule/v1/schedule/actual_teachers');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(dioExceptionMessage(e));
    }
  }

  /// [groupName] будет URL-закодирован (например, 'ЦИС-47' → '%D0%A6%D0%98%D0%A1-47').
  Future<Map<String, dynamic>> fetchGroupSchedule(String groupName) async {
    try {
      final encoded = Uri.encodeComponent(groupName);
      final r = await _dio.get('/s/schedule/v1/schedule/group/$encoded');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(dioExceptionMessage(e));
    }
  }

  Future<Map<String, dynamic>> fetchTeacherSchedule(int teacherId) async {
    try {
      final r =
          await _dio.get('/s/schedule/v1/schedule/teacher/$teacherId');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(dioExceptionMessage(e));
    }
  }
}
