part of 'login_page.dart';

/// 登录页的纯视图层。
///
/// `login_page.dart` 主文件保留状态与事件入口，这个 mixin 只负责布局、
/// 动画和交互壳层，避免一个超大 State 同时承担“逻辑 + UI”两种职责。
mixin _LoginPageView
    on
        ConsumerState<LoginPage>,
        VerificationCodeFlowMixin<LoginPage>,
        _LoginPageLogic {
  Animation<double> get _breatheAnim;
  Animation<double> get _btnScaleAnim;
  AnimationController get _btnScaleCtrl;
  Listenable get _formFieldsListenable;
  bool get _isBusy;
  bool get _obscurePass;
  bool get _agreeTerms;
  set _agreeTerms(bool value);
  @override
  set _obscurePass(bool value);
  bool get _wechatLoginLoading;
  _LoginButtonPhase get _buttonPhase;
  String get _selectedCountryFlag;
  set _selectedCountryFlag(String value);
  set _selectedCountryCode(String value);
  List<CountryCodeOption> get _countryCodes;
  Future<void> _onSendCode();
  Future<void> _onLogin();
  Future<void> _onWechatMiniProgramLogin();

  Widget _buildBackground() {
    return const RepaintBoundary(
      child: CustomPaint(painter: _LoginBgPainter()),
    );
  }

  Widget _buildBrandRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF46745F), Color(0xFF7BAA90)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22618674),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: _BrandMark()),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF233528),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    children: [
                      TextSpan(text: context.l10n.appBrandPrefix),
                      const TextSpan(
                        text: 'AI',
                        style: TextStyle(color: Color(0xFF4F8C70)),
                      ),
                      TextSpan(text: context.l10n.appBrandSuffix),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: const AuthLocaleButton(key: ValueKey('login_locale_button')),
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return Center(
      child: AnimatedBuilder(
        animation: _breatheAnim,
        builder: (context, child) {
          return Transform.scale(scale: _breatheAnim.value, child: child);
        },
        child: SizedBox(
          width: 154,
          height: 154,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.08, -0.16),
                    colors: [
                      Colors.white.withValues(alpha: 0.58),
                      const Color(0xFFE7F4E7).withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              Container(
                width: 126,
                height: 126,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4794BDA5),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _breatheAnim,
                builder: (_, child) => Opacity(
                  opacity: (0.88 + (_breatheAnim.value - 0.96) * 2.0).clamp(
                    0.0,
                    1.0,
                  ),
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size(136, 136),
                  painter: const _BaguaRingPainter(),
                ),
              ),
              const _CornerBrackets(color: Color(0xFF6D8275)),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFDFEFB), Color(0xFFD5E8D7)],
                  ),
                  border: Border.all(
                    color: const Color(0xAAFFFFFF),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x365E836F),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.24),
                    radius: 0.92,
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      const Color(0xFFC8DDCA).withValues(alpha: 0.58),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 34,
                      color: Color(0xFF4D6E5E),
                    ),
                    Positioned(
                      top: 18,
                      right: 16,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 10,
                          color: Color(0xFFC9A55C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ornamentLine(),
                const SizedBox(width: 10),
                Text(
                  context.l10n.authInspectionMotto,
                  style: const TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 2.8,
                    color: Color(0xFF5B5A53),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                _ornamentLine(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalFadeTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final begin = Offset(_isPasswordLogin ? 0.08 : -0.08, 0);
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  Widget _buildModeFadeTransition(Widget child, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slidesFromRight = child.key == const ValueKey('email_input_area');
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(slidesFromRight ? 0.12 : -0.12, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  Widget _buildInputArea() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: _buildModeFadeTransition,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ...switch (currentChild) {
                null => const <Widget>[],
                final child => <Widget>[child],
              },
            ],
          );
        },
        child: _isEmailLogin ? _buildEmailInputArea() : _buildPhoneInputArea(),
      ),
    );
  }

  Widget _buildPhoneInputArea() {
    return Column(
      key: const ValueKey('phone_input_area'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhoneField(),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _buildHorizontalFadeTransition,
          child: _usesPasswordCredential
              ? _buildPasswordField()
              : _buildCodeField(),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _buildHorizontalFadeTransition,
          child: _buildFieldsFooter(),
        ),
      ],
    );
  }

  Widget _buildEmailInputArea() {
    return Column(
      key: const ValueKey('email_input_area'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEmailField(),
        const SizedBox(height: 12),
        _buildCodeField(),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      key: const ValueKey('phone_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authPhoneLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handlePhoneChanged,
          cursorColor: const Color(0xFF5D826D),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF2F281F),
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hint: context.l10n.authPhoneHint,
            prefixIcon: _buildCountryCodePrefix(),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          validator: _validatePhone,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      key: const ValueKey('email_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authEmailLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleEmailChanged,
          cursorColor: const Color(0xFF5D826D),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF2F281F),
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hint: context.l10n.authEmailHint,
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 18,
              color: Color(0xFFC0AF98),
            ),
          ),
          validator: _validateEmail,
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    final l10n = context.l10n;
    final maskedReceiver = _maskedReceiver;
    return Column(
      key: const ValueKey('code_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: l10n.authVerificationCodeLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(kVerificationCodeLength),
          ],
          onChanged: dismissVerificationCodeInputIfComplete,
          cursorColor: const Color(0xFF5D826D),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF2F281F),
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hint: l10n.authVerificationCodeHint,
            prefixIcon: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: Color(0xFFC0AF98),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 94,
              minHeight: 56,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _codeSending
                    ? const SizedBox(
                        key: ValueKey('send_code_loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6FA585),
                        ),
                      )
                    : _codeCountingDown
                    ? Text(
                        l10n.authResendCode(_codeCountdown),
                        key: const ValueKey('send_code_countdown'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB28749),
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      )
                    : TextButton(
                        key: const ValueKey('send_code_button'),
                        onPressed: _onSendCode,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.authSendCode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB28749),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) =>
              (!_usesPasswordCredential &&
                  (v == null || v.trim().length != kVerificationCodeLength))
              ? l10n.authVerificationCodeHint
              : null,
        ),
        if (!_usesPasswordCredential &&
            maskedReceiver != null &&
            maskedReceiver.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.authCodeSentToReceiver(maskedReceiver),
            key: const ValueKey('login_masked_receiver_hint'),
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF5A5349).withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({Key? fieldKey}) {
    return Column(
      key: fieldKey ?? const ValueKey('password_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authPasswordLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          cursorColor: const Color(0xFF5D826D),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF2F281F),
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hint: context.l10n.authPasswordHint,
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 18,
              color: Color(0xFFC0AF98),
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFFC0AF98),
              ),
            ),
          ),
          validator: (v) {
            if (!_usesPasswordCredential) {
              return null;
            }
            if (v == null || v.isEmpty) {
              return context.l10n.authPasswordHint;
            }
            if (v.length < 6) {
              return context.l10n.authPasswordMin6;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFieldsFooter() {
    return Row(
      key: ValueKey(
        _isPasswordLogin ? 'password_fields_footer' : 'code_fields_footer',
      ),
      children: [
        TextButton(
          key: ValueKey(
            _isPasswordLogin
                ? 'switch_to_code_login'
                : 'switch_to_password_login',
          ),
          onPressed: _togglePhoneAuthMode,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isPasswordLogin
                ? context.l10n.authCodeLogin
                : context.l10n.authPasswordLogin,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6C8C77),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (_isPasswordLogin) _buildForgotPasswordButton(),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: const Color(0xFFF9F7F2),
            title: Text(
              context.l10n.authForgotPassword,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D6A4F),
              ),
            ),
            content: Text(
              context.l10n.authForgotPasswordTip,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.commonConfirm,
                  style: const TextStyle(
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        context.l10n.authForgotPassword,
        style: TextStyle(
          fontSize: 12,
          color: const Color(0xFF8A7B68),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Column(
      key: const ValueKey('login_agreement_visible'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildTermsRow(), const SizedBox(height: 18)],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      key: const ValueKey('login_terms_row'),
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
              gradient: _agreeTerms
                  ? const LinearGradient(
                      colors: [Color(0xFF7AA98E), Color(0xFF98C4AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: _agreeTerms
                    ? Colors.transparent
                    : const Color(0xFFE0D6C8),
                width: 1.2,
              ),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF534B41).withValues(alpha: 0.82),
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: context.l10n.registerReadAndAgree),
                  const TextSpan(text: ' ', style: TextStyle(fontSize: 12)),
                  TextSpan(
                    text: context.l10n.registerUserAgreement,
                    style: const TextStyle(
                      color: Color(0xFF3D7B61),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerAnd),
                  TextSpan(
                    text: context.l10n.registerPrivacyPolicy,
                    style: const TextStyle(
                      color: Color(0xFF3D7B61),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerHealthDataClause),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCodePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryCodePopoverPicker(
            key: const ValueKey('country_code_menu_trigger'),
            flag: _selectedCountryFlag,
            code: _selectedCountryCode,
            options: _countryCodes,
            onSelected: (selected) {
              setState(() {
                // 验证码和区号是绑定的；切换国家区号后必须清掉旧验证码状态，
                // 避免用户继续提交先前区号申请到的短信码。
                if (_codeTargetCountryCode != null &&
                    _codeTargetCountryCode != selected.code) {
                  resetVerificationCodeState();
                }
                _selectedCountryCode = selected.code;
                _selectedCountryFlag = selected.flag;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return AnimatedBuilder(
      animation: _formFieldsListenable,
      builder: (context, _) {
        final isEnabled = !_isBusy && _hasPrimaryActionRequirements;
        final buttonColors = _buttonPhase == _LoginButtonPhase.submitting
            ? const [Color(0xFF689676), Color(0xFF729D7D), Color(0xFF658F73)]
            : isEnabled
            ? const [Color(0xFF79AC85), Color(0xFF7FAE8A), Color(0xFF74A380)]
            : const [Color(0xFFC9D0CA), Color(0xFFBEC6BF), Color(0xFFB2BBB3)];
        final shadowColor = _buttonPhase == _LoginButtonPhase.submitting
            ? const Color(0xFF76A784).withValues(alpha: 0.14)
            : isEnabled
            ? const Color(0xFF76A784).withValues(alpha: 0.34)
            : const Color(0xFF99A39C).withValues(alpha: 0.18);
        final shadowBlur = _buttonPhase == _LoginButtonPhase.submitting
            ? 12.0
            : isEnabled
            ? 20.0
            : 10.0;
        final shadowOffsetY = _buttonPhase == _LoginButtonPhase.submitting
            ? 4.0
            : isEnabled
            ? 8.0
            : 4.0;

        return GestureDetector(
          key: const ValueKey('login_primary_button'),
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled
              ? (_) {
                  HapticFeedback.lightImpact();
                  _btnScaleCtrl.forward();
                }
              : null,
          onTap: isEnabled ? _onLogin : null,
          onTapUp: isEnabled ? (_) => _btnScaleCtrl.reverse() : null,
          onTapCancel: isEnabled ? () => _btnScaleCtrl.reverse() : null,
          child: AnimatedBuilder(
            animation: _btnScaleAnim,
            builder: (context, child) =>
                Transform.scale(scale: _btnScaleAnim.value, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: buttonColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: shadowBlur,
                    offset: Offset(0, shadowOffsetY),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Center(child: _buildButtonContent(context)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _hasPrimaryActionRequirements {
    if (!_agreeTerms || _currentAccountValue.isEmpty) {
      return false;
    }
    if (_usesPasswordCredential) {
      return _passCtrl.text.isNotEmpty;
    }
    return _codeCtrl.text.trim().length == kVerificationCodeLength;
  }

  Widget _buildButtonContent(BuildContext context) {
    final idleLabel = _usesPasswordCredential
        ? context.l10n.authLoginButton
        : context.l10n.commonContinue;
    final submittingLabel = _usesPasswordCredential
        ? context.l10n.authLoggingIn
        : context.l10n.commonContinue;
    final label = Text(
      idleLabel,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
        ),
      );

    // 外层按钮的尺寸、渐变和阴影始终保持不变，只切换中心内容，
    // 这样 loading 态不会造成整颗按钮的宽高跳动。
    switch (_buttonPhase) {
      case _LoginButtonPhase.idle:
        return Center(key: const ValueKey('login_idle'), child: label);
      case _LoginButtonPhase.submitting:
        return Row(
          key: const ValueKey('login_submitting'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              submittingLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBottomAuxiliarySections() {
    return Container(
      key: const ValueKey('login_bottom_auxiliary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          _buildOrDivider(),
          const SizedBox(height: 14),
          _buildSocialRow(),
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Center(
      child: Text(
        context.l10n.authOtherMethods,
        style: TextStyle(
          fontSize: 12.5,
          color: const Color(0xFF4B433B).withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            buttonKey: const ValueKey('login_wechat_button'),
            icon: Icons.wechat,
            iconColor: const Color(0xFF07C160),
            label: context.l10n.authWechatLogin,
            labelColor: const Color(0xFF1E1810),
            loading: _wechatLoginLoading,
            onTap: _onWechatMiniProgramLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            buttonKey: const ValueKey('login_email_button'),
            icon: _isEmailLogin
                ? Icons.phone_iphone_rounded
                : Icons.email_outlined,
            iconColor: const Color(0xFF3A3028),
            label: _isEmailLogin
                ? context.l10n.authPhoneLogin
                : context.l10n.authEmailLogin,
            labelColor: const Color(0xFF3A3028),
            onTap: _toggleIdentityLoginMode,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? prefix,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
    BoxConstraints? suffixIconConstraints,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFB6A58E)),
      filled: true,
      fillColor: const Color(0xFFFFFCF7),
      prefixIcon: prefixIcon,
      prefixIconConstraints:
          prefixIconConstraints ??
          const BoxConstraints(minWidth: 48, minHeight: 56),
      prefix: prefix,
      suffixIcon: suffixIcon != null
          ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon)
          : null,
      suffixIconConstraints: suffixIcon != null
          ? suffixIconConstraints ??
                const BoxConstraints(minWidth: 52, minHeight: 56)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      errorStyle: const TextStyle(fontSize: 11.5, height: 1.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFECE3D6), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFECE3D6), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF8CAD98), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.red.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }

  Widget _ornamentLine() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 1,
          color: const Color(0xFF8D8377).withValues(alpha: 0.42),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8D8377).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
