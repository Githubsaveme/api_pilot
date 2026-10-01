import 'package:flutter/material.dart';
import 'package:easy_api_kit/easy_api_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure EasyApiKit globally
  EasyApi.configure(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    enableLogging: true,
    logLevel: ApiLogLevel.full,
    defaultHeaders: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  runApp(const EasyApiExampleApp());
}

class PostModel {
  final int id;
  final int userId;
  final String title;
  final String body;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory PostModel.fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Expected JSON map for PostModel');
    }
    return PostModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class EasyApiExampleApp extends StatelessWidget {
  const EasyApiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyApiKit Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <Map<String, dynamic>>[
      {
        'title': '1. GET Request (Single Object)',
        'subtitle': 'Fetch single post by ID using EasyApi.get',
        'icon': Icons.download_rounded,
        'screen': const GetSingleDemoScreen(),
      },
      {
        'title': '2. GET Request (List of Models)',
        'subtitle': 'Fetch list of posts with strongly typed parsing',
        'icon': Icons.format_list_bulleted_rounded,
        'screen': const GetListDemoScreen(),
      },
      {
        'title': '3. Query Parameters',
        'subtitle': 'GET /comments?postId=1',
        'icon': Icons.filter_list_rounded,
        'screen': const QueryParamsDemoScreen(),
      },
      {
        'title': '4. POST Request',
        'subtitle': 'Create new resource with JSON body',
        'icon': Icons.add_circle_outline_rounded,
        'screen': const PostDemoScreen(),
      },
      {
        'title': '5. PUT Request',
        'subtitle': 'Replace resource at /posts/1',
        'icon': Icons.edit_rounded,
        'screen': const PutDemoScreen(),
      },
      {
        'title': '6. PATCH Request',
        'subtitle': 'Partially update resource at /posts/1',
        'icon': Icons.published_with_changes_rounded,
        'screen': const PatchDemoScreen(),
      },
      {
        'title': '7. DELETE Request',
        'subtitle': 'Delete resource at /posts/1',
        'icon': Icons.delete_outline_rounded,
        'screen': const DeleteDemoScreen(),
      },
      {
        'title': '8. Form URL Encoded',
        'subtitle': 'application/x-www-form-urlencoded request',
        'icon': Icons.description_outlined,
        'screen': const FormUrlEncodedDemoScreen(),
      },
      {
        'title': '9. Multipart File Upload',
        'subtitle': 'Upload fields and files with progress indicator',
        'icon': Icons.upload_file_rounded,
        'screen': const MultipartDemoScreen(),
      },
      {
        'title': '10. Model Parsing Error Handling',
        'subtitle': 'Detailed diagnostic report for JSON type mismatch',
        'icon': Icons.bug_report_outlined,
        'screen': const ModelParseErrorDemoScreen(),
      },
      {
        'title': '11. HTTP Error Handling (404 Not Found)',
        'subtitle': 'Expose structured 404, 422, 500 error diagnostics',
        'icon': Icons.error_outline_rounded,
        'screen': const HttpErrorDemoScreen(),
      },
      {
        'title': '12. Authentication & Token Management',
        'subtitle': 'EasyApi.setToken() and AuthInterceptor',
        'icon': Icons.lock_outline_rounded,
        'screen': const AuthDemoScreen(),
      },
      {
        'title': '13. Request Cancellation',
        'subtitle': 'Cancel in-flight HTTP requests with CancellationToken',
        'icon': Icons.cancel_outlined,
        'screen': const CancellationDemoScreen(),
      },
      {
        'title': '14. Response Caching',
        'subtitle': 'CachePolicy.cacheFirst and TTL expiration',
        'icon': Icons.cached_rounded,
        'screen': const CachingDemoScreen(),
      },
      {
        'title': '15. Pagination Helper',
        'subtitle': 'EasyApi.paginate() page navigation',
        'icon': Icons.auto_stories_rounded,
        'screen': const PaginationDemoScreen(),
      },
      {
        'title': '16. Functional ApiResult',
        'subtitle': 'EasyApi.safeGet() and result.when() pattern',
        'icon': Icons.alt_route_rounded,
        'screen': const SafeApiResultDemoScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyApiKit Showcase'),
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = demos[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  item['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item['subtitle'] as String),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['screen'] as Widget),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Common Response Viewer Component
class ResponseViewerWidget<T> extends StatelessWidget {
  final ApiResponse<T>? response;
  final bool isLoading;

  const ResponseViewerWidget({
    super.key,
    required this.response,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Executing network request...'),
            ],
          ),
        ),
      );
    }

    if (response == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Tap button above to send request.'),
          ),
        ),
      );
    }

    final res = response!;
    final isSuccess = res.isSuccess;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSuccess ? Colors.green.shade300 : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    'STATUS: ${res.statusCode ?? "-"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${res.duration.inMilliseconds} ms'),
                  avatar: const Icon(Icons.timer_outlined, size: 16),
                ),
              ],
            ),
            const Divider(),
            Text('Request URL: ${res.request.fullUrl}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Method: ${res.request.method.name}'),
            const SizedBox(height: 12),
            if (isSuccess) ...[
              const Text('Response Body:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${res.rawData}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ] else ...[
              const Text('Error Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  res.error?.toFormattedString() ?? res.message,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 1. GET Single Demo Screen
class GetSingleDemoScreen extends StatefulWidget {
  const GetSingleDemoScreen({super.key});

  @override
  State<GetSingleDemoScreen> createState() => _GetSingleDemoScreenState();
}

class _GetSingleDemoScreenState extends State<GetSingleDemoScreen> {
  ApiResponse<PostModel>? _response;
  bool _isLoading = false;

  void _fetchPost() async {
    final res = await EasyApi.get<PostModel>(
      '/posts/1',
      parser: PostModel.fromJson,
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GET Single Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchPost,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send GET /posts/1'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<PostModel>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. GET List Demo Screen
class GetListDemoScreen extends StatefulWidget {
  const GetListDemoScreen({super.key});

  @override
  State<GetListDemoScreen> createState() => _GetListDemoScreenState();
}

class _GetListDemoScreenState extends State<GetListDemoScreen> {
  ApiResponse<List<dynamic>>? _response;
  bool _isLoading = false;

  void _fetchPosts() async {
    final res = await EasyApi.get<List<dynamic>>(
      '/posts',
      parser: PostModel.fromJson,
      isList: true,
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GET Posts List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchPosts,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send GET /posts'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<List<dynamic>>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Query Params Demo Screen
class QueryParamsDemoScreen extends StatefulWidget {
  const QueryParamsDemoScreen({super.key});

  @override
  State<QueryParamsDemoScreen> createState() => _QueryParamsDemoScreenState();
}

class _QueryParamsDemoScreenState extends State<QueryParamsDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _fetchComments() async {
    final res = await EasyApi.get(
      '/comments',
      queryParameters: {'postId': 1},
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Query Parameters')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchComments,
              icon: const Icon(Icons.send_rounded),
              label: const Text('GET /comments?postId=1'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. POST Demo Screen
class PostDemoScreen extends StatefulWidget {
  const PostDemoScreen({super.key});

  @override
  State<PostDemoScreen> createState() => _PostDemoScreenState();
}

class _PostDemoScreenState extends State<PostDemoScreen> {
  ApiResponse<PostModel>? _response;
  bool _isLoading = false;

  void _createPost() async {
    final res = await EasyApi.post<PostModel>(
      '/posts',
      data: {
        'title': 'EasyApiKit rocks!',
        'body': 'Production ready networking package for Flutter.',
        'userId': 1,
      },
      parser: PostModel.fromJson,
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POST Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createPost,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send POST /posts'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<PostModel>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. PUT Demo Screen
class PutDemoScreen extends StatefulWidget {
  const PutDemoScreen({super.key});

  @override
  State<PutDemoScreen> createState() => _PutDemoScreenState();
}

class _PutDemoScreenState extends State<PutDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _updatePost() async {
    final res = await EasyApi.put(
      '/posts/1',
      data: {
        'id': 1,
        'title': 'Updated Title',
        'body': 'Updated Body',
        'userId': 1,
      },
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PUT Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updatePost,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send PUT /posts/1'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. PATCH Demo Screen
class PatchDemoScreen extends StatefulWidget {
  const PatchDemoScreen({super.key});

  @override
  State<PatchDemoScreen> createState() => _PatchDemoScreenState();
}

class _PatchDemoScreenState extends State<PatchDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _patchPost() async {
    final res = await EasyApi.patch(
      '/posts/1',
      data: {'title': 'Patched Title'},
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PATCH Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _patchPost,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send PATCH /posts/1'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 7. DELETE Demo Screen
class DeleteDemoScreen extends StatefulWidget {
  const DeleteDemoScreen({super.key});

  @override
  State<DeleteDemoScreen> createState() => _DeleteDemoScreenState();
}

class _DeleteDemoScreenState extends State<DeleteDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _deletePost() async {
    final res = await EasyApi.delete(
      '/posts/1',
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DELETE Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _deletePost,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Send DELETE /posts/1'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 8. Form URL Encoded Demo
class FormUrlEncodedDemoScreen extends StatefulWidget {
  const FormUrlEncodedDemoScreen({super.key});

  @override
  State<FormUrlEncodedDemoScreen> createState() =>
      _FormUrlEncodedDemoScreenState();
}

class _FormUrlEncodedDemoScreenState extends State<FormUrlEncodedDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _sendForm() async {
    final res = await EasyApi.form(
      '/posts',
      data: {
        'title': 'Form Title',
        'body': 'Form Body Content',
      },
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form URL Encoded')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendForm,
              icon: const Icon(Icons.description_rounded),
              label: const Text('Send EasyApi.form()'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 9. Multipart Demo Screen
class MultipartDemoScreen extends StatefulWidget {
  const MultipartDemoScreen({super.key});

  @override
  State<MultipartDemoScreen> createState() => _MultipartDemoScreenState();
}

class _MultipartDemoScreenState extends State<MultipartDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  void _uploadMultipart() async {
    final res = await EasyApi.multipart(
      'https://httpbin.org/post', // Public upload test endpoint
      fields: {
        'username': 'john_doe',
        'description': 'Profile avatar upload',
      },
      files: {
        'profile_image': UploadFile.fromBytes(
          field: 'profile_image',
          filename: 'avatar.png',
          bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]),
        ),
      },
      onSendProgress: (sent, total) {
        setState(() {
          _uploadProgress = total > 0 ? sent / total : 1.0;
        });
      },
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multipart Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadMultipart,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Send Multipart Request'),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _uploadProgress),
              Text('${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 10. Model Parse Error Demo Screen
class ModelParseErrorDemoScreen extends StatefulWidget {
  const ModelParseErrorDemoScreen({super.key});

  @override
  State<ModelParseErrorDemoScreen> createState() =>
      _ModelParseErrorDemoScreenState();
}

class _ModelParseErrorDemoScreenState
    extends State<ModelParseErrorDemoScreen> {
  ApiResponse<PostModel>? _response;
  bool _isLoading = false;

  void _triggerParseError() async {
    // Expected int id, but factory below intentionally fails to demonstrate ParsingError report
    final res = await EasyApi.get<PostModel>(
      '/posts/1',
      parser: (json) {
        // Intentionally throw type error
        final String badId = json['id'];
        return PostModel(id: int.parse(badId), userId: 1, title: '', body: '');
      },
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Parse Error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _triggerParseError,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Trigger Type Mismatch'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<PostModel>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 11. HTTP Error Demo Screen
class HttpErrorDemoScreen extends StatefulWidget {
  const HttpErrorDemoScreen({super.key});

  @override
  State<HttpErrorDemoScreen> createState() => _HttpErrorDemoScreenState();
}

class _HttpErrorDemoScreenState extends State<HttpErrorDemoScreen> {
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _trigger404() async {
    final res = await EasyApi.get(
      '/invalid_endpoint_9999',
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 Not Found Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _trigger404,
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('GET /invalid_endpoint_9999'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 12. Auth Demo Screen
class AuthDemoScreen extends StatefulWidget {
  const AuthDemoScreen({super.key});

  @override
  State<AuthDemoScreen> createState() => _AuthDemoScreenState();
}

class _AuthDemoScreenState extends State<AuthDemoScreen> {
  final String _activeToken = 'jwt_secret_token_example';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Token: $_activeToken',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    EasyApi.setToken(_activeToken);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token set in EasyApi!')),
                    );
                  },
                  child: const Text('Set Token'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    EasyApi.clearToken();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token cleared.')),
                    );
                  },
                  child: const Text('Clear Token'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 13. Cancellation Demo Screen
class CancellationDemoScreen extends StatefulWidget {
  const CancellationDemoScreen({super.key});

  @override
  State<CancellationDemoScreen> createState() =>
      _CancellationDemoScreenState();
}

class _CancellationDemoScreenState extends State<CancellationDemoScreen> {
  CancellationToken? _cancelToken;
  ApiResponse<dynamic>? _response;
  bool _isLoading = false;

  void _startRequest() async {
    final token = CancellationToken();
    setState(() {
      _cancelToken = token;
      _isLoading = true;
    });

    final res = await EasyApi.get(
      '/photos',
      cancellationToken: token,
      onLoading: (loading) => setState(() => _isLoading = loading),
    );

    setState(() => _response = res);
  }

  void _cancel() {
    _cancelToken?.cancel('User tapped cancel button.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Cancellation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startRequest,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Request'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? _cancel : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                  label: const Text('Cancel Request',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<dynamic>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 14. Caching Demo Screen
class CachingDemoScreen extends StatefulWidget {
  const CachingDemoScreen({super.key});

  @override
  State<CachingDemoScreen> createState() => _CachingDemoScreenState();
}

class _CachingDemoScreenState extends State<CachingDemoScreen> {
  ApiResponse<PostModel>? _response;
  bool _isLoading = false;

  void _fetchWithCache() async {
    final res = await EasyApi.get<PostModel>(
      '/posts/1',
      parser: PostModel.fromJson,
      cachePolicy: CachePolicy.cacheFirst,
      cacheDuration: const Duration(minutes: 5),
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Response Caching')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchWithCache,
                  icon: const Icon(Icons.cached_rounded),
                  label: const Text('Fetch (CacheFirst)'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    EasyApi.clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared!')),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text('Clear Cache'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<PostModel>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 15. Pagination Demo Screen
class PaginationDemoScreen extends StatefulWidget {
  const PaginationDemoScreen({super.key});

  @override
  State<PaginationDemoScreen> createState() => _PaginationDemoScreenState();
}

class _PaginationDemoScreenState extends State<PaginationDemoScreen> {
  ApiResponse<PaginationResult<PostModel>>? _response;
  bool _isLoading = false;
  int _page = 1;

  void _fetchPage(int page) async {
    _page = page;
    final res = await EasyApi.paginate<PostModel>(
      '/posts',
      page: page,
      limit: 5,
      parser: PostModel.fromJson,
      onLoading: (loading) => setState(() => _isLoading = loading),
    );
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagination Helper')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading || _page <= 1 ? null : () => _fetchPage(_page - 1),
                  child: const Text('Previous Page'),
                ),
                const SizedBox(width: 16),
                Text('Page $_page', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _fetchPage(_page + 1),
                  child: const Text('Next Page'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseViewerWidget<PaginationResult<PostModel>>(
                  response: _response,
                  isLoading: _isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 16. Safe ApiResult Demo Screen
class SafeApiResultDemoScreen extends StatefulWidget {
  const SafeApiResultDemoScreen({super.key});

  @override
  State<SafeApiResultDemoScreen> createState() => _SafeApiResultDemoScreenState();
}

class _SafeApiResultDemoScreenState extends State<SafeApiResultDemoScreen> {
  String _output = 'Tap button to execute EasyApi.safeGet()';
  bool _isLoading = false;

  void _executeSafeGet() async {
    setState(() => _isLoading = true);

    final result = await EasyApi.safeGet<PostModel>(
      '/posts/1',
      parser: PostModel.fromJson,
    );

    setState(() {
      _isLoading = false;
      _output = result.when(
        success: (post) => 'SUCCESS:\nID: ${post.id}\nTitle: ${post.title}\nBody: ${post.body}',
        failure: (error) => 'FAILURE:\n${error.message}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ApiResult Pattern')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _executeSafeGet,
              icon: const Icon(Icons.alt_route_rounded),
              label: const Text('Execute EasyApi.safeGet()'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Text(
                            _output,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
