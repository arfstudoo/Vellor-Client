import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/core_manager.dart';
import '../../core/storage.dart';
import '../../core/system_proxy_manager.dart';
import '../../core/tray_service.dart';
import '../../core/vless_parser.dart';
import '../../models/profile.dart';
import '../../models/subscription.dart';
import '../../theme/vellor_theme.dart';
import 'widgets/connect_button.dart';
import 'widgets/import_dialog.dart';
import 'widgets/mode_selector.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/smooth_scroll_wrapper.dart';
import 'widgets/subscription_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _core = CoreManager.instance;

  List<Subscription> _subscriptions = [];
  String? _selectedProfileId;
  bool _bypassRu = false;
  String _mode = 'tun';
  bool _autoConnect = false;
  bool _autoStart = false;
  List<String> _splitApps = [];

  bool _isLoading = true;
  bool _sortByPing = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _serverListScrollController = ScrollController();

  final Set<String> _pingingSubIds = {};
  CoreState _coreState = CoreState.disconnected;

  late StreamSubscription<CoreState> _stateSub;
  Timer? _autoUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialState();

    _stateSub = _core.stateStream.listen((state) {
      if (mounted) {
        setState(() => _coreState = state);
        TrayService.updateStatus(
          connected: state == CoreState.connected,
          text: state == CoreState.connected
              ? 'Vellor Client - Подключено (${_activeProfile?.name ?? ""})'
              : 'Vellor Client - Отключено',
        );
        if (state == CoreState.error && _core.lastError.isNotEmpty) {
          _showErrorSnackBar(_core.lastError);
        }
      }
    });

    TrayService.init(
      onToggleConnect: _toggleConnect,
      onExit: () async {
        await _core.stop();
        await SystemProxyManager.disableProxy();
      },
    );
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    _searchController.dispose();
    _serverListScrollController.dispose();
    _stateSub.cancel();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final state = await AppStorage.loadState();
    _subscriptions = (state['subscriptions'] as List<Subscription>?) ?? [];
    _selectedProfileId = state['selectedProfileId'] as String?;
    _bypassRu = state['bypassRu'] as bool? ?? false;
    _mode = state['mode'] as String? ?? 'tun';
    _autoConnect = state['autoConnect'] as bool? ?? false;
    _autoStart = state['autoStart'] as bool? ?? false;
    _splitApps = (state['splitApps'] as List<String>?) ?? [];

    if (_selectedProfileId == null && _subscriptions.isNotEmpty) {
      final firstWithProfiles = _subscriptions.firstWhere(
        (s) => s.profiles.isNotEmpty,
        orElse: () => _subscriptions.first,
      );
      if (firstWithProfiles.profiles.isNotEmpty) {
        _selectedProfileId = firstWithProfiles.profiles.first.id;
      }
    }

    setState(() => _isLoading = false);

    _startAutoUpdateTimer();

    if (_autoConnect && _activeProfile != null && _coreState == CoreState.disconnected) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _coreState == CoreState.disconnected) {
          _toggleConnect();
        }
      });
    }
  }

  void _startAutoUpdateTimer() {
    _autoUpdateTimer?.cancel();
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      final now = DateTime.now();
      for (final sub in _subscriptions) {
        if (sub.url.isNotEmpty &&
            now.difference(sub.lastUpdated).inHours >= sub.autoUpdateIntervalHours) {
          _refreshSubscription(sub);
        }
      }
    });
  }

  Future<void> _saveState() async {
    await AppStorage.saveState(
      subscriptions: _subscriptions,
      selectedProfileId: _selectedProfileId,
      bypassRu: _bypassRu,
      mode: _mode,
      autoConnect: _autoConnect,
      autoStart: _autoStart,
      splitApps: _splitApps,
    );
  }

  void _handleModeChange(String newMode) {
    if (_mode == newMode) return;
    setState(() => _mode = newMode);
    _saveState();
    if (_coreState == CoreState.connected && _activeProfile != null) {
      _core.start(
        profile: _activeProfile!,
        bypassRu: _bypassRu,
        mode: _mode,
        splitTunnelingApps: _splitApps,
      );
    }
  }

  Profile? get _activeProfile {
    if (_selectedProfileId == null) return null;
    for (final sub in _subscriptions) {
      for (final p in sub.profiles) {
        if (p.id == _selectedProfileId) return p;
      }
    }
    for (final sub in _subscriptions) {
      if (sub.profiles.isNotEmpty) return sub.profiles.first;
    }
    return null;
  }

  Future<void> _toggleConnect() async {
    if (_coreState == CoreState.connected ||
        _coreState == CoreState.connecting) {
      await _core.stop();
      return;
    }

    final profile = _activeProfile;
    if (profile == null) {
      _showImportDialog();
      return;
    }

    final success = await _core.start(
      profile: profile,
      bypassRu: _bypassRu,
      mode: _mode,
      splitTunnelingApps: _splitApps,
    );

    if (!success && mounted) {
      _showErrorSnackBar(_core.lastError.isNotEmpty
          ? _core.lastError
          : 'Не удалось запустить сетевое подключение');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TunyxColors.surfaceElevated,
        content: Text(
          message,
          style: const TextStyle(
            color: TunyxColors.redPing,
            fontSize: 12,
            fontFamily: 'Segoe UI',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: TunyxColors.redPing, width: 0.8),
        ),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportDialog(
        onImport: (newSub) {
          setState(() {
            _subscriptions.add(newSub);
            if (_selectedProfileId == null && newSub.profiles.isNotEmpty) {
              _selectedProfileId = newSub.profiles.first.id;
            }
          });
          _saveState();
          _pingSubscription(newSub);
        },
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        autoConnect: _autoConnect,
        autoStart: _autoStart,
        bypassRu: _bypassRu,
        splitApps: _splitApps,
        onSave: ({
          required bool autoConnect,
          required bool autoStart,
          required bool bypassRu,
          required List<String> splitApps,
        }) {
          setState(() {
            _autoConnect = autoConnect;
            _autoStart = autoStart;
            _bypassRu = bypassRu;
            _splitApps = splitApps;
          });
          _saveState();
          if (_coreState == CoreState.connected && _activeProfile != null) {
            _core.start(
              profile: _activeProfile!,
              bypassRu: _bypassRu,
              mode: _mode,
              splitTunnelingApps: _splitApps,
            );
          }
        },
      ),
    );
  }

  Future<void> _refreshSubscription(Subscription sub) async {
    if (sub.url.isEmpty) return;

    final updated = await VlessParser.fetchSubscription(sub.url);
    if (updated != null && mounted) {
      setState(() {
        final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
        if (idx != -1) {
          _subscriptions[idx] = updated.copyWith(
            id: sub.id,
            name: sub.name,
            isExpanded: sub.isExpanded,
          );
        }
      });
      _saveState();
      _pingSubscription(_subscriptions.firstWhere((s) => s.id == sub.id));
    }
  }

  Future<void> _pingSubscription(Subscription sub) async {
    if (_pingingSubIds.contains(sub.id) || sub.profiles.isEmpty) return;

    setState(() => _pingingSubIds.add(sub.id));

    final updatedProfiles = List<Profile>.from(sub.profiles);
    for (int i = 0; i < updatedProfiles.length; i++) {
      final p = updatedProfiles[i];
      final latency = await CoreManager.testLatency(p);
      if (mounted) {
        setState(() {
          updatedProfiles[i] = p.copyWith(latencyMs: latency);
          final subIdx = _subscriptions.indexWhere((s) => s.id == sub.id);
          if (subIdx != -1) {
            _subscriptions[subIdx] = _subscriptions[subIdx].copyWith(profiles: updatedProfiles);
          }
        });
      }
    }

    if (mounted) {
      setState(() => _pingingSubIds.remove(sub.id));
    }
    _saveState();
  }

  void _toggleExpand(Subscription sub) {
    setState(() {
      final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
      if (idx != -1) {
        _subscriptions[idx] = sub.copyWith(isExpanded: !sub.isExpanded);
      }
    });
    _saveState();
  }

  void _selectProfile(Profile p) {
    if (_selectedProfileId == p.id) return;
    setState(() => _selectedProfileId = p.id);
    _saveState();

    if (_coreState == CoreState.connected) {
      _core.start(
        profile: p,
        bypassRu: _bypassRu,
        mode: _mode,
        splitTunnelingApps: _splitApps,
      );
    }
  }

  void _deleteSubscription(Subscription sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TunyxColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Удалить подписку', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Text('Удалить "${sub.name}" и все её серверы?', style: const TextStyle(fontSize: 12, color: TunyxColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: TunyxColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _subscriptions.removeWhere((s) => s.id == sub.id);
                if (_activeProfile == null && _subscriptions.isNotEmpty) {
                  final firstWithProfiles = _subscriptions.firstWhere(
                    (s) => s.profiles.isNotEmpty,
                    orElse: () => _subscriptions.first,
                  );
                  if (firstWithProfiles.profiles.isNotEmpty) {
                    _selectedProfileId = firstWithProfiles.profiles.first.id;
                  }
                }
              });
              _saveState();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TunyxColors.redPrimary),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _renameSubscription(Subscription sub, String newName) {
    setState(() {
      final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
      if (idx != -1) {
        _subscriptions[idx] = sub.copyWith(name: newName);
      }
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: TunyxColors.redPrimary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    int totalServersCount = 0;
    for (final s in _subscriptions) {
      totalServersCount += s.profiles.length;
    }

    return Scaffold(
      backgroundColor: TunyxColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  ModeSelector(
                    selectedMode: _mode,
                    onModeChanged: _handleModeChange,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showSettingsDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101016),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E1E28),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Color(0xFF8E8E9E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showImportDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 32,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width >= 400 ? 10 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101016),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E1E28),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xFFE2E2EA),
                          ),
                          if (MediaQuery.of(context).size.width >= 400) ...[
                            const SizedBox(width: 4),
                            const Text(
                              'Добавить',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE2E2EA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            ConnectButton(
              state: _coreState,
              onTap: _toggleConnect,
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Подписки (${_subscriptions.length}) • $totalServersCount серверов',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7E7E90),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                        if (!_isSearchVisible) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                    icon: Icon(
                      _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                      size: 16,
                      color: _isSearchVisible ? const Color(0xFF38BDF8) : const Color(0xFF8E8E9E),
                    ),
                    splashRadius: 14,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Поиск серверов',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      setState(() => _sortByPing = !_sortByPing);
                    },
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      size: 17,
                      color: _sortByPing ? const Color(0xFF10B981) : const Color(0xFF8E8E9E),
                    ),
                    splashRadius: 14,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: _sortByPing ? 'Сортировка по пингу включена' : 'Сортировать по пингу',
                  ),
                ],
              ),
            ),

            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
                child: SizedBox(
                  height: 30,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFEDEDF2)),
                    decoration: InputDecoration(
                      hintText: 'Поиск по стране или названию сервера...',
                      hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF6B6B7C)),
                      prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF6B6B7C)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF101016),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF1E1E28)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF1E1E28)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),
            const SizedBox(height: 2),

            Expanded(
              child: _subscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public_off_rounded,
                            size: 28,
                            color: TunyxColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Список подписок пуст',
                            style: TextStyle(
                              fontSize: 12,
                              color: TunyxColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _showImportDialog,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Добавить подписку'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TunyxColors.textPrimary,
                              side: const BorderSide(color: TunyxColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SmoothScrollWrapper(
                      controller: _serverListScrollController,
                      child: ListView.builder(
                        controller: _serverListScrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = _subscriptions[index];
                          return SubscriptionCard(
                            subscription: sub,
                            selectedProfileId: _selectedProfileId,
                            searchQuery: _searchQuery,
                            sortByPing: _sortByPing,
                            isPinging: _pingingSubIds.contains(sub.id),
                            onSelectProfile: _selectProfile,
                            onToggleExpand: () => _toggleExpand(sub),
                            onRefresh: () => _refreshSubscription(sub),
                            onPingAll: () => _pingSubscription(sub),
                            onDelete: () => _deleteSubscription(sub),
                            onRename: (newName) => _renameSubscription(sub, newName),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
