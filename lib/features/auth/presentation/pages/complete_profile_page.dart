// 认证模块页面：`CompleteProfilePage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

part of 'register_page.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key, this.redirectLocation});

  final String? redirectLocation;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

const _kCompleteProfilePrimary = Color(0xFF6FA585);

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _toastController = AuthTopToastController();
  int _selectedGender = -1;
  bool _nicknameFocused = false;

  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  String? get _redirectLocation =>
      _normalizeAuthRedirectLocation(widget.redirectLocation);

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPasswordSetupPrompt();
    });
  }

  @override
  void dispose() {
    _toastController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowPasswordSetupPrompt() async {
    if (!getIt.isRegistered<LoginPasswordStore>()) {
      return;
    }
    final shouldShow = await getIt<LoginPasswordStore>()
        .consumePasswordSetupPrompt();
    if (!mounted || !shouldShow) {
      return;
    }
    _toastController.show(
      context,
      context.l10n.registerPasswordSetupPrompt,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 4),
    );
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    context.go(
      _buildAuthRouteLocation(
        AppRoutes.login,
        redirectLocation: _redirectLocation,
      ),
    );
  }

  Future<void> _completeOrSkip({required bool skip}) async {
    final hasSession = await getIt<AuthSessionStore>().hasSession();
    if (!mounted) {
      return;
    }

    if (!hasSession) {
      setPreviewAuthenticated(false);
      context.go(
        _buildAuthRouteLocation(
          AppRoutes.login,
          redirectLocation: _redirectLocation,
        ),
      );
      return;
    }

    if (!skip && !_formKey.currentState!.validate()) {
      return;
    }

    setPreviewAuthenticated(true);
    context.go(_redirectLocation ?? AppRoutes.home);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                '${context.l10n.appBrandPrefix}AI${context.l10n.appBrandSuffix}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2B23),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EEDC).withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6F9D7E,
                          ).withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Color(0xFF486451),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const ValueKey('complete_profile_skip_button'),
                  onPressed: () => _completeOrSkip(skip: true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF222A24),
                    minimumSize: const Size(44, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    context.l10n.completeProfileSkip,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStage() {
    return SizedBox(
      height: 182,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 8,
            child: Container(
              width: 176,
              height: 116,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDCEBDD).withValues(alpha: 0.90),
                    const Color(0xFFDCEBDD).withValues(alpha: 0.46),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            child: SizedBox(
              width: 162,
              height: 162,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) => Transform.rotate(
                      angle: _rotateController.value * 2 * math.pi,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: const Size(124, 124),
                      painter: const _SmallBaguaRingPainter(),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      final pulse = _pulseAnim.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            key: const ValueKey('complete_profile_avatar_ring'),
                            scale: pulse,
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kCompleteProfilePrimary.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                                color: _kCompleteProfilePrimary.withValues(
                                  alpha: 0.03,
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 2.0 - pulse,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFFC4AD7D,
                                  ).withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.56),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Container(
                    key: const ValueKey('complete_profile_avatar'),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7BA08A,
                          ).withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const CustomPaint(painter: _HarmonySealPainter()),
                  ),
                  const SizedBox(
                    width: 118,
                    height: 118,
                    child: _CornerBrackets(color: Color(0xFF8A9A89)),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: GestureDetector(
                      onTap: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          width: 33,
                          height: 33,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF89B394), Color(0xFF6F9D7E)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.92),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kCompleteProfilePrimary.withValues(
                                  alpha: 0.24,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameField(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _nicknameFocused = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8F3E6), Color(0xFFF3EEE0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _nicknameFocused
                ? _kCompleteProfilePrimary.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF7D9B80,
              ).withValues(alpha: _nicknameFocused ? 0.14 : 0.08),
              blurRadius: _nicknameFocused ? 18 : 14,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.28),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: TextFormField(
          controller: _nicknameCtrl,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1E1810)),
          decoration: InputDecoration(
            hintText: context.l10n.authNameHint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9B9584)),
            filled: false,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: _nicknameFocused
                  ? const Color(0xFF6D9378)
                  : const Color(0xFFC0B8A3),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.authNameHint;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return FormField<int>(
      initialValue: _selectedGender,
      validator: (_) =>
          _selectedGender == -1 ? context.l10n.registerGenderRequired : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    cardKey: const ValueKey('complete_profile_gender_male'),
                    icon: Icons.male_rounded,
                    label: context.l10n.registerGenderMale,
                    selected: _selectedGender == 0,
                    onTap: () {
                      setState(() => _selectedGender = 0);
                      field.didChange(0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GenderCard(
                    cardKey: const ValueKey('complete_profile_gender_female'),
                    icon: Icons.female_rounded,
                    label: context.l10n.registerGenderFemale,
                    selected: _selectedGender == 1,
                    onTap: () {
                      setState(() => _selectedGender = 1);
                      field.didChange(1);
                    },
                  ),
                ),
              ],
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E8).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.68),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7B61).withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.34),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.completeProfileTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171712),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.completeProfileSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: const Color(0xFF464034).withValues(alpha: 0.78),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                _InputLabel(text: context.l10n.authNameLabel),
                const SizedBox(height: 8),
                _buildNicknameField(context),
                const SizedBox(height: 18),
                _InputLabel(text: context.l10n.registerGenderOptional),
                const SizedBox(height: 10),
                _buildGenderField(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final seasonalTag = context.l10n.seasonalTagLabel(SeasonalContext.now());

    return Container(
      key: const ValueKey('complete_profile_bottom_bar'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC9A84C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seasonalTag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC9A84C),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC9A84C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                key: const ValueKey('complete_profile_primary_button'),
                onTap: () => _completeOrSkip(skip: false),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9BC79D), Color(0xFF74A97D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5D8A67).withValues(alpha: 0.28),
                        blurRadius: 26,
                        spreadRadius: 1,
                        offset: const Offset(0, 11),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.completeProfileStart,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E7),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF5F0E5), Color(0xFFF8F4ED)],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) => CustomPaint(
                    painter: _CompleteProfileBgPainter(
                      rotation: _rotateController.value * math.pi * 2,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _buildHeader(context),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildAvatarStage(),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 118,
                                  bottom: 0,
                                  child: _buildContentCard(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildBottomActionBar(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegBgPainter extends CustomPainter {
  final double rotation;
  const _RegBgPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    // 右上金色光晕
    canvas.drawCircle(
      Offset(size.width + 30, -30),
      190,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFC9A84C).withValues(alpha: 0.07),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width + 30, -30),
                radius: 190,
              ),
            ),
    );
    // 宸︿笅澧ㄧ豢鍏夋檿
    canvas.drawCircle(
      Offset(-40, size.height + 30),
      200,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF2D6A4F).withValues(alpha: 0.09),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(-40, size.height + 30),
                radius: 200,
              ),
            ),
    );
    // 格纹。
    final g = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    // 左上角旋转装饰圈。
    canvas.save();
    canvas.translate(24, 180);
    canvas.rotate(rotation);
    final rp = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 44, rp);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * 37, math.sin(a) * 37),
        Offset(math.cos(a) * 44, math.sin(a) * 44),
        rp,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RegBgPainter old) => old.rotation != rotation;
}

