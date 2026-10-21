import 'package:dio/dio.dart';
import '../config/network/dio_client.dart';

class ApiService {
   final DioClient client;
   ApiService({required this.client});
  
    /// Example API call
  Future<Response> fetchUsers() {
    return client.dio.get('https://jsonplaceholder.typicode.com/users');
  }
}
