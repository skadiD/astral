import 'package:astral/src/rust/api/astral_wfp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  // init
  @override
  void initState() {
    super.initState();
    _initializeWfp();
  }

  Future<void> _initializeWfp() async {
    try {
      final wfpController = await WfpController.newInstance();

      await wfpController.initialize();

      final rules = await FilterRule.newWithParams(
        name: "测试",
        direction: Direction.outbound,
        action: FilterAction.block,
      );

      final result = await wfpController.addFilters(rules: [rules]);
      print('添加过滤器成功，ID: $result');
    } catch (e) {
      // 处理错误
      print('WFP 初始化错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WFP 规则配置')),
      body: Column(children: [
         
        ],
      ),
    );
  }
}