class _CompleteProfileBgPainter extends CustomPainter {
  final double rotation;

  const _CompleteProfileBgPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawRipple(
      Offset center,
      double baseRadius,
      Color color,
      List<double> factors,
    ) {
      for (final factor in factors) {
        ripplePaint
          ..color = color.withValues(alpha: 0.08 / factor.clamp(1, 3))
          ..strokeWidth = factor == factors.first ? 1.2 : 0.9;
        canvas.drawCircle(center, baseRadius * factor, ripplePaint);
      }
    }

    canvas.drawCircle(
      Offset(size.width * 0.9, -12),
      112,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFA3C39A).withValues(alpha: 0.56),
                const Color(0xFFA3C39A).withValues(alpha: 0.18),
                Colors.transparent,
              ],
              stops: const [0, 0.55, 1],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.9, -12),
                radius: 112,
              ),
            ),
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, 56),
      130,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFE8F1E4).withValues(alpha: 0.9),
                const Color(0xFFE8F1E4).withValues(alpha: 0.28),
                Colors.transparent,
              ],
              stops: const [0, 0.55, 1],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.52, 56),
                radius: 130,
              ),
            ),
    );

    final grainPaint = Paint()
      ..color = const Color(0xFFAA9E85).withValues(alpha: 0.035)
      ..strokeWidth = 0.7;
    for (double y = 0; y < size.height; y += 14) {
      final shift = math.sin(y / 28 + rotation) * 4;
      canvas.drawLine(
        Offset(-8, y),
        Offset(size.width + shift, y + math.cos(y / 36 + rotation) * 1.6),
        grainPaint,
      );
    }

    drawRipple(
      Offset(size.width * 0.08, size.height * 0.22),
      26,
      const Color(0xFF8FA38B),
      const [1, 1.9, 2.8],
    );
    drawRipple(
      Offset(size.width * 0.93, size.height * 0.22),
      18,
      const Color(0xFF9AB89C),
      const [1, 1.75, 2.5, 3.2],
    );
    drawRipple(
      Offset(size.width * 0.86, size.height * 0.72),
      24,
      const Color(0xFF9EAF9B),
      const [1, 1.8, 2.6, 3.3],
    );
    drawRipple(
      Offset(size.width * 0.07, size.height * 0.78),
      20,
      const Color(0xFFB1A587),
      const [1, 1.9, 2.7],
    );

    canvas.save();
    canvas.translate(size.width * 0.5, 118);
    canvas.rotate(rotation * 0.14);
    final sealPaint = Paint()
      ..color = _kCompleteProfilePrimary.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 48, sealPaint);
    canvas.drawCircle(
      Offset.zero,
      35,
      Paint()
        ..color = const Color(0xFFC4AD7D).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompleteProfileBgPainter old) => old.rotation != rotation;
}

