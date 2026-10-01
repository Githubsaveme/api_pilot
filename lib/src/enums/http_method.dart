/// Represents supported HTTP request methods in EasyApiKit.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD'),
  options('OPTIONS');

  final String name;
  const HttpMethod(this.name);

  @override
  String toString() => name;
}
