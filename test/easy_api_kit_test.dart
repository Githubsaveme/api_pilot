import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:easy_api_kit/easy_api_kit.dart';

class TestUser {
  final int id;
  final String name;
  final String email;

  TestUser({required this.id, required this.name, required this.email});

  factory TestUser.fromJson(dynamic json) {
    if (json is! Map) {
      throw FormatException('Expected JSON Map for TestUser');
    }
    return TestUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

void main() {
  group('EasyApiKit Tests', () {
    test('GET request with successful JSON response and model parsing', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/users/1');
        return http.Response(
          jsonEncode({
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '1',
        method: HttpMethod.get,
        url: '/users/1',
      );

      final response = await apiClient.execute<TestUser>(
        req,
        parser: TestUser.fromJson,
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, 200);
      expect(response.data, isNotNull);
      expect(response.data!.id, 1);
      expect(response.data!.name, 'John Doe');
      expect(response.data!.email, 'john@example.com');
    });

    test('GET list of models parsing', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'John', 'email': 'john@test.com'},
            {'id': 2, 'name': 'Jane', 'email': 'jane@test.com'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '2',
        method: HttpMethod.get,
        url: '/users',
      );

      final response = await apiClient.execute<List<dynamic>>(
        req,
        parser: TestUser.fromJson,
        isList: true,
      );

      expect(response.isSuccess, isTrue);
      expect(response.data!.length, 2);
      final user1 = response.data![0] as TestUser;
      final user2 = response.data![1] as TestUser;
      expect(user1.name, 'John');
      expect(user2.name, 'Jane');
    });

    test('POST request with body payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        final decoded = jsonDecode(request.body);
        expect(decoded['name'], 'Alice');
        return http.Response(
          jsonEncode({'id': 100, 'name': 'Alice', 'email': 'alice@example.com'}),
          201,
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '3',
        method: HttpMethod.post,
        url: '/users',
        data: {'name': 'Alice', 'email': 'alice@example.com'},
      );

      final response = await apiClient.execute<TestUser>(
        req,
        parser: TestUser.fromJson,
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, 201);
      expect(response.data!.id, 100);
    });

    test('HTTP 404 Not Found returns NotFoundError', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'User not found'}),
          404,
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '4',
        method: HttpMethod.get,
        url: '/users/999',
      );

      final response = await apiClient.execute(req);

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, 404);
      expect(response.error, isA<NotFoundError>());
      expect(response.error!.message, 'User not found');
    });

    test('HTTP 422 Validation Error parses field errors map', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Validation failed',
            'errors': {
              'email': ['Email address is invalid'],
              'password': ['Password must be at least 6 characters']
            }
          }),
          422,
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '5',
        method: HttpMethod.post,
        url: '/register',
        data: {},
      );

      final response = await apiClient.execute(req);

      expect(response.isSuccess, isFalse);
      expect(response.error, isA<ValidationError>());
      final valError = response.error as ValidationError;
      expect(valError.validationErrors['email']!.first, 'Email address is invalid');
      expect(valError.validationErrors['password']!.first, 'Password must be at least 6 characters');
    });

    test('Model parse error returns ParsingError with details', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'not_an_int_id', // Expected int
            'name': 'John',
            'email': 'john@example.com',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final req = ApiRequest(
        id: '6',
        method: HttpMethod.get,
        url: '/users/1',
      );

      final response = await apiClient.execute<TestUser>(
        req,
        parser: TestUser.fromJson,
      );

      expect(response.isSuccess, isFalse);
      expect(response.error, isA<ParsingError>());
      final parseError = response.error as ParsingError;
      expect(parseError.statusCode, 200);
      expect(parseError.toFormattedString(), contains('MODEL PARSE ERROR'));
    });

    test('CancellationToken cancels in-flight request', () async {
      final token = CancellationToken();
      token.cancel('User navigated away');

      final mockClient = MockClient((request) async {
        return http.Response('{"ok": true}', 200);
      });

      final req = ApiRequest(
        id: '7',
        method: HttpMethod.get,
        url: '/long-task',
        cancellationToken: token,
      );

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final response = await apiClient.execute(req);

      expect(response.isSuccess, isFalse);
      expect(response.error, isA<CancelledError>());
      expect(response.error!.message, contains('User navigated away'));
    });

    test('AuthInterceptor injects Authorization token header', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer secret_jwt_123');
        return http.Response('{"ok": true}', 200);
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      apiClient.authInterceptor.setToken('secret_jwt_123');

      final req = ApiRequest(
        id: '8',
        method: HttpMethod.get,
        url: '/protected',
      );

      final response = await apiClient.execute(req);
      expect(response.isSuccess, isTrue);
    });

    test('EasyApiController manages loading and error state', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'id': 1, 'name': 'John', 'email': 'john@test.com'}),
          200,
        );
      });

      final apiClient = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.com', enableLogging: false),
        httpClient: mockClient,
      );

      final controller = EasyApiController<TestUser>();
      expect(controller.isLoading, isFalse);
      expect(controller.hasData, isFalse);

      final future = controller.execute(() => apiClient.execute<TestUser>(
            ApiRequest(id: '9', method: HttpMethod.get, url: '/user'),
            parser: TestUser.fromJson,
          ));

      expect(controller.isLoading, isTrue);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.hasData, isTrue);
      expect(controller.data!.name, 'John');
    });

    test('ApiResult.when handles success and failure branches', () {
      final successResult = ApiResult<String>.success('Hello World');
      String? successMessage;
      successResult.when(
        success: (data) => successMessage = data,
        failure: (error) => fail('Should not reach failure'),
      );
      expect(successMessage, 'Hello World');

      final failureResult = ApiResult<String>.failure(
        const NotFoundError(message: 'Item not found'),
      );
      String? errorMessage;
      failureResult.when(
        success: (data) => fail('Should not reach success'),
        failure: (error) => errorMessage = error.message,
      );
      expect(errorMessage, 'Item not found');
    });

    test('MemoryCache stores and expires entries correctly', () {
      final cache = MemoryCache();
      cache.set<String>(
        key: 'test_key',
        data: 'cached_value',
        rawData: 'cached_value',
        statusCode: 200,
        headers: {},
        duration: const Duration(minutes: 10),
      );

      final entry = cache.get('test_key');
      expect(entry, isNotNull);
      expect(entry!.data, 'cached_value');
      expect(entry.isExpired, isFalse);
    });

    test('PaginationParser parses page metadata correctly', () {
      final json = {
        'page': 1,
        'limit': 10,
        'total': 25,
        'data': [
          {'id': 1, 'name': 'John', 'email': 'john@test.com'},
          {'id': 2, 'name': 'Jane', 'email': 'jane@test.com'},
        ],
      };

      final result = PaginationParser.parse<TestUser>(
        json: json,
        parser: TestUser.fromJson,
        currentPage: 1,
        limit: 10,
      );

      expect(result.currentPage, 1);
      expect(result.limit, 10);
      expect(result.total, 25);
      expect(result.hasNextPage, isTrue);
      expect(result.items.length, 2);
      expect(result.items[0].name, 'John');
    });
  });
}
