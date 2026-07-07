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
