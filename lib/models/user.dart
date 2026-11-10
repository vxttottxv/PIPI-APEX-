/// PIPI 사용자 데이터 모델 클래스
///
/// 명세서 5. 데이터 모델:
/// - id: 사용자 고유 아이디
/// - passwordHash: SHA-256으로 해싱된 비밀번호 (평문 저장 금지)
/// - createdAt: 회원가입 일시
class User {
  /// 사용자 고유 아이디
  final String id;

  /// SHA-256 해시 처리된 비밀번호 문자열
  final String passwordHash;

  /// 계정 생성 일시 (선택적 메타데이터)
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.passwordHash,
    this.createdAt,
  });

  /// 백엔드 API 연동 및 로컬 SharedPreferences 저장을 위한 JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passwordHash': passwordHash,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// JSON 객체로부터 User 인스턴스를 역직렬화하여 생성
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// 객체 복사 및 특정 필드 수정을 위한 copyWith
  User copyWith({
    String? id,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $id, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.passwordHash == passwordHash;
  }

  @override
  int get hashCode => id.hashCode ^ passwordHash.hashCode;
}
