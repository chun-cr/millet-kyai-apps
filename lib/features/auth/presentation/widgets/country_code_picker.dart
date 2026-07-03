import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 国家区号选择项。
///
/// `searchTerms` 预留给后续搜索态使用，`preferred` 用于在产品需要时把常用国家前置。
class CountryCodeOption {
  const CountryCodeOption({
    required this.name,
    required this.code,
    required this.flag,
    required this.searchTerms,
    this.preferred = false,
  });

  final String name;
  final String code;
  final String flag;
  final List<String> searchTerms;
  final bool preferred;
}

const List<CountryCodeOption> authCountryCodeOptions = [
  CountryCodeOption(
    name: '中国',
    code: '+86',
    flag: '🇨🇳',
    searchTerms: ['中国', 'china', 'cn', '+86'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '英国',
    code: '+44',
    flag: '🇬🇧',
    searchTerms: ['英国', 'united kingdom', 'uk', 'britain', 'england', '+44'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '西班牙',
    code: '+34',
    flag: '🇪🇸',
    searchTerms: ['西班牙', 'spain', 'es', '+34'],
  ),
  CountryCodeOption(
    name: '葡萄牙',
    code: '+351',
    flag: '🇵🇹',
    searchTerms: ['葡萄牙', 'portugal', 'pt', '+351'],
  ),
  CountryCodeOption(
    name: '法国',
    code: '+33',
    flag: '🇫🇷',
    searchTerms: ['法国', 'france', 'fr', '+33'],
  ),
  CountryCodeOption(
    name: '德国',
    code: '+49',
    flag: '🇩🇪',
    searchTerms: ['德国', 'germany', 'de', '+49'],
  ),
  CountryCodeOption(
    name: '日本',
    code: '+81',
    flag: '🇯🇵',
    searchTerms: ['日本', 'japan', 'jp', '+81'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '韩国',
    code: '+82',
    flag: '🇰🇷',
    searchTerms: ['韩国', 'korea', 'kr', '+82'],
    preferred: true,
  ),
];

/// 登录页使用的轻量区号弹层。
///
/// 这里没有直接使用标准下拉组件，而是自定义 overlay，目的是同时满足：
/// 1. 锚定在输入框前缀旁边；
/// 2. 保留玻璃质感和缩放动画；
/// 3. 在父组件频繁 rebuild 时仍能稳定开合。
class CountryCodePopoverPicker extends StatefulWidget {
  const CountryCodePopoverPicker({
    super.key,
    required this.flag,
    required this.code,
    required this.options,
    required this.onSelected,
    this.maxPopoverHeight = 280,
    this.menuWidth = 216,
  });

  final String flag;
  final String code;
  final List<CountryCodeOption> options;
  final ValueChanged<CountryCodeOption> onSelected;
  final double maxPopoverHeight;
  final double menuWidth;

  @override
  State<CountryCodePopoverPicker> createState() =>
      _CountryCodePopoverPickerState();
}

class _CountryCodePopoverPickerState extends State<CountryCodePopoverPicker>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _scrollHapticTimer;
  late final AnimationController _menuController;
  late final Animation<double> _menuOpacity;
  late final Animation<double> _menuScale;
  bool _pressed = false;
  bool _open = false;
  bool _overlayRebuildQueued = false;
  double _lastHapticPixels = 0;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _menuOpacity = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _menuScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CountryCodePopoverPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRefreshOverlay =
        oldWidget.code != widget.code ||
        oldWidget.flag != widget.flag ||
        oldWidget.maxPopoverHeight != widget.maxPopoverHeight ||
        oldWidget.menuWidth != widget.menuWidth ||
        !identical(oldWidget.options, widget.options);
    if (_open && shouldRefreshOverlay) {
      // OverlayEntry 不会随着宿主 widget 的 rebuild 自动刷新，
      // 选中值或布局参数变化时需要显式请求下一帧重建。
      _queueOverlayRebuild();
    }
  }

  @override
  void dispose() {
    _scrollHapticTimer?.cancel();
    _removeOverlay(immediate: true);
    _menuController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  Future<void> _togglePopover() async {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    if (_open) {
      await _hidePopover();
    } else {
      await _showPopover();
    }
  }

  Future<void> _showPopover() async {
    if (_open) {
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    _open = true;
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {});
    }
    await _menuController.forward(from: 0);
  }

  Future<void> _hidePopover({CountryCodeOption? selection}) async {
    if (!_open) {
      return;
    }
    _open = false;
    if (mounted) {
      setState(() {});
    }
    await _menuController.reverse();
    _removeOverlay();
    if (selection != null) {
      widget.onSelected(selection);
    }
  }

  void _removeOverlay({bool immediate = false}) {
    if (immediate) {
      _menuController.stop();
      _menuController.value = 0;
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayRebuildQueued = false;
  }

  void _queueOverlayRebuild() {
    if (_overlayRebuildQueued) {
      return;
    }
    _overlayRebuildQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildQueued = false;
      if (!mounted || !_open) {
        return;
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final mediaQuery = MediaQuery.of(overlayContext);
    final renderObject = _targetKey.currentContext?.findRenderObject();
    final targetBox = renderObject is RenderBox ? renderObject : null;
    final overlayBox = Overlay.of(overlayContext).context.findRenderObject();
    final rootBox = overlayBox is RenderBox ? overlayBox : null;
    final targetOffset = (targetBox != null && rootBox != null)
        ? targetBox.localToGlobal(Offset.zero, ancestor: rootBox)
        : Offset.zero;
    final targetSize = targetBox?.size ?? Size.zero;
    final safeBottom = mediaQuery.padding.bottom + 14;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    // 弹层总是锚定在触发器下方，并把安全区和输入法都计入剩余空间，
    // 避免小屏或键盘弹起时列表被直接裁到屏幕外。
    final availableBelow =
        mediaQuery.size.height -
        keyboardInset -
        targetOffset.dy -
        targetSize.height -
        16 -
        safeBottom;
    final popoverHeight = math
        .max(120, math.min(widget.maxPopoverHeight, availableBelow))
        .toDouble();
    final popoverWidth = math
        .min(widget.menuWidth, mediaQuery.size.width - 24)
        .toDouble();

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hidePopover,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: FadeTransition(
                opacity: _menuOpacity,
                child: ScaleTransition(
                  scale: _menuScale,
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - _menuOpacity.value)),
                    child: _CountryCodePopoverSurface(
                      key: const ValueKey('country_code_popover_surface'),
                      width: popoverWidth,
                      maxHeight: popoverHeight,
                      selectedCode: widget.code,
                      options: widget.options,
                      onItemTap: (option) async {
                        HapticFeedback.lightImpact();
                        await _hidePopover(selection: option);
                      },
                      onScroll: _handleScroll,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScroll(double pixels) {
    if ((pixels - _lastHapticPixels).abs() < 42) {
      return;
    }
    _lastHapticPixels = pixels;
    // ScrollUpdate 通知非常密集，这里做一个极轻的节流，避免连续震动。
    _scrollHapticTimer?.cancel();
    _scrollHapticTimer = Timer(const Duration(milliseconds: 16), () {
      HapticFeedback.selectionClick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _targetKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _togglePopover,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.986 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            opacity: _pressed ? 0.82 : 1,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1810),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    turns: _open ? 0.5 : 0,
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 11,
                      color: const Color(0xFFA09080).withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 0.8,
                    height: 18,
                    color: const Color(0xFF1E1810).withValues(alpha: 0.08),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryCodePopoverSurface extends StatelessWidget {
  const _CountryCodePopoverSurface({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.options,
    required this.selectedCode,
    required this.onItemTap,
    required this.onScroll,
  });

  final double width;
  final double maxHeight;
  final List<CountryCodeOption> options;
  final String selectedCode;
  final ValueChanged<CountryCodeOption> onItemTap;
  final ValueChanged<double> onScroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                onScroll(notification.metrics.pixels);
                return false;
              },
              child: ListView.separated(
                key: const ValueKey('country_code_popover_list'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                primary: false,
                itemCount: options.length,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.code == selectedCode;
                  return _CountryCodePopoverItem(
                    option: option,
                    selected: selected,
                    onTap: () => onItemTap(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryCodePopoverItem extends StatelessWidget {
  const _CountryCodePopoverItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CountryCodeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('country_code_picker_item_${option.code}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(option.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1E1810),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              option.code,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFF6C7480),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