class _SmallBaguaRingPainter extends CustomPainter {
  const _SmallBaguaRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final ringPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    final innerRingPaint = Paint()
      ..color = const Color(0xFFC7A45E).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius - 6, innerRingPaint);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(a) * (radius - 8),
          center.dy + math.sin(a) * (radius - 8),
        ),
        Offset(
          center.dx + math.cos(a) * radius,
          center.dy + math.sin(a) * radius,
        ),
        ringPaint,
      );
    }
    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * (radius - 1.5),
          center.dy + math.sin(angle) * (radius - 1.5),
        ),
        i.isEven ? 1.15 : 0.8,
        Paint()
          ..color =
              (i % 3 == 0 ? const Color(0xFFC7A45E) : const Color(0xFF6E9B80))
                  .withValues(alpha: i.isEven ? 0.18 : 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HarmonySealPainter extends CustomPainter {
  const _HarmonySealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2 - 3;
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final emblemRadius = outerRadius - 5;
    final emblemRect = Rect.fromCircle(center: center, radius: emblemRadius);

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.22),
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFFD4E6D5).withValues(alpha: 0.78),
            const Color(0xFFA8C6AF).withValues(alpha: 0.38),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(outerRect),
    );

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: 0.82),
            const Color(0xFF7DA589).withValues(alpha: 0.45),
            const Color(0xFFD7B87E).withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.82),
          ],
        ).createShader(outerRect),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius - 2),
      -math.pi * 0.9,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.38),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 8);
    canvas.translate(-center.dx, -center.dy);

    const lightColor = Color(0xFFEFF7EB);
    const darkColor = Color(0xFF355748);
    canvas.drawCircle(center, emblemRadius, Paint()..color = lightColor);
    canvas.drawArc(
      emblemRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = darkColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - emblemRadius / 2),
      emblemRadius / 2,
      Paint()..color = darkColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + emblemRadius / 2),
      emblemRadius / 2,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - emblemRadius / 2),
      emblemRadius / 7,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + emblemRadius / 2),
      emblemRadius / 7,
      Paint()..color = darkColor,
    );
    canvas.restore();

    final heartbeatPaint = Paint()
      ..color = const Color(0xFFC4A05C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final heartbeatPath = Path()
      ..moveTo(center.dx - outerRadius * 0.96, center.dy + outerRadius * 0.1)
      ..lineTo(center.dx - outerRadius * 0.58, center.dy + outerRadius * 0.1)
      ..lineTo(center.dx - outerRadius * 0.36, center.dy - outerRadius * 0.04)
      ..lineTo(center.dx - outerRadius * 0.14, center.dy + outerRadius * 0.24)
      ..lineTo(center.dx + outerRadius * 0.05, center.dy - outerRadius * 0.34)
      ..lineTo(center.dx + outerRadius * 0.18, center.dy + outerRadius * 0.02)
      ..lineTo(center.dx + outerRadius * 0.42, center.dy + outerRadius * 0.02)
      ..lineTo(center.dx + outerRadius * 0.72, center.dy + outerRadius * 0.02);
    canvas.drawPath(heartbeatPath, heartbeatPaint);

    final leafPath = Path()
      ..moveTo(center.dx + outerRadius * 0.48, center.dy - outerRadius * 0.12)
      ..quadraticBezierTo(
        center.dx + outerRadius * 0.74,
        center.dy - outerRadius * 0.38,
        center.dx + outerRadius * 0.74,
        center.dy - outerRadius * 0.02,
      )
      ..quadraticBezierTo(
        center.dx + outerRadius * 0.56,
        center.dy + outerRadius * 0.02,
        center.dx + outerRadius * 0.48,
        center.dy - outerRadius * 0.12,
      );
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = const Color(0xFFD4B378).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(center.dx + outerRadius * 0.54, center.dy - outerRadius * 0.1),
      Offset(center.dx + outerRadius * 0.67, center.dy - outerRadius * 0.22),
      Paint()
        ..color = const Color(0xFFF6E8C9).withValues(alpha: 0.75)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.3,
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1A12).withValues(alpha: 0.92),
      ),
    );
  }
}

