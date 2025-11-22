import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../core/providers/settings_provider.dart';
import '../../model/pages/default_model_page.dart';
import '../../provider/pages/providers_page_modern.dart';
import 'display_settings_page.dart';
import '../../../core/services/chat/chat_service.dart';
import '../../mcp/pages/mcp_page.dart';
import '../../assistant/pages/assistant_settings_page.dart';
import 'about_page.dart';
import 'tts_services_page.dart';
import 'sponsor_page.dart';
import '../../search/pages/search_services_page.dart';
import '../../backup/pages/backup_page.dart';
import '../../quick_phrase/pages/quick_phrases_page.dart';
import '../../instruction_injection/pages/instruction_injection_page.dart';
import 'network_proxy_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/haptics.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    String modeLabel(ThemeMode m) {
      switch (m) {
        case ThemeMode.dark:
          return l10n.settingsPageDarkMode;
        case ThemeMode.light:
          return l10n.settingsPageLightMode;
        case ThemeMode.system:
        default:
          return l10n.settingsPageSystemMode;
      }
    }

    Future<void> pickThemeMode() async {
      final selected = await showModalBottomSheet<ThemeMode>(
        context: context,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetOption(
                    ctx,
                    icon: Lucide.Monitor,
                    label: modeLabel(ThemeMode.system),
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.system),
                  ),
                  _sheetDivider(ctx),
                  _sheetOption(
                    ctx,
                    icon: Lucide.Sun,
                    label: modeLabel(ThemeMode.light),
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.light),
                  ),
                  _sheetDivider(ctx),
                  _sheetOption(
                    ctx,
                    icon: Lucide.Moon,
                    label: modeLabel(ThemeMode.dark),
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (selected != null) {
        await context.read<SettingsProvider>().setThemeMode(selected);
      }
    }

    // 现代风格分组标题
    Widget sectionHeader(String text, {bool first = false}) => Padding(
      padding: EdgeInsets.fromLTRB(16, first ? 8 : 24, 16, 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leading: Tooltip(
          message: l10n.settingsPageBackButton,
          child: _TactileIconButton(
            icon: Lucide.ArrowLeft,
            color: cs.onSurface,
            size: 22,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          l10n.settingsPageTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (!settings.hasAnyActiveModel)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Lucide.MessageCircleWarning, size: 20, color: cs.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.settingsPageWarningMessage,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),

          // 基本设置
          sectionHeader('基本设置', first: true),
          _modernSectionCard(
            context,
            children: [
              _modernSettingItem(
                context,
                icon: Lucide.Palette,
                title: '外观',
                description: '主题、字体大小和语言设置',
                detailText: modeLabel(settings.themeMode),
                onTap: pickThemeMode,
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Settings,
                title: '行为',
                description: '消息发送和通知设置',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DisplaySettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 模型服务
          sectionHeader('模型服务'),
          _modernSectionCard(
            context,
            children: [
              _modernSettingItem(
                context,
                icon: Lucide.Heart,
                title: '配置模型',
                description: '管理AI模型和API密钥',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProvidersPageModern(),
                    ),
                  );
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Wand2,
                title: '智能体提示词集合',
                description: '浏览和使用内置的丰富提示词模板',
                onTap: () {
                  // TODO: 导航到智能体提示词页面
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Globe,
                title: '网络搜索',
                description: '配置网络搜索和相关服务',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchServicesPage(),
                    ),
                  );
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Volume2,
                title: '语音功能',
                description: '语音识别和文本转语音设置',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TtsServicesPage()),
                  );
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Terminal,
                title: 'MCP 服务器',
                description: '高级服务器配置',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const McpPage()));
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.Zap,
                title: '快捷短语',
                description: '创建常用短语模板',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuickPhrasesPage()),
                  );
                },
              ),
            ],
          ),

          // 其他设置
          sectionHeader('其他设置'),
          _modernSectionCard(
            context,
            children: [
              _modernSettingItem(
                context,
                icon: Lucide.Database,
                title: '数据设置',
                description: '管理数据存储和隐私选项',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const BackupPage()));
                },
              ),
              _modernDivider(context),
              _modernSettingItem(
                context,
                icon: Lucide.BadgeInfo,
                title: '关于我们',
                description: '应用信息和技术支持',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- 现代风格设置页面组件 ---

// 现代风格分组卡片
Widget _modernSectionCard(
  BuildContext context, {
  required List<Widget> children,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

// 现代风格分割线
Widget _modernDivider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    thickness: 1,
    indent: 68,
    endIndent: 16,
    color: cs.outlineVariant.withOpacity(0.2),
  );
}

// 现代风格设置项
Widget _modernSettingItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? description,
  VoidCallback? onTap,
  String? detailText,
  Widget Function(BuildContext ctx)? detailBuilder,
}) {
  final cs = Theme.of(context).colorScheme;
  final interactive = onTap != null;

  return _TactileRow(
    onTap: onTap,
    pressedScale: 1.00,
    haptics: true,
    builder: (pressed) {
      return Container(
        color: pressed ? cs.onSurface.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: cs.primary),
            ),
            const SizedBox(width: 16),
            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Detail & Arrow
            if (detailBuilder != null) detailBuilder(context),
            if (detailText != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            if (interactive)
              Icon(
                Lucide.ChevronRight,
                size: 20,
                color: cs.onSurface.withOpacity(0.4),
              ),
          ],
        ),
      );
    },
  );
}

// Tactile Row Widget
class _TactileRow extends StatefulWidget {
  const _TactileRow({
    required this.builder,
    this.onTap,
    this.pressedScale = 1.00,
    this.haptics = true,
  });
  final Widget Function(bool pressed) builder;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptics;
  @override
  State<_TactileRow> createState() => _TactileRowState();
}

class _TactileRowState extends State<_TactileRow> {
  bool _pressed = false;
  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptics &&
                  context.read<SettingsProvider>().hapticsOnListItemTap) {
                Haptics.soft();
              }
              widget.onTap!.call();
            },
      child: widget.builder(_pressed),
    );
  }
}

// Icon-only tactile button for AppBar
class _TactileIconButton extends StatefulWidget {
  const _TactileIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.size = 22,
    this.haptics = true,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final double size;
  final bool haptics;

  @override
  State<_TactileIconButton> createState() => _TactileIconButtonState();
}

class _TactileIconButtonState extends State<_TactileIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color;
    final pressColor = base.withOpacity(0.7);
    final icon = Icon(
      widget.icon,
      size: widget.size,
      color: _pressed ? pressColor : base,
      semanticLabel: widget.semanticLabel,
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          if (widget.haptics) Haptics.light();
          widget.onTap();
        },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                if (widget.haptics) Haptics.light();
                widget.onLongPress!.call();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: icon,
        ),
      ),
    );
  }
}

// Bottom sheet iOS-style option
Widget _sheetOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return _TactileRow(
    pressedScale: 1.00,
    haptics: true,
    onTap: onTap,
    builder: (pressed) {
      final base = cs.onSurface;
      final bgTarget = pressed
          ? (isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05))
          : Colors.transparent;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        color: bgTarget,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 24, child: Icon(icon, size: 20, color: base)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, color: base)),
            ),
          ],
        ),
      );
    },
  );
}

Widget _sheetDivider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    thickness: 0.6,
    indent: 52,
    endIndent: 16,
    color: cs.outlineVariant.withOpacity(0.18),
  );
}
