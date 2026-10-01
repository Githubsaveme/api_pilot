# EasyApiKit 🚀

A production-ready, developer-first Flutter & Dart networking package designed to make API integration effortless while exposing full control for advanced use cases.

[![pub package](https://img.shields.io/pub/v/easy_api_kit.svg)](https://pub.dev/packages/easy_api_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🌟 Key Features

- ⚡ **Ultra-Clean Syntax**: Make API calls in 1 line of code (`EasyApi.get('/users')`).
- 🛠️ **HTTP Methods**: Full support for `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.
- 📦 **Strongly Typed Model Parsing**: Parse JSON into Dart models seamlessly with strong typing (`EasyApi.get<User>('/users/1', parser: User.fromJson)`).
- 🔍 **Model Parse Error Diagnostics**: Terminal diagnostics for JSON type mismatches (expected vs received field types).
- 📁 **Multipart & File Uploads**: Single file, multiple files (`images[]`), bytes, paths, and field naming strategies (`arraySuffix`, `repeatKey`, `indexed`).
- 💾 **File Download**: Direct-to-disk streaming with progress callbacks (`EasyApi.download`).
- 🗄️ **Response Caching**: In-memory caching with strategies (`cacheFirst`, `networkFirst`, `cacheOnly`, `staleWhileRevalidate`).
- 📄 **Pagination Helper**: Easy pagination parser and navigator (`EasyApi.paginate`).
- 🔀 **Functional ApiResult**: Pattern-matched results with `.when(success: ..., failure: ...)` using `EasyApi.safeGet()`.
- 📊 **Progress Tracking**: Measure upload (`onSendProgress`) and download (`onReceiveProgress`) percentages easily.
- 🔐 **Authentication & Token Refresh**: Built-in `AuthInterceptor`, dynamic token providers, and automatic 401 token refresh retries.
- 🔄 **Automated Retry System**: Configurable retries for transient network failures, timeouts, and 502/503/504 errors.
- 🛑 **Request Cancellation**: Cancel in-flight HTTP requests cleanly with `CancellationToken`.
- 📋 **Loading Controllers**: Native Flutter `EasyApiController` / `ApiRequestController` for reactive state binding without requiring GetX/Bloc/Riverpod.
- 🎨 **Beautiful Terminal Logging**: Box-bordered colored console output with automatic sensitive header & key masking (`Authorization`, `password`, `tokens`).

---

## 🚀 Installation

Add `easy_api_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  easy_api_kit: ^1.0.0
```

Run:

```bash
flutter pub get
```

Import it in your Dart code:

```dart
import 'package:easy_api_kit/easy_api_kit.dart';
```

---

## ⚙️ Quick Initialization

Initialize `EasyApi` once in your `main()` or startup logic:

```dart
void main() {
  EasyApi.configure(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    defaultHeaders: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    // Enable caching
    enableCache: true,
    defaultCacheDuration: const Duration(minutes: 5),
    // Dynamic token provider
    tokenProvider: () async => await TokenStorage.getToken(),
    // Automated 401 token refresh handler
    refreshTokenHandler: () async {
      return await AuthService.refreshToken();
    },
  );

  runApp(const MyApp());
}
```

---

## 💻 Making API Calls

### 1. GET Request

```dart
final response = await EasyApi.get('/users');

if (response.isSuccess) {
  print(response.data);
} else {
  print(response.error?.message);
}
```

### 2. Query & Path Parameters

```dart
final response = await EasyApi.get(
  '/users/{id}/posts',
  pathParameters: {'id': 123},
  queryParameters: {
    'page': 1,
    'limit': 20,
    'search': 'john',
  },
);
```

### 3. Strongly Typed Model Parsing

```dart
final response = await EasyApi.get<User>(
  '/user/1',
  parser: User.fromJson,
);

final User? user = response.data;
```

#### Parsing Lists of Models

```dart
final response = await EasyApi.get<List<User>>(
  '/users',
  parser: User.fromJson,
  isList: true,
);

final List<User>? users = response.data;
```

---

### 4. Response Caching

Use `cachePolicy` to serve cached responses instantly:

```dart
final response = await EasyApi.get<User>(
  '/users/1',
  parser: User.fromJson,
  cachePolicy: CachePolicy.cacheFirst,
  cacheDuration: const Duration(minutes: 10),
);
```

Supported Cache Policies:
- `networkOnly`: Always fetch fresh data from network.
- `cacheFirst`: Serve valid cached data if available; fallback to network.
- `networkFirst`: Attempt network call first; fallback to cached data on network failure.
- `cacheOnly`: Serve exclusively from cache.
- `staleWhileRevalidate`: Instantly serve cached data while updating cache in background.

---

### 5. Pagination Helper

Easily fetch and parse paginated lists:

```dart
final response = await EasyApi.paginate<User>(
  '/users',
  page: 1,
  limit: 20,
  parser: User.fromJson,
);

if (response.isSuccess) {
  final PaginationResult<User> pageData = response.data!;
  print('Current Page: ${pageData.currentPage}');
  print('Has Next Page: ${pageData.hasNextPage}');
  print('Items: ${pageData.items.length}');
}
```

---

### 6. Functional `ApiResult` Pattern

Avoid try/catch blocks with the pattern-matched `safeGet`:

```dart
final result = await EasyApi.safeGet<User>(
  '/users/1',
  parser: User.fromJson,
);

result.when(
  success: (user) => print('Hello ${user.name}'),
  failure: (error) => print('Error: ${error.message}'),
);
```

---

### 7. File Downloads

Stream files directly to disk with real-time download progress:

```dart
final response = await EasyApi.download(
  '/files/sample.pdf',
  savePath: '/storage/sample.pdf',
  onReceiveProgress: (received, total) {
    print('Downloaded: ${(received / total * 100).toStringAsFixed(0)}%');
  },
);

final File file = response.data!;
```

---

### 8. POST Request

```dart
final response = await EasyApi.post(
  '/users',
  data: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 28,
  },
);
```

---

### 9. PUT, PATCH, DELETE

```dart
// PUT
final putRes = await EasyApi.put(
  '/users/1',
  data: {'name': 'Updated Name'},
);

// PATCH
final patchRes = await EasyApi.patch(
  '/users/1',
  data: {'title': 'New Title'},
);

// DELETE
final deleteRes = await EasyApi.delete('/users/1');
```

---

### 10. Multipart & File Uploads

Upload fields along with single or multiple files (`File`, `UploadFile`, `Uint8List` bytes, or disk paths):

```dart
final response = await EasyApi.multipart(
  '/users/avatar',
  fields: {
    'user_id': '123',
    'caption': 'Profile Picture',
  },
  files: {
    'profile_image': File('/path/to/avatar.jpg'),
    'documents': [
      File('/path/doc1.pdf'),
      File('/path/doc2.pdf'),
    ],
  },
  multipartStrategy: MultipartFileStrategy.arraySuffix, // creates "documents[]"
  onSendProgress: (sent, total) {
    print('Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
  },
);
```

---

### 11. Form URL Encoded (`application/x-www-form-urlencoded`)

```dart
final response = await EasyApi.form(
  '/login',
  data: {
    'email': 'test@example.com',
    'password': 'secret_password',
  },
);
```

---

## 🎨 Model Parse Error Diagnostics

When a backend response returns types that do not match your Dart model expectations (e.g. backend sends `int` for a field expected to be `String`), `EasyApiKit` prints a diagnostic report:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EASY API KIT - MODEL PARSE ERROR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Endpoint:
GET https://api.example.com/users/1

Status:
200 OK

Problem:
The API request succeeded, but the response could not be converted.

Parser:
User.fromJson

Field:
name

Expected:
String

Received:
int

Possible solutions:
1. Check the raw backend JSON response structure.
2. Verify model `fromJson` constructor mappings.
3. Handle nullable fields properly (e.g. `json["key"] as String?`).
4. Safely convert dynamic types (e.g. `(json["id"] as num?)?.toInt()`).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🛡️ Error Handling Hierarchy

`EasyApiKit` maps all network failures and status codes to strongly typed subclasses of `ApiError`:

| Exception Class | Status Code | Reason / Explanation |
| :--- | :--- | :--- |
| `NetworkError` | - | Socket, DNS, or offline connectivity issues |
| `OfflineError` | - | Device has no active internet connection |
| `TimeoutError` | - | Connect, send, or receive timeout exceeded |
| `UnauthorizedError` | 401 | Missing or invalid authentication credentials |
| `ForbiddenError` | 403 | Lacks permission for requested resource |
| `NotFoundError` | 404 | Endpoint or resource ID does not exist |
| `ValidationError` | 422 / 400 | Validation errors map extracted from response |
| `ServerError` | 5xx | Internal server or gateway error |
| `ParsingError` | 200 | JSON payload could not be parsed into Dart model |
| `CancelledError` | - | Request actively cancelled via `CancellationToken` |

```dart
final response = await EasyApi.get('/users/123');

if (response.isError) {
  final error = response.error;
  if (error is ValidationError) {
    print(error.validationErrors); // {"email": ["Invalid email address"]}
  } else if (error is NotFoundError) {
    print('Resource missing!');
  }
}
```

---

## 📊 Flutter State Management Helper (`EasyApiController`)

Use `EasyApiController` to bind loading, data, and error state directly to Flutter widgets:

```dart
final controller = EasyApiController<User>();

void loadUser() async {
  await controller.execute(() => EasyApi.get<User>(
        '/users/1',
        parser: User.fromJson,
      ));
}

// In Widget build method:
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    if (controller.isLoading) return const CircularProgressIndicator();
    if (controller.hasError) return Text(controller.error!.message);
    return Text('Welcome ${controller.data?.name}');
  },
);
```

---

## 🛑 Request Cancellation

Cancel requests in flight:

```dart
final token = CancellationToken();

// Start request
final future = EasyApi.get('/large-file', cancellationToken: token);

// Cancel anytime
token.cancel('User navigated away');

final response = await future;
print(response.error is CancelledError); // true
```

---

## 🔒 Security & Logging

Sensitive headers and request body keys are masked in terminal logs automatically:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EASY API KIT - REQUEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID       : req_1700000000000_1
METHOD   : POST
URL      : https://api.example.com/login
HEADERS  : {
  "Content-Type": "application/json",
  "Authorization": "*** MASKED ***"
}
BODY     : {
  "email": "user@example.com",
  "password": "*** MASKED ***"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
