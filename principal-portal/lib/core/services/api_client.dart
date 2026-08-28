import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiClient {
  ApiClient._();
  
  static bool _initialised = false;
  static bool get isReady => _initialised;

  static Future<void> initialise() async {
    if (!AppConfig.isBackendConfigured) return;
    _initialised = true;
  }

  static ApiSchema schema(String schemaName) {
    if (!_initialised) {
      throw StateError('No database connection.');
    }
    return ApiSchema(schemaName);
  }

  static Future<Map<String, dynamic>> uploadCSV({
    required String table,
    required String csvContent,
    required String fileName,
  }) async {
    final uri = Uri.parse('${AppConfig.supabaseUrl}/api/import/$table');
    final request = http.MultipartRequest('POST', uri);
    if (AppConfig.apiKey.isNotEmpty) {
      request.headers['x-api-key'] = AppConfig.apiKey;
    }
    request.files.add(
      http.MultipartFile.fromString(
        'file',
        csvContent,
        filename: fileName,
      ),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded;
    } else {
      final errorMsg = decoded['error'] ?? 'Import failed';
      final details = decoded['details'] != null ? '\n${(decoded['details'] as List).join('\n')}' : '';
      throw Exception('$errorMsg$details');
    }
  }
}


class ApiQuery<T> implements Future<T> {
  final String schema;
  final String table;
  String _select = '*';
  final Map<String, String> _filters = {};
  String? _orderBy;
  bool _ascending = true;
  int? _limit;
  
  bool _isInsert = false;
  bool _isUpdate = false;
  bool _isDelete = false;
  Map<String, dynamic>? _values;
  bool _single = false;
  bool _maybeSingle = false;

  ApiQuery(this.schema, this.table);

  ApiQuery<R> _copyWithType<R>() {
    final copy = ApiQuery<R>(schema, table);
    copy._select = _select;
    copy._filters.addAll(_filters);
    copy._orderBy = _orderBy;
    copy._ascending = _ascending;
    copy._limit = _limit;
    copy._isInsert = _isInsert;
    copy._isUpdate = _isUpdate;
    copy._isDelete = _isDelete;
    copy._values = _values;
    copy._single = _single;
    copy._maybeSingle = _maybeSingle;
    return copy;
  }

  ApiQuery<List<Map<String, dynamic>>> select([String columns = '*']) {
    return _copyWithType<List<Map<String, dynamic>>>().._select = columns;
  }

  ApiQuery<T> eq(String column, dynamic value) {
    _filters[column] = value.toString();
    return this;
  }
  
  ApiQuery<T> like(String column, String value) {
    _filters[column] = value;
    return this;
  }
  
  ApiQuery<T> order(String column, {bool ascending = false}) {
    _orderBy = column;
    _ascending = ascending;
    return this;
  }
  
  ApiQuery<T> limit(int count) {
    _limit = count;
    return this;
  }

  ApiQuery<T> insert(Map<String, dynamic> values) {
    _isInsert = true;
    _values = values;
    return this;
  }

  ApiQuery<T> update(Map<String, dynamic> values) {
    _isUpdate = true;
    _values = values;
    return this;
  }
  
  ApiQuery<T> delete() {
    _isDelete = true;
    return this;
  }
  
  ApiQuery<Map<String, dynamic>> single() {
    return _copyWithType<Map<String, dynamic>>().._single = true;
  }
  
  ApiQuery<Map<String, dynamic>?> maybeSingle() {
    return _copyWithType<Map<String, dynamic>?>()
      .._single = true
      .._maybeSingle = true;
  }

  Future<T> _execute() async {
    if (_isInsert) {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/api/db/$schema/$table');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
        },
        body: json.encode(_values),
      );
      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (_single) {
           if (decoded is List) return decoded.first as T;
           return decoded as T;
        }
        return decoded as T;
      }
      throw Exception('Insert Error: ${response.statusCode} ${response.body}');
    } else if (_isUpdate) {
      if (_filters.isEmpty) {
        throw Exception('Update Error: missing matchColumn/matchValue for this REST API implementation');
      }
      final matchColumn = _filters.keys.first;
      final matchValue = _filters.values.first;
      final uri = Uri.parse('${AppConfig.supabaseUrl}/api/db/$schema/$table').replace(queryParameters: {
        'matchColumn': matchColumn,
        'matchValue': matchValue,
      });
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
        },
        body: json.encode(_values),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (_single) {
           if (decoded is List) return decoded.first as T;
           return decoded as T;
        }
        return decoded as T;
      }
      throw Exception('Update Error: ${response.statusCode} ${response.body}');
    } else if (_isDelete) {
      if (_filters.isEmpty) {
        throw Exception('Delete Error: missing matchColumn/matchValue for this REST API implementation');
      }
      final matchColumn = _filters.keys.first;
      final matchValue = _filters.values.first;
      final uri = Uri.parse('${AppConfig.supabaseUrl}/api/db/$schema/$table').replace(queryParameters: {
        'matchColumn': matchColumn,
        'matchValue': matchValue,
      });
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
        },
      );
      if (response.statusCode == 200) {
        return [] as T;
      }
      throw Exception('Delete Error: ${response.statusCode} ${response.body}');
    } else {
      final queryParams = {'select': _select, ..._filters};
      if (_orderBy != null) {
        queryParams['orderBy'] = _orderBy!;
        queryParams['ascending'] = _ascending.toString();
      }
      if (_limit != null) {
        queryParams['limit'] = _limit.toString();
      }
      final uri = Uri.parse('${AppConfig.supabaseUrl}/api/db/$schema/$table').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        // Dashboard and analytics reads are intentionally public.
        headers: const {},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final list = data.cast<Map<String, dynamic>>();
        if (_single) {
          if (list.isEmpty) {
            if (_maybeSingle) return null as T;
            throw Exception('No rows found');
          }
          return list.first as T;
        }
        return list as T;
      }
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Stream<T> asStream() => _execute().asStream();
  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) => _execute().catchError(onError, test: test);
  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) => _execute().then(onValue, onError: onError);
  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) => _execute().timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => _execute().whenComplete(action);
}

class ApiSchema {
  final String schema;
  ApiSchema(this.schema);
  ApiQuery<dynamic> from(String table) => ApiQuery<dynamic>(schema, table);

  Future<dynamic> rpc(String functionName, {Map<String, dynamic>? params}) async {
    final uri = Uri.parse('${AppConfig.supabaseUrl}/api/db/rpc/$schema/$functionName');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
      },
      body: json.encode(params ?? {}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('RPC Error: ${response.statusCode} ${response.body}');
  }
}

class DbSchema {
  DbSchema._();
  static const String principal = 'principal';
  static const String student = 'student';
  static const String faculty = 'faculty';
  static const String hod = 'hod';
  static const String timetable = 'timetable';
}
