import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'social_login_button.dart';

/// 시연/데모용 소셜 로그인(카카오 / 구글) 계정 선택 및 정보 제공 동의 다이얼로그
///
/// 사용자가 소셜 로그인 버튼을 눌렀을 때 바로 건너뛰지 않고,
/// 실제 OAuth 흐름처럼 계정 입력/선택 및 개인정보 제공 동의를 거친 뒤
/// 선택한 계정 식별자(이메일 또는 닉네임)를 반환합니다.
Future<String?> showSocialOAuthDialog({
  required BuildContext context,
  required SocialLoginType type,
  List<String> rememberedAccounts = const [],
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SocialOAuthDialog(
      type: type,
      rememberedAccounts: rememberedAccounts,
    ),
  );
}

class _SocialOAuthDialog extends StatefulWidget {
  final SocialLoginType type;
  final List<String> rememberedAccounts;

  const _SocialOAuthDialog({
    required this.type,
    required this.rememberedAccounts,
  });

  @override
  State<_SocialOAuthDialog> createState() => _SocialOAuthDialogState();
}

class _SocialOAuthDialogState extends State<_SocialOAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountController;
  String? _selectedRemembered;
  bool _agreed = true;
  String? _consentError;

  bool get _isKakao => widget.type == SocialLoginType.kakao;

  @override
  void initState() {
    super.initState();
    _selectedRemembered = widget.rememberedAccounts.isNotEmpty
        ? widget.rememberedAccounts.first
        : null;
    _accountController = TextEditingController(
      text: _selectedRemembered ?? '',
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_agreed) {
      setState(() {
        _consentError = '필수 정보 제공 동의에 체크해주세요.';
      });
      return;
    }
    setState(() {
      _consentError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_accountController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = _isKakao ? const Color(0xFFFEE500) : Colors.white;
    final headerFg = _isKakao ? const Color(0xFF191919) : AppColors.pointNavy;
    final primaryBtnBg =
        _isKakao ? const Color(0xFFFEE500) : const Color(0xFF1A73E8);
    final primaryBtnFg = _isKakao ? const Color(0xFF191919) : Colors.white;
    final title = _isKakao ? '카카오계정으로 로그인' : 'Google 계정으로 로그인';
    final hint = _isKakao
        ? '카카오 이메일 또는 아이디 (예: pipi@kakao.com)'
        : 'Google 이메일 또는 이름 (예: pipi@gmail.com)';
    final confirmLabel = _isKakao ? '동의하고 계속하기' : '계정으로 계속하기';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 브랜드 헤더
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(
                    bottom: BorderSide(
                      color: _isKakao
                          ? const Color(0xFFE5CD00)
                          : AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _isKakao
                            ? const KakaoLogoPainter()
                            : const GoogleLogoPainter(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: headerFg,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: Icon(Icons.close, size: 20, color: headerFg),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 서비스 연결 안내
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _isKakao
                              ? 'PIPI 서비스에 연결할 카카오계정을 선택하거나 입력하세요.'
                              : 'PIPI 서비스로 이동할 Google 계정을 선택하거나 입력하세요.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 이전 로그인 계정 빠른 선택
                      if (widget.rememberedAccounts.isNotEmpty) ...[
                        const Text(
                          '최근 로그인한 계정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.rememberedAccounts.map((acc) {
                          final selected = _selectedRemembered == acc &&
                              _accountController.text.trim() == acc;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _selectedRemembered = acc;
                                  _accountController.text = acc;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.pointNavy
                                        : AppColors.border,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle_rounded,
                                      size: 20,
                                      color: selected
                                          ? AppColors.pointNavy
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        acc,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: AppColors.pointNavy,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

                      // 계정 입력 필드
                      TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: _isKakao ? '카카오계정' : 'Google 계정',
                          hintText: hint,
                          hintStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.alternate_email_rounded,
                              size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        validator: (value) {
                          final trimmed = (value ?? '').trim();
                          if (trimmed.isEmpty) {
                            return '계정(이메일 또는 닉네임)을 입력해주세요.';
                          }
                          if (trimmed.length < 2) {
                            return '2자 이상 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 정보 제공 동의 체크박스
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _agreed = !_agreed;
                            if (_agreed) _consentError = null;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _agreed,
                              onChanged: (val) {
                                setState(() {
                                  _agreed = val ?? false;
                                  if (_agreed) _consentError = null;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                _isKakao
                                    ? '[필수] 카카오 프로필·이메일 정보 제공에 동의합니다.'
                                    : '[필수] Google 이름·이메일 주소 공유에 동의합니다.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_consentError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            _consentError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 하단 액션 버튼
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBtnBg,
                                foregroundColor: primaryBtnFg,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                confirmLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
