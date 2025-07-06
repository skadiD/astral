import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/wfp_model.dart';
import 'package:astral/src/rust/api/nt.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:astral/src/rust/api/astral_wfp.dart';
import 'dart:io';

// 中文选项常量
const Map<String, String> directionOptions = {
  'inbound': '入站',
  'outbound': '出站',
  'both': '双向',
};

const Map<String, String> actionOptions = {'allow': '允许', 'block': '阻止'};

const Map<String, String> protocolOptions = {'tcp': 'TCP', 'udp': 'UDP'};

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  WfpController? _wfpController;
  bool _isWfpRunning = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startWfp() async {
    try {
      print('🚀 开始启动WFP...');
      setState(() {
        _isInitializing = true;
      });

      // 每次启动时初始化新的引擎
      print('📡 正在创建WFP控制器...');
      _wfpController = await WfpController.newInstance();
      print('✅ WFP控制器创建成功');

      print('🔧 正在初始化WFP引擎...');
      await _wfpController!.initialize();
      print('✅ WFP引擎初始化成功');

      // 获取所有规则并转换为FilterRule
      final rules = Aps().wfpModels.value;
      print('📋 获取到 ${rules.length} 条规则');

      final filterRules = <FilterRule>[];

      for (int i = 0; i < rules.length; i++) {
        final rule = rules[i];
        print('🔄 正在处理规则 ${i + 1}/${rules.length}: ${rule.name}');

        // 处理空字符串转换为null
        String? cleanAppPath =
            rule.appPath?.isEmpty == true ? null : rule.appPath;
        String? cleanLocal = rule.local?.isEmpty == true ? null : rule.local;
        String? cleanRemote = rule.remote?.isEmpty == true ? null : rule.remote;
        String? cleanProtocol =
            rule.protocol?.isEmpty == true ? null : rule.protocol;
        String? cleanDescription =
            rule.description?.isEmpty == true ? null : rule.description;

        // 处理应用程序路径转换
        String? ntPath;
        if (cleanAppPath != null) {
          print('  📁 转换应用程序路径: $cleanAppPath');
          try {
            ntPath = await getNtPath(dosPath: cleanAppPath);
            print('  ✅ 路径转换成功: $ntPath');
          } catch (e) {
            print('  ⚠️ 路径转换失败: $e');
            ntPath = cleanAppPath; // 使用原始路径作为备选
          }
        } else {
          print('  📁 应用程序路径为空，跳过转换');
        }

        // 打印所有参数的原始值
        print('  📋 规则参数详情:');
        print('    📝 名称: "${rule.name}"');
        print('    📁 应用程序路径: ${rule.appPath ?? "null"}');
        print('    🏠 本地地址: ${rule.local ?? "null"}');
        print('    🌐 远程地址: ${rule.remote ?? "null"}');
        print('    🔌 本地端口: ${rule.localPort ?? "null"}');
        print('    🔌 远程端口: ${rule.remotePort ?? "null"}');
        print('    📊 本地端口范围: ${rule.localPortRange ?? "null"}');
        print('    📊 远程端口范围: ${rule.remotePortRange ?? "null"}');
        print('    📡 协议: ${rule.protocol ?? "null"}');
        print('    ➡️ 方向: "${rule.direction}"');
        print('    🎯 动作: "${rule.action}"');
        print('    ⚡ 优先级: ${rule.priority ?? "null"}');
        print('    📄 描述: ${rule.description ?? "null"}');

        // 打印空字符串处理结果
        print('  🧹 空字符串处理:');
        print('    📁 应用程序路径: "${rule.appPath}" -> ${cleanAppPath ?? "null"}');
        print('    🏠 本地地址: "${rule.local}" -> ${cleanLocal ?? "null"}');
        print('    🌐 远程地址: "${rule.remote}" -> ${cleanRemote ?? "null"}');
        print('    📡 协议: "${rule.protocol}" -> ${cleanProtocol ?? "null"}');
        print(
          '    📄 描述: "${rule.description}" -> ${cleanDescription ?? "null"}',
        );

        // 打印转换后的NT路径
        print('    🔄 转换后NT路径: ${ntPath ?? "null"}');

        // 处理端口范围转换
        (int, int)? localPortRangeTuple;
        (int, int)? remotePortRangeTuple;

        if (rule.localPortRange != null && rule.localPortRange!.length >= 2) {
          localPortRangeTuple = (
            rule.localPortRange![0],
            rule.localPortRange![1],
          );
          print(
            '    🔌 本地端口范围转换: ${rule.localPortRange} -> $localPortRangeTuple',
          );
        }

        if (rule.remotePortRange != null && rule.remotePortRange!.length >= 2) {
          remotePortRangeTuple = (
            rule.remotePortRange![0],
            rule.remotePortRange![1],
          );
          print(
            '    🔌 远程端口范围转换: ${rule.remotePortRange} -> $remotePortRangeTuple',
          );
        }

        // 打印最终传递给FilterRule的参数
        print('  🎯 最终FilterRule参数:');
        print('    📝 name: "${rule.name}"');
        print('    📁 appPath: ${ntPath ?? "null"}');
        print('    🏠 local: ${cleanLocal ?? "null"}');
        print('    🌐 remote: ${cleanRemote ?? "null"}');
        print('    🔌 localPort: ${rule.localPort ?? "null"}');
        print('    🔌 remotePort: ${rule.remotePort ?? "null"}');
        print('    📊 localPortRange: $localPortRangeTuple');
        print('    📊 remotePortRange: $remotePortRangeTuple');
        print(
          '    📡 protocol: ${cleanProtocol != null ? _parseProtocol(cleanProtocol!) : "null"}',
        );
        print('    ➡️ direction: ${_parseDirection(rule.direction)}');
        print('    🎯 action: ${_parseAction(rule.action)}');
        print('    ⚡ priority: ${rule.priority ?? "null"}');
        print('    📄 description: ${cleanDescription ?? "null"}');

        final filterRule = await FilterRule.newWithParams(
          name: rule.name,
          appPath: ntPath,
          local: cleanLocal,
          remote: cleanRemote,
          localPort: rule.localPort,
          remotePort: rule.remotePort,
          localPortRange: localPortRangeTuple,
          remotePortRange: remotePortRangeTuple,
          protocol:
              cleanProtocol != null ? _parseProtocol(cleanProtocol!) : null,
          direction: _parseDirection(rule.direction),
          action: _parseAction(rule.action),
          priority: rule.priority,
          description: cleanDescription,
        );

        print('  🔍 验证规则...');
        await filterRule.validate();
        print('  ✅ 规则验证通过');

        filterRules.add(filterRule);
        print('  📝 规则已添加到列表');
      }

      print('🎯 正在应用 ${filterRules.length} 条规则到WFP...');
      // 添加所有过滤器
      await _wfpController!.addFilters(rules: filterRules);
      print('✅ 所有规则已成功应用到WFP');

      setState(() {
        _isWfpRunning = true;
        _isInitializing = false;
      });

      print('🎉 WFP启动完成！状态: 运行中');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WFP已启动，规则已应用'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ WFP启动失败: $e');
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动WFP失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopWfp() async {
    if (_wfpController == null) {
      print('⚠️ WFP控制器不存在，无需停止');
      return;
    }

    try {
      print('🛑 开始停止WFP...');
      setState(() {
        _isInitializing = true;
      });

      print('🧹 正在清理WFP过滤器...');
      // 清理所有过滤器
      await _wfpController!.cleanup();
      print('✅ WFP过滤器清理完成');

      // 清理引擎引用
      _wfpController = null;
      print('🗑️ WFP引擎引用已清理');

      setState(() {
        _isWfpRunning = false;
        _isInitializing = false;
      });

      print('🎉 WFP停止完成！状态: 已停止');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WFP已停止'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ WFP停止失败: $e');
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止WFP失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Protocol _parseProtocol(String protocol) {
    final result = switch (protocol.toLowerCase()) {
      'tcp' => Protocol.tcp,
      'udp' => Protocol.udp,
      _ => Protocol.tcp,
    };
    print('  📡 协议解析: $protocol -> $result');
    return result;
  }

  Direction _parseDirection(String direction) {
    final result = switch (direction.toLowerCase()) {
      'inbound' => Direction.inbound,
      'outbound' => Direction.outbound,
      'both' => Direction.both,
      _ => Direction.both,
    };
    print('  ➡️ 方向解析: $direction -> $result');
    return result;
  }

  FilterAction _parseAction(String action) {
    final result = switch (action.toLowerCase()) {
      'allow' => FilterAction.allow,
      'block' => FilterAction.block,
      _ => FilterAction.block,
    };
    print('  🎯 动作解析: $action -> $result');
    return result;
  }

  @override
  void dispose() {
    // 页面销毁时清理WFP引擎
    if (_wfpController != null) {
      print('🔚 页面销毁，正在清理WFP引擎...');
      _wfpController!.cleanup();
      print('✅ WFP引擎清理完成');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('WFP 规则管理')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WFP状态控制区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isWfpRunning
                              ? Icons.security
                              : Icons.security_outlined,
                          color: _isWfpRunning ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WFP 状态',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isInitializing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isWfpRunning ? 'WFP 正在运行，规则已生效' : 'WFP 已停止，规则未生效',
                            style: TextStyle(
                              color: _isWfpRunning ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isInitializing ? null : _startWfp,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('启动'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed:
                              _isInitializing || !_isWfpRunning
                                  ? null
                                  : _stopWfp,
                          icon: const Icon(Icons.stop),
                          label: const Text('停止'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 规则列表区域
            Expanded(
              child: ValueListenableBuilder<List<WfpModel>>(
                valueListenable:
                    Aps().wfpModels as ValueNotifier<List<WfpModel>>,
                builder: (context, rules, _) {
                  return Column(
                    children: [
                      Expanded(
                        child:
                            rules.isEmpty
                                ? const Center(child: Text('暂无规则'))
                                : _WfpRulesTable(
                                  rules: rules,
                                  isWfpRunning: _isWfpRunning,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('添加规则'),
                          onPressed:
                              _isWfpRunning
                                  ? null
                                  : () => _showEditDialog(context, null),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WfpModel? rule) {
    final isEdit = rule != null;
    final _formKey = GlobalKey<FormState>();

    // 基础控制器
    final nameController = TextEditingController(text: rule?.name ?? '');
    final appPathController = TextEditingController(text: rule?.appPath ?? '');
    final localController = TextEditingController(text: rule?.local ?? '');
    final remoteController = TextEditingController(text: rule?.remote ?? '');
    final priorityController = TextEditingController(
      text: rule?.priority?.toString() ?? '',
    );

    // 端口控制器
    final localPortController = TextEditingController(
      text: rule?.localPort?.toString() ?? '',
    );
    final remotePortController = TextEditingController(
      text: rule?.remotePort?.toString() ?? '',
    );

    // 端口范围控制器
    final localPortRangeStartController = TextEditingController();
    final localPortRangeEndController = TextEditingController();
    final remotePortRangeStartController = TextEditingController();
    final remotePortRangeEndController = TextEditingController();

    // 下拉选择器值
    String selectedProtocol = rule?.protocol?.toLowerCase() ?? '';
    String selectedDirection = rule?.direction ?? 'both';
    String selectedAction = rule?.action ?? 'block';

    // 初始化端口数据
    if (rule != null) {
      if (rule.localPort != null) {
        localPortController.text = rule.localPort!.toString();
        localPortRangeStartController.text = rule.localPort!.toString();
        localPortRangeEndController.text = rule.localPort!.toString();
      } else if (rule.localPortRange != null &&
          rule.localPortRange!.isNotEmpty) {
        if (rule.localPortRange!.length == 1) {
          localPortController.text = rule.localPortRange![0].toString();
          localPortRangeStartController.text =
              rule.localPortRange![0].toString();
          localPortRangeEndController.text = rule.localPortRange![0].toString();
        } else if (rule.localPortRange!.length >= 2) {
          localPortRangeStartController.text =
              rule.localPortRange![0].toString();
          localPortRangeEndController.text = rule.localPortRange![1].toString();
        }
      }

      if (rule.remotePort != null) {
        remotePortController.text = rule.remotePort!.toString();
        remotePortRangeStartController.text = rule.remotePort!.toString();
        remotePortRangeEndController.text = rule.remotePort!.toString();
      } else if (rule.remotePortRange != null &&
          rule.remotePortRange!.isNotEmpty) {
        if (rule.remotePortRange!.length == 1) {
          remotePortController.text = rule.remotePortRange![0].toString();
          remotePortRangeStartController.text =
              rule.remotePortRange![0].toString();
          remotePortRangeEndController.text =
              rule.remotePortRange![0].toString();
        } else if (rule.remotePortRange!.length >= 2) {
          remotePortRangeStartController.text =
              rule.remotePortRange![0].toString();
          remotePortRangeEndController.text =
              rule.remotePortRange![1].toString();
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                width: 800, // 增加对话框宽度
                constraints: const BoxConstraints(maxWidth: 900),
                child: AlertDialog(
                  title: Text(isEdit ? '编辑规则' : '添加规则'),
                  content: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 第一行：规则名称和应用程序路径
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: '规则名称',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? '请输入规则名称'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: appPathController,
                                        decoration: const InputDecoration(
                                          labelText: '应用程序路径 (可选)',
                                          hintText: '不选择则应用于所有程序',
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.apps),
                                      onPressed: () async {
                                        final result =
                                            await _showAppSelectorDialog(
                                              context,
                                            );
                                        if (result != null) {
                                          setState(() {
                                            appPathController.text = result;
                                          });
                                        }
                                      },
                                      tooltip: '选择应用程序',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          appPathController.clear();
                                        });
                                      },
                                      tooltip: '清除路径',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 第二行：本地地址和远程地址
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: localController,
                                  decoration: const InputDecoration(
                                    labelText: '本地地址',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: remoteController,
                                  decoration: const InputDecoration(
                                    labelText: '远程地址',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 第三行：本地端口和远程端口
                          Row(
                            children: [
                              Expanded(
                                child: _PortInput(
                                  singlePortController: localPortController,
                                  rangeStartController:
                                      localPortRangeStartController,
                                  rangeEndController:
                                      localPortRangeEndController,
                                  label: '本地端口',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _PortInput(
                                  singlePortController: remotePortController,
                                  rangeStartController:
                                      remotePortRangeStartController,
                                  rangeEndController:
                                      remotePortRangeEndController,
                                  label: '远程端口',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 第四行：协议、方向和动作
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      selectedProtocol.isEmpty
                                          ? null
                                          : selectedProtocol,
                                  decoration: const InputDecoration(
                                    labelText: '协议类型',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('不限制'),
                                    ),
                                    ...protocolOptions.entries.map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedProtocol = value ?? '';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDirection,
                                  decoration: const InputDecoration(
                                    labelText: '方向',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      directionOptions.entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDirection = value!;
                                    });
                                  },
                                  validator:
                                      (value) => value == null ? '请选择方向' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedAction,
                                  decoration: const InputDecoration(
                                    labelText: '动作',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      actionOptions.entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAction = value!;
                                    });
                                  },
                                  validator:
                                      (value) => value == null ? '请选择动作' : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 第五行：优先级
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priorityController,
                                  decoration: const InputDecoration(
                                    labelText: '优先级',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(child: SizedBox()), // 占位
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          // 智能处理端口数据
                          int? localPort;
                          List<int>? localPortRange;

                          if (localPortController.text.isNotEmpty) {
                            localPort = int.tryParse(localPortController.text);
                          } else if (localPortRangeStartController
                              .text
                              .isNotEmpty) {
                            final start = int.tryParse(
                              localPortRangeStartController.text,
                            );
                            final end = int.tryParse(
                              localPortRangeEndController.text,
                            );
                            if (start != null && end != null) {
                              if (start == end) {
                                localPort = start;
                              } else {
                                localPortRange = [start, end];
                              }
                            }
                          }

                          int? remotePort;
                          List<int>? remotePortRange;

                          if (remotePortController.text.isNotEmpty) {
                            remotePort = int.tryParse(
                              remotePortController.text,
                            );
                          } else if (remotePortRangeStartController
                              .text
                              .isNotEmpty) {
                            final start = int.tryParse(
                              remotePortRangeStartController.text,
                            );
                            final end = int.tryParse(
                              remotePortRangeEndController.text,
                            );
                            if (start != null && end != null) {
                              if (start == end) {
                                remotePort = start;
                              } else {
                                remotePortRange = [start, end];
                              }
                            }
                          }

                          final model =
                              WfpModel()
                                ..name = nameController.text
                                ..appPath =
                                    appPathController.text.isEmpty
                                        ? null
                                        : appPathController.text
                                ..local =
                                    localController.text.isEmpty
                                        ? null
                                        : localController.text
                                ..remote =
                                    remoteController.text.isEmpty
                                        ? null
                                        : remoteController.text
                                ..localPort = localPort
                                ..remotePort = remotePort
                                ..localPortRange = localPortRange
                                ..remotePortRange = remotePortRange
                                ..protocol =
                                    selectedProtocol.isEmpty
                                        ? null
                                        : selectedProtocol
                                ..direction = selectedDirection
                                ..action = selectedAction
                                ..priority =
                                    priorityController.text.isEmpty
                                        ? null
                                        : int.tryParse(priorityController.text);

                          if (isEdit) {
                            model.id = rule!.id;
                            await Aps().updateWfpModel(model);
                          } else {
                            await Aps().addWfpModel(model);
                          }

                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 应用程序选择器对话框
  Future<String?> _showAppSelectorDialog(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择应用程序失败: $e')));
    }
    return null;
  }
}

// 统一端口输入控件 - 支持单个端口和端口范围
class _PortInput extends StatefulWidget {
  final TextEditingController singlePortController;
  final TextEditingController rangeStartController;
  final TextEditingController rangeEndController;
  final String label;

  const _PortInput({
    required this.singlePortController,
    required this.rangeStartController,
    required this.rangeEndController,
    required this.label,
  });

  @override
  State<_PortInput> createState() => _PortInputState();
}

class _PortInputState extends State<_PortInput> {
  bool _isRangeMode = false;
  bool _isSingleMode = false;

  @override
  void initState() {
    super.initState();
    widget.singlePortController.addListener(_updateMode);
    widget.rangeStartController.addListener(_updateMode);
    widget.rangeEndController.addListener(_updateMode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMode();
    });
  }

  @override
  void dispose() {
    widget.singlePortController.removeListener(_updateMode);
    widget.rangeStartController.removeListener(_updateMode);
    widget.rangeEndController.removeListener(_updateMode);
    super.dispose();
  }

  void _updateMode() {
    if (!mounted) return;

    final singlePort = widget.singlePortController.text;
    final rangeStart = widget.rangeStartController.text;
    final rangeEnd = widget.rangeEndController.text;

    setState(() {
      _isSingleMode = singlePort.isNotEmpty;
      _isRangeMode = rangeStart.isNotEmpty && rangeEnd.isNotEmpty;
    });
  }

  void _switchToSingleMode() {
    if (!mounted) return;

    if (widget.rangeStartController.text.isNotEmpty) {
      widget.singlePortController.text = widget.rangeStartController.text;
      widget.rangeStartController.clear();
      widget.rangeEndController.clear();
    }
    setState(() {
      _isSingleMode = true;
      _isRangeMode = false;
    });
  }

  void _switchToRangeMode() {
    if (!mounted) return;

    if (widget.singlePortController.text.isNotEmpty) {
      widget.rangeStartController.text = widget.singlePortController.text;
      widget.rangeEndController.text = widget.singlePortController.text;
      widget.singlePortController.clear();
    }
    setState(() {
      _isSingleMode = false;
      _isRangeMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.router, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeButton(
                    label: '单端口',
                    isActive: _isSingleMode,
                    onTap: _switchToSingleMode,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _ModeButton(
                    label: '端口范围',
                    isActive: _isRangeMode,
                    onTap: _switchToRangeMode,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isSingleMode || (!_isSingleMode && !_isRangeMode))
            TextFormField(
              controller: widget.singlePortController,
              decoration: const InputDecoration(
                labelText: '端口号',
                hintText: '80',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return '端口范围: 1-65535';
                  }
                }
                return null;
              },
            ),

          if (_isRangeMode)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.rangeStartController,
                    decoration: const InputDecoration(
                      labelText: '起始端口',
                      hintText: '80',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final port = int.tryParse(value);
                        if (port == null || port < 1 || port > 65535) {
                          return '端口范围: 1-65535';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.rangeEndController,
                    decoration: const InputDecoration(
                      labelText: '结束端口',
                      hintText: '90',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final port = int.tryParse(value);
                        if (port == null || port < 1 || port > 65535) {
                          return '端口范围: 1-65535';
                        }

                        final startPort = int.tryParse(
                          widget.rangeStartController.text,
                        );
                        if (startPort != null && port < startPort) {
                          return '结束端口不能小于起始端口';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),
          if (_isSingleMode && widget.singlePortController.text.isNotEmpty)
            Text(
              '单个端口: ${widget.singlePortController.text}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (_isRangeMode &&
              widget.rangeStartController.text.isNotEmpty &&
              widget.rangeEndController.text.isNotEmpty)
            Text(
              '端口范围: ${widget.rangeStartController.text} - ${widget.rangeEndController.text}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              '请选择输入模式并输入端口',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

// 模式切换按钮
class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isActive
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// 大表格布局组件
class _WfpRulesTable extends StatelessWidget {
  final List<WfpModel> rules;
  final bool isWfpRunning;

  const _WfpRulesTable({required this.rules, required this.isWfpRunning});

  String _getPortDisplay(int? port, List<int>? portRange) {
    if (port != null) {
      return port.toString();
    } else if (portRange != null && portRange.isNotEmpty) {
      if (portRange.length == 1) {
        return portRange[0].toString();
      } else if (portRange.length >= 2) {
        return '${portRange[0]}-${portRange[1]}';
      }
    }
    return '-';
  }

  String _getAppPathDisplay(String? appPath) {
    if (appPath == null || appPath.isEmpty) {
      return '所有程序';
    }
    // 只显示文件名，不显示完整路径
    final fileName = appPath.split(Platform.pathSeparator).last;
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rules.isEmpty) {
      return const Center(child: Text('暂无规则'));
    }
    return ListView.builder(
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // 主体内容
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rule.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // 操作按钮
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color:
                                    isWfpRunning
                                        ? Colors.grey
                                        : colorScheme.primary,
                              ),
                              tooltip: isWfpRunning ? 'WFP运行时无法编辑' : '编辑规则',
                              onPressed:
                                  isWfpRunning
                                      ? null
                                      : () => _showEditDialog(context, rule),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: isWfpRunning ? Colors.grey : Colors.red,
                              ),
                              tooltip: isWfpRunning ? 'WFP运行时无法删除' : '删除规则',
                              onPressed:
                                  isWfpRunning
                                      ? null
                                      : () => _showDeleteConfirmDialog(
                                        context,
                                        rule,
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: '应用程序',
                          value: _getAppPathDisplay(rule.appPath),
                        ),
                        _InfoChip(
                          label: '协议',
                          value:
                              rule.protocol != null && rule.protocol!.isNotEmpty
                                  ? protocolOptions[rule.protocol!
                                          .toLowerCase()] ??
                                      rule.protocol!
                                  : '不限制',
                        ),
                        _InfoChip(
                          label: '方向',
                          value:
                              directionOptions[rule.direction] ??
                              rule.direction,
                        ),
                        _InfoChip(
                          label: '动作',
                          value: actionOptions[rule.action] ?? rule.action,
                          color:
                              rule.action == 'allow'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        _InfoChip(
                          label: '优先级',
                          value: rule.priority?.toString() ?? '-',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FieldRow(
                            label: '本地地址',
                            value: rule.local ?? '-',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FieldRow(
                            label: '远程地址',
                            value: rule.remote ?? '-',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FieldRow(
                            label: '本地端口',
                            value: _getPortDisplay(
                              rule.localPort,
                              rule.localPortRange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FieldRow(
                            label: '远程端口',
                            value: _getPortDisplay(
                              rule.remotePort,
                              rule.remotePortRange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WfpModel rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除规则 \"${rule.name}\" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await Aps().deleteWfpModel(rule.id);
    }
  }

  void _showEditDialog(BuildContext context, WfpModel rule) {
    final _formKey = GlobalKey<FormState>();

    // 基础控制器
    final nameController = TextEditingController(text: rule.name);
    final appPathController = TextEditingController(text: rule.appPath ?? '');
    final localController = TextEditingController(text: rule.local ?? '');
    final remoteController = TextEditingController(text: rule.remote ?? '');
    final priorityController = TextEditingController(
      text: rule.priority?.toString() ?? '',
    );

    // 端口控制器
    final localPortController = TextEditingController(
      text: rule.localPort?.toString() ?? '',
    );
    final remotePortController = TextEditingController(
      text: rule.remotePort?.toString() ?? '',
    );

    // 端口范围控制器
    final localPortRangeStartController = TextEditingController();
    final localPortRangeEndController = TextEditingController();
    final remotePortRangeStartController = TextEditingController();
    final remotePortRangeEndController = TextEditingController();

    // 下拉选择器值
    String selectedProtocol = rule.protocol?.toLowerCase() ?? '';
    String selectedDirection = rule.direction;
    String selectedAction = rule.action;

    // 初始化端口数据
    if (rule.localPort != null) {
      localPortController.text = rule.localPort!.toString();
      localPortRangeStartController.text = rule.localPort!.toString();
      localPortRangeEndController.text = rule.localPort!.toString();
    } else if (rule.localPortRange != null && rule.localPortRange!.isNotEmpty) {
      if (rule.localPortRange!.length == 1) {
        localPortController.text = rule.localPortRange![0].toString();
        localPortRangeStartController.text = rule.localPortRange![0].toString();
        localPortRangeEndController.text = rule.localPortRange![0].toString();
      } else if (rule.localPortRange!.length >= 2) {
        localPortRangeStartController.text = rule.localPortRange![0].toString();
        localPortRangeEndController.text = rule.localPortRange![1].toString();
      }
    }

    if (rule.remotePort != null) {
      remotePortController.text = rule.remotePort!.toString();
      remotePortRangeStartController.text = rule.remotePort!.toString();
      remotePortRangeEndController.text = rule.remotePort!.toString();
    } else if (rule.remotePortRange != null &&
        rule.remotePortRange!.isNotEmpty) {
      if (rule.remotePortRange!.length == 1) {
        remotePortController.text = rule.remotePortRange![0].toString();
        remotePortRangeStartController.text =
            rule.remotePortRange![0].toString();
        remotePortRangeEndController.text = rule.remotePortRange![0].toString();
      } else if (rule.remotePortRange!.length >= 2) {
        remotePortRangeStartController.text =
            rule.remotePortRange![0].toString();
        remotePortRangeEndController.text = rule.remotePortRange![1].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                width: 800, // 增加对话框宽度
                constraints: const BoxConstraints(maxWidth: 900),
                child: AlertDialog(
                  title: const Text('编辑规则'),
                  content: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 第一行：规则名称和应用程序路径
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: '规则名称',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? '请输入规则名称'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: appPathController,
                                        decoration: const InputDecoration(
                                          labelText: '应用程序路径 (可选)',
                                          hintText: '不选择则应用于所有程序',
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.apps),
                                      onPressed: () async {
                                        final result =
                                            await _showAppSelectorDialog(
                                              context,
                                            );
                                        if (result != null) {
                                          setState(() {
                                            appPathController.text = result;
                                          });
                                        }
                                      },
                                      tooltip: '选择应用程序',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          appPathController.clear();
                                        });
                                      },
                                      tooltip: '清除路径',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 第二行：本地地址和远程地址
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: localController,
                                  decoration: const InputDecoration(
                                    labelText: '本地地址',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: remoteController,
                                  decoration: const InputDecoration(
                                    labelText: '远程地址',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 第三行：本地端口和远程端口
                          Row(
                            children: [
                              Expanded(
                                child: _PortInput(
                                  singlePortController: localPortController,
                                  rangeStartController:
                                      localPortRangeStartController,
                                  rangeEndController:
                                      localPortRangeEndController,
                                  label: '本地端口',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _PortInput(
                                  singlePortController: remotePortController,
                                  rangeStartController:
                                      remotePortRangeStartController,
                                  rangeEndController:
                                      remotePortRangeEndController,
                                  label: '远程端口',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 第四行：协议、方向和动作
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value:
                                      selectedProtocol.isEmpty
                                          ? null
                                          : selectedProtocol,
                                  decoration: const InputDecoration(
                                    labelText: '协议类型',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('不限制'),
                                    ),
                                    ...protocolOptions.entries.map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedProtocol = value ?? '';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDirection,
                                  decoration: const InputDecoration(
                                    labelText: '方向',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      directionOptions.entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDirection = value!;
                                    });
                                  },
                                  validator:
                                      (value) => value == null ? '请选择方向' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedAction,
                                  decoration: const InputDecoration(
                                    labelText: '动作',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      actionOptions.entries
                                          .map(
                                            (entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAction = value!;
                                    });
                                  },
                                  validator:
                                      (value) => value == null ? '请选择动作' : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 第五行：优先级
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priorityController,
                                  decoration: const InputDecoration(
                                    labelText: '优先级',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(child: SizedBox()), // 占位
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          // 智能处理端口数据
                          int? localPort;
                          List<int>? localPortRange;

                          if (localPortController.text.isNotEmpty) {
                            localPort = int.tryParse(localPortController.text);
                          } else if (localPortRangeStartController
                              .text
                              .isNotEmpty) {
                            final start = int.tryParse(
                              localPortRangeStartController.text,
                            );
                            final end = int.tryParse(
                              localPortRangeEndController.text,
                            );
                            if (start != null && end != null) {
                              if (start == end) {
                                localPort = start;
                              } else {
                                localPortRange = [start, end];
                              }
                            }
                          }

                          int? remotePort;
                          List<int>? remotePortRange;

                          if (remotePortController.text.isNotEmpty) {
                            remotePort = int.tryParse(
                              remotePortController.text,
                            );
                          } else if (remotePortRangeStartController
                              .text
                              .isNotEmpty) {
                            final start = int.tryParse(
                              remotePortRangeStartController.text,
                            );
                            final end = int.tryParse(
                              remotePortRangeEndController.text,
                            );
                            if (start != null && end != null) {
                              if (start == end) {
                                remotePort = start;
                              } else {
                                remotePortRange = [start, end];
                              }
                            }
                          }

                          final model =
                              WfpModel()
                                ..id = rule.id
                                ..name = nameController.text
                                ..appPath =
                                    appPathController.text.isEmpty
                                        ? null
                                        : appPathController.text
                                ..local =
                                    localController.text.isEmpty
                                        ? null
                                        : localController.text
                                ..remote =
                                    remoteController.text.isEmpty
                                        ? null
                                        : remoteController.text
                                ..localPort = localPort
                                ..remotePort = remotePort
                                ..localPortRange = localPortRange
                                ..remotePortRange = remotePortRange
                                ..protocol =
                                    selectedProtocol.isEmpty
                                        ? null
                                        : selectedProtocol
                                ..direction = selectedDirection
                                ..action = selectedAction
                                ..priority =
                                    priorityController.text.isEmpty
                                        ? null
                                        : int.tryParse(priorityController.text);

                          await Aps().updateWfpModel(model);
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 应用程序选择器对话框
  Future<String?> _showAppSelectorDialog(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择应用程序失败: $e')));
    }
    return null;
  }
}

// 卡片内字段展示
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _InfoChip({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value', style: TextStyle(color: color)),
      backgroundColor: color?.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
