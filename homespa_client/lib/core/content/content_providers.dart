import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

/// Dashboard-editable app content (GET /content/*). Every provider falls
/// back to the app's built-in copy when the dashboard hasn't set a value.

class SupportContacts {
  final String? requestHelpPhone;
  final String? reportIssuePhone;
  const SupportContacts({this.requestHelpPhone, this.reportIssuePhone});
}

final supportContactsProvider = FutureProvider<SupportContacts>((ref) async {
  final json = await apiClient.get('/content/support') as Map<String, dynamic>;
  return SupportContacts(
    requestHelpPhone: json['requestHelpPhone'] as String?,
    reportIssuePhone: json['reportIssuePhone'] as String?,
  );
});

class ContentPage {
  final String? title;
  final String? body;
  const ContentPage({this.title, this.body});
  bool get hasBody => body != null && body!.trim().isNotEmpty;
}

/// key: 'terms' | 'privacy' | 'help'
final contentPageProvider = FutureProvider.family<ContentPage, String>((
  ref,
  key,
) async {
  final json = await apiClient.get('/content/page.$key') as Map<String, dynamic>;
  return ContentPage(title: json['title'] as String?, body: json['body'] as String?);
});

class IntakeQuestion {
  final String id;
  final String label;
  final String type; // single | multi | text | boolean
  final List<String> options;
  final bool required;
  const IntakeQuestion({
    required this.id,
    required this.label,
    required this.type,
    this.options = const [],
    this.required = false,
  });

  factory IntakeQuestion.fromJson(Map<String, dynamic> j) => IntakeQuestion(
    id: j['id'] as String,
    label: j['label'] as String,
    type: (j['type'] as String?) ?? 'text',
    options: ((j['options'] as List?) ?? const []).cast<String>(),
    required: j['required'] == true,
  );
}

/// Dashboard-defined intake questions; empty = app shows its built-in form.
final intakeFormProvider = FutureProvider<List<IntakeQuestion>>((ref) async {
  final json = await apiClient.get('/content/intake-form') as Map<String, dynamic>;
  return [
    for (final q in ((json['questions'] as List?) ?? const []).cast<Map<String, dynamic>>())
      IntakeQuestion.fromJson(q),
  ];
});
