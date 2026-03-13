class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final AgentAction? action;
  final String? languageHint;
  final String? ttsMessage;
  final String? ttsLanguageHint;
  final bool isLoading;
  final String? imagePath;
  final bool isLocalImage;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.action,
    this.languageHint,
    this.ttsMessage,
    this.ttsLanguageHint,
    this.isLoading = false,
    this.imagePath,
    this.isLocalImage = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isLoading': isLoading,
        'languageHint': languageHint,
        'ttsMessage': ttsMessage,
        'ttsLanguageHint': ttsLanguageHint,
      };

  Map<String, dynamic> toApiMessage() => {
        'role': role,
        'content': content,
      };
}

class AgentAction {
  final String type; // 'navigate', 'confirm', 'display_data', 'text'
  final String? route;
  final String? dataType;
  final dynamic data;
  final String? confirmAction;
  final dynamic confirmPayload;
  final String? message;

  AgentAction({
    required this.type,
    this.route,
    this.dataType,
    this.data,
    this.confirmAction,
    this.confirmPayload,
    this.message,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      type: json['type'] ?? 'text',
      route: json['route'],
      dataType: json['dataType'],
      data: json['data'],
      confirmAction: json['confirmAction'],
      confirmPayload: json['confirmPayload'],
      message: json['message'],
    );
  }
}

class AgentResponse {
  final String message;
  final AgentAction? action;
  final String? languageHint;
  final String? ttsMessage;
  final String? ttsLanguageHint;

  AgentResponse({
    required this.message, 
    this.action, 
    this.languageHint,
    this.ttsMessage,
    this.ttsLanguageHint,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      message: json['message'] ?? '',
      action: json['action'] != null
          ? AgentAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      languageHint: json['languageHint'],
      ttsMessage: json['ttsMessage'],
      ttsLanguageHint: json['ttsLanguageHint'],
    );
  }
}