class _RegisterModeTab extends StatelessWidget {
  const _RegisterModeTab({
    required this.tabKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key tabKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tabKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0x4A7FAF92),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, -1),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: selected ? 1 : 0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xC89FD0AF),
                          Color(0xB28CC3A1),
                          Color(0xA6B7DAC3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.52, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x667EAE91),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: selected ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF2A4336)
                        : const Color(0xFF6A645A),
                  ),
                  child: Text(label, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  final Color color;

  const _CornerBrackets({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 10, left: 10, child: _Bracket(color: color, tl: true)),
        Positioned(top: 10, right: 10, child: _Bracket(color: color, tr: true)),
        Positioned(
          bottom: 10,
          left: 10,
          child: _Bracket(color: color, bl: true),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: _Bracket(color: color, br: true),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final Key? cardKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    this.cardKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: cardKey,
        duration: const Duration(milliseconds: 200),
        height: 92,
        transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF7F1E6), Color(0xFFF3ECDD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF76A883).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.68),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: _kCompleteProfilePrimary.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: const Color(0xFF8C7E6A).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? const Color(0xFF5A8466)
                  : const Color(0xFF75886F),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF181410),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final bool tl, tr, bl, br;
  const _Bracket({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          left: (tl || bl)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          right: (tr || br)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          bottom: (bl || br)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
        ),
      ),
    );
  }
}
