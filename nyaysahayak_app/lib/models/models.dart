// ─── Case Model ───────────────────────────────────────────────────────────────

class CaseModel {
  final String caseId;
  final String? incidentType;
  final String? riskLevel;
  final String? status;
  final String? createdAt;
  final Map<String, dynamic>? structuredReport;

  const CaseModel({
    required this.caseId,
    this.incidentType,
    this.riskLevel,
    this.status,
    this.createdAt,
    this.structuredReport,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    final report = json['structured_report'] as Map<String, dynamic>?;
    return CaseModel(
      caseId: json['case_id'] as String? ?? json['id'] as String? ?? '',
      incidentType: report?['incident_type'] as String? ?? 'Legal Case',
      riskLevel: report?['risk_level'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String?,
      structuredReport: report,
    );
  }
}

// ─── Lawyer Model ─────────────────────────────────────────────────────────────

class LawyerModel {
  final String uid;
  final String name;
  final String specialization;
  final String lawyerType;
  final int experience;
  final int hourlyRate;
  final String bio;
  final String location;
  final String avatar;
  final String contactNumber;
  final String email;
  final bool isOnline;

  const LawyerModel({
    required this.uid,
    required this.name,
    required this.specialization,
    required this.lawyerType,
    required this.experience,
    required this.hourlyRate,
    required this.bio,
    required this.location,
    required this.avatar,
    required this.contactNumber,
    required this.email,
    this.isOnline = false,
  });

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Lawyer',
      specialization: json['specialization'] as String? ?? 'General Law',
      lawyerType: json['lawyerType'] as String? ?? 'Consultant',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? 'India',
      avatar: json['avatar'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

// ─── Chat Message Model ───────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final String? agent;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.agent,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? agent,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      agent: agent ?? this.agent,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
    if (agent != null) 'agent': agent,
  };
}
