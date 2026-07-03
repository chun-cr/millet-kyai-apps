// 个人中心模块页面：`AccountSecurityPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/security/login_password_store.dart';
import 'package:millet_kyai_apps/features/auth/presentation/widgets/auth_top_toast.dart';

const _kAccountPageBg = Color(0xFFF4F1EB);
const _kAccountCardBg = Colors.white;
const _kAccountPrimary = Color(0xFF2D6A4F);
const _kAccountTextPrimary = Color(0xFF1E1810);
const _kAccountTextSecondary = Color(0xFF7A6F63);

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  bool? _hasLoginPassword;
  final _toastController = AuthTopToastController();

  @override
  void initState() {
    super.initState();
    _loadPasswordStatus();
  }

  @override
  void dispose() {
    _toastController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswordStatus() async {
    final hasPassword = await getIt<LoginPasswordStore>().hasLoginPassword();
    if (!mounted) {
      return;
    }
    setState(() => _hasLoginPassword = hasPassword);
  }

  Future<void> _openSetPasswordPage() async {
    final didSetPassword = await context.push<bool>(AppRoutes.setLoginPassword);
    if (!mounted) {
      return;
    }
    await _loadPasswordStatus();
    if (!mounted || didSetPassword != true) {
      return;
    }
    _toastController.show(
      context,
      context.l10n.setLoginPasswordSuccess,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = _hasLoginPassword;
    final statusText = hasPassword == null
        ? ''
        : hasPassword
        ? context.l10n.accountSecurityPasswordSet
        : context.l10n.accountSecurityPasswordUnset;

    return Scaffold(
      backgroundColor: _kAccountPageBg,
      appBar: AppBar(
        backgroundColor: _kAccountPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.accountSecurityTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kAccountTextPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: _kAccountCardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kAccountPrimary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.accountSecurityPhoneCodeTip,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: _kAccountTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openSetPasswordPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _kAccountPrimary.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _kAccountPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: _kAccountPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.accountSecurityLoginPassword,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kAccountTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.accountSecurityLoginPasswordSub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: _kAccountTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (statusText.isNotEmpty) ...[
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasPassword == true
                                    ? _kAccountPrimary
                                    : _kAccountTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _kAccountTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
