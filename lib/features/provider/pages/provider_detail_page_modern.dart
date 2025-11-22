import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../icons/lucide_adapter.dart';
import '../widgets/provider_avatar.dart';
import '../../../shared/widgets/snackbar.dart';
import '../../../core/services/haptics.dart';
import 'multi_key_manager_page.dart';

class ProviderDetailPageModern extends StatefulWidget {
  const ProviderDetailPageModern({
    super.key,
    required this.keyName,
    required this.displayName,
  });

  final String keyName;
  final String displayName;

  @override
  State<ProviderDetailPageModern> createState() =>
      _ProviderDetailPageModernState();
}

class _ProviderDetailPageModernState extends State<ProviderDetailPageModern> {
  late ProviderConfig _cfg;
  late ProviderKind _kind;

  final _nameCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();

  bool _enabled = true;
  bool _multiKeyEnabled = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _cfg = settings.getProviderConfig(
      widget.keyName,
      defaultName: widget.displayName,
    );
    _kind = ProviderConfig.classify(
      widget.keyName,
      explicitType: _cfg.providerType,
    );

    _enabled = _cfg.enabled;
    _nameCtrl.text = _cfg.name;
    _keyCtrl.text = _cfg.apiKey;
    _baseCtrl.text = _cfg.baseUrl;
    _multiKeyEnabled = _cfg.multiKeyEnabled ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    _baseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.background : cs.surface.withOpacity(0.95),
      appBar: _buildAppBar(context, cs, l10n),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProviderInfoCard(context, cs, isDark),
          const SizedBox(height: 16),
          _buildModelsCard(context, cs, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: cs.surface,
      leading: IconButton(
        icon: Icon(Lucide.ArrowLeft, color: cs.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _nameCtrl.text.isEmpty ? widget.displayName : _nameCtrl.text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      actions: [
        // 启用/禁用开关
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Text(
                _enabled ? '已启用' : '已禁用',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
        ),
        // 保存按钮
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: _handleSave,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfoCard(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像和名称
          Row(
            children: [
              ProviderAvatar(
                providerKey: widget.keyName,
                displayName: _nameCtrl.text.isEmpty
                    ? widget.displayName
                    : _nameCtrl.text,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text.isEmpty
                          ? widget.displayName
                          : _nameCtrl.text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_cfg.providerType ?? "Custom"} API',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 32, color: cs.outlineVariant.withOpacity(0.3)),

          // API配置标题
          Text(
            'API 配置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // API Key 模式切换
          _buildApiKeyModeSwitch(context, cs),
          const SizedBox(height: 16),

          // API Key 输入或多密钥管理按钮
          if (_multiKeyEnabled)
            _buildMultiKeyManagement(context, cs)
          else
            _buildSingleKeyInput(context, cs),

          const SizedBox(height: 16),

          // Base URL 输入
          _buildBaseUrlInput(context, cs),
        ],
      ),
    );
  }

  Widget _buildApiKeyModeSwitch(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'API Key 模式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _multiKeyEnabled
                  ? '多密钥模式：轮询使用多个API Key'
                  : '单密钥模式：使用单个API Key',
              child: Icon(
                Lucide.BadgeInfo,
                size: 16,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              _multiKeyEnabled ? '多密钥' : '单密钥',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _multiKeyEnabled,
              onChanged: (v) => setState(() => _multiKeyEnabled = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiKeyManagement(BuildContext context, ColorScheme cs) {
    final keyCount = _cfg.apiKeys?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '多密钥管理',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MultiKeyManagerPage(
                  providerKey: widget.keyName,
                  providerDisplayName: _nameCtrl.text.isEmpty
                      ? widget.displayName
                      : _nameCtrl.text,
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('管理多密钥 ($keyCount 个密钥)'),
              const SizedBox(width: 8),
              Icon(Lucide.ChevronRight, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleKeyInput(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Key',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keyCtrl,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            hintText: '请输入 API Key',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(_showApiKey ? Lucide.EyeOff : Lucide.Eye, size: 18),
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBaseUrlInput(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Base URL',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _baseCtrl,
          decoration: InputDecoration(
            hintText: 'https://api.example.com/v1',
            helperText: '留空使用默认地址',
            helperStyle: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildModelsCard(BuildContext context, ColorScheme cs, bool isDark) {
    final modelCount = _cfg.models.length;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '模型列表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: 打开添加模型对话框
                  },
                  icon: Icon(Lucide.Plus, size: 18),
                  label: const Text('添加模型'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    backgroundColor: cs.primary.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
          if (modelCount == 0)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Lucide.Boxes,
                    size: 48,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有模型',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击上方"添加模型"按钮开始',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cfg.models.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                color: cs.outlineVariant.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final modelId = _cfg.models[index];
                return ListTile(
                  leading: Icon(
                    Lucide.MessageSquare,
                    color: cs.primary,
                    size: 20,
                  ),
                  title: Text(
                    modelId,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Model ID: $modelId',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: Icon(
                    Lucide.ChevronRight,
                    size: 18,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  onTap: () {
                    // TODO: 打开模型详情
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    try {
      Haptics.light();

      final settings = context.read<SettingsProvider>();
      final updated = _cfg.copyWith(
        name: _nameCtrl.text,
        apiKey: _keyCtrl.text,
        baseUrl: _baseCtrl.text,
        enabled: _enabled,
        multiKeyEnabled: _multiKeyEnabled,
      );

      await settings.setProviderConfig(widget.keyName, updated);

      if (!mounted) return;
      showAppSnackBar(context, message: '保存成功', type: NotificationType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: '保存失败: $e',
        type: NotificationType.error,
      );
    }
  }
}
