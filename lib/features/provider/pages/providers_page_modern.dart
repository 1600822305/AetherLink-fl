import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../icons/lucide_adapter.dart';
import '../widgets/provider_avatar.dart';
import 'provider_detail_page_modern.dart';
import '../widgets/add_provider_sheet.dart';
import '../../../core/services/haptics.dart';
import '../../../shared/widgets/snackbar.dart';
import '../../../core/providers/assistant_provider.dart';

class ProvidersPageModern extends StatefulWidget {
  const ProvidersPageModern({super.key});

  @override
  State<ProvidersPageModern> createState() => _ProvidersPageModernState();
}

class _ProvidersPageModernState extends State<ProvidersPageModern> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedProviders = {};
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    // 构建供应商列表
    final baseProviders = _getBaseProviders(l10n);
    final cfgs = settings.providerConfigs;
    final baseKeys = {for (final p in baseProviders) p.keyName};

    // 动态供应商
    final dynamicProviders = <ProviderItem>[];
    cfgs.forEach((key, cfg) {
      if (!baseKeys.contains(key)) {
        dynamicProviders.add(
          ProviderItem(
            name: cfg.name.isNotEmpty ? cfg.name : key,
            keyName: key,
            enabled: cfg.enabled,
            modelCount: cfg.models.length,
          ),
        );
      }
    });

    // 合并并排序
    final merged = [...baseProviders, ...dynamicProviders];
    final order = settings.providersOrder;
    final map = {for (final p in merged) p.keyName: p};
    final providers = <ProviderItem>[];
    for (final k in order) {
      final p = map.remove(k);
      if (p != null) providers.add(p);
    }
    providers.addAll(map.values);

    return Scaffold(
      backgroundColor: isDark ? cs.background : cs.surface.withOpacity(0.95),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: Icon(Lucide.ArrowLeft, color: cs.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '配置模型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          if (_isMultiSelectMode) ...[
            // 取消按钮
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: Icon(Lucide.X, size: 18),
                label: const Text('取消'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withOpacity(0.7),
                  backgroundColor: cs.onSurface.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleToggleMultiSelect,
              ),
            ),
            // 删除按钮
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                icon: Icon(Lucide.Trash2, size: 18),
                label: Text('删除 (${_selectedProviders.length})'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  backgroundColor: cs.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectedProviders.isEmpty
                    ? null
                    : _handleDeleteSelected,
              ),
            ),
          ] else ...[
            // 批量删除按钮
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: Icon(Lucide.Trash2, size: 18),
                label: const Text('批量删除'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  backgroundColor: cs.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleToggleMultiSelect,
              ),
            ),
            // 添加按钮
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                icon: Icon(Lucide.Plus, size: 18),
                label: const Text('添加'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleAddProvider,
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 供应商列表卡片
          _buildProvidersCard(context, providers, isDark),
          const SizedBox(height: 16),
          // 推荐操作卡片
          _buildRecommendedActionsCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildProvidersCard(
    BuildContext context,
    List<ProviderItem> providers,
    bool isDark,
  ) {
    final cs = Theme.of(context).colorScheme;

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
          // 标题区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.01),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '模型供应商',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isMultiSelectMode ? '选择要删除的供应商' : '管理您的AI模型供应商',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isMultiSelectMode)
                  TextButton(
                    onPressed: _handleSelectAll,
                    child: Text(
                      _selectedProviders.length == providers.length
                          ? '取消全选'
                          : '全选',
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
          // 供应商列表
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: providers.length,
            buildDefaultDragHandles: !_isMultiSelectMode,
            onReorder: (oldIndex, newIndex) =>
                _handleReorder(oldIndex, newIndex, providers),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return _buildProviderItem(context, provider, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderItem(
    BuildContext context,
    ProviderItem provider,
    bool isDark,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedProviders.contains(provider.keyName);

    return Material(
      key: ValueKey(provider.keyName),
      color: isSelected ? cs.primary.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () => _isMultiSelectMode
            ? _handleToggleProvider(provider.keyName)
            : _handleProviderClick(provider.keyName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // 拖动手柄或复选框
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _handleToggleProvider(provider.keyName),
                )
              else
                Icon(
                  Lucide.GripVertical,
                  size: 20,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              const SizedBox(width: 12),
              // 供应商图标
              ProviderAvatar(
                providerKey: provider.keyName,
                displayName: provider.name,
                size: 40,
              ),
              const SizedBox(width: 16),
              // 名称和状态
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          provider.enabled ? '已启用' : '已禁用',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: provider.enabled
                                ? Colors.green
                                : cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (provider.modelCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${provider.modelCount} 个模型',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 右侧操作按钮
              if (!_isMultiSelectMode) ...[
                IconButton(
                  icon: Icon(Lucide.Settings, size: 18),
                  color: cs.onSurface.withOpacity(0.6),
                  onPressed: () => _handleProviderClick(provider.keyName),
                ),
                Icon(
                  Lucide.ChevronRight,
                  size: 20,
                  color: cs.primary.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedActionsCard(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '推荐操作',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Lucide.Bot, color: cs.primary, size: 20),
            ),
            title: const Text('智能体提示词'),
            subtitle: const Text('浏览内置提示词模板'),
            trailing: Icon(
              Lucide.ChevronRight,
              color: cs.primary.withOpacity(0.5),
            ),
            onTap: () {
              // 导航到智能体提示词页面
            },
          ),
          Divider(
            height: 1,
            indent: 72,
            color: cs.outlineVariant.withOpacity(0.3),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Lucide.MessageSquare, color: cs.primary, size: 20),
            ),
            title: const Text('模型选择器样式'),
            subtitle: const Text('切换对话框或下拉菜单'),
            trailing: Icon(
              Lucide.ChevronRight,
              color: cs.primary.withOpacity(0.5),
            ),
            onTap: () {
              // 切换模型选择器样式
            },
          ),
        ],
      ),
    );
  }

  // 事件处理函数
  void _handleToggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedProviders.clear();
      }
    });
  }

  void _handleToggleProvider(String keyName) {
    setState(() {
      if (_selectedProviders.contains(keyName)) {
        _selectedProviders.remove(keyName);
      } else {
        _selectedProviders.add(keyName);
      }
    });
  }

  void _handleSelectAll() {
    final settings = context.read<SettingsProvider>();
    final allKeys = settings.providerConfigs.keys.toSet();

    setState(() {
      if (_selectedProviders.length == allKeys.length) {
        _selectedProviders.clear();
      } else {
        _selectedProviders.addAll(allKeys);
      }
    });
  }

  Future<void> _handleAddProvider() async {
    final createdKey = await showAddProviderSheet(context);
    if (!mounted) return;
    if (createdKey != null && createdKey.isNotEmpty) {
      setState(() {});
      showAppSnackBar(
        context,
        message: '供应商已添加',
        type: NotificationType.success,
      );
    }
  }

  void _handleProviderClick(String keyName) {
    if (_isDragging) return;
    final provider = context.read<SettingsProvider>().providerConfigs[keyName];
    final displayName = provider?.name ?? keyName;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProviderDetailPageModern(
              keyName: keyName,
              displayName: displayName,
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    List<ProviderItem> providers,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final mut = List<ProviderItem>.of(providers);
    final item = mut.removeAt(oldIndex);
    mut.insert(newIndex, item);

    await context.read<SettingsProvider>().setProvidersOrder([
      for (final p in mut) p.keyName,
    ]);

    setState(() {});
  }

  Future<void> _handleDeleteSelected() async {
    if (_selectedProviders.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除供应商 (${_selectedProviders.length})'),
        content: const Text('确定要删除选中的供应商吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 清理助手引用
      try {
        final ap = context.read<AssistantProvider>();
        for (final a in ap.assistants) {
          if (_selectedProviders.contains(a.chatModelProvider)) {
            await ap.updateAssistant(a.copyWith(clearChatModel: true));
          }
        }
      } catch (_) {}

      // 删除供应商
      final sp = context.read<SettingsProvider>();
      for (final k in _selectedProviders) {
        await sp.removeProviderConfig(k);
      }

      if (!mounted) return;
      setState(() {
        _selectedProviders.clear();
        _isMultiSelectMode = false;
      });

      showAppSnackBar(
        context,
        message: '已删除选中的供应商',
        type: NotificationType.success,
      );
    } catch (_) {}
  }

  List<ProviderItem> _getBaseProviders(AppLocalizations l10n) => [
    ProviderItem(
      name: 'OpenAI',
      keyName: 'OpenAI',
      enabled: true,
      modelCount: 0,
    ),
    ProviderItem(
      name: l10n.providersPageSiliconFlowName,
      keyName: 'SiliconFlow',
      enabled: true,
      modelCount: 0,
    ),
    ProviderItem(
      name: 'Gemini',
      keyName: 'Gemini',
      enabled: true,
      modelCount: 0,
    ),
    ProviderItem(
      name: 'OpenRouter',
      keyName: 'OpenRouter',
      enabled: true,
      modelCount: 0,
    ),
    ProviderItem(
      name: 'AetherLinkIN',
      keyName: 'AetherLinkIN',
      enabled: true,
      modelCount: 0,
    ),
    ProviderItem(
      name: 'DeepSeek',
      keyName: 'DeepSeek',
      enabled: false,
      modelCount: 0,
    ),
    ProviderItem(
      name: l10n.providersPageAliyunName,
      keyName: 'Aliyun',
      enabled: false,
      modelCount: 0,
    ),
    ProviderItem(
      name: l10n.providersPageZhipuName,
      keyName: 'Zhipu AI',
      enabled: false,
      modelCount: 0,
    ),
    ProviderItem(
      name: 'Claude',
      keyName: 'Claude',
      enabled: false,
      modelCount: 0,
    ),
    ProviderItem(name: 'Grok', keyName: 'Grok', enabled: false, modelCount: 0),
    ProviderItem(
      name: l10n.providersPageByteDanceName,
      keyName: 'ByteDance',
      enabled: false,
      modelCount: 0,
    ),
  ];
}

class ProviderItem {
  final String name;
  final String keyName;
  final bool enabled;
  final int modelCount;

  ProviderItem({
    required this.name,
    required this.keyName,
    required this.enabled,
    required this.modelCount,
  });
}
