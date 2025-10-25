import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/k/app_s/aps.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  late TextEditingController _forceRelayNodeController;
  StreamSubscription? _forceRelayNodeSubscription;

  @override
  void initState() {
    super.initState();
    _forceRelayNodeController = TextEditingController(
      text: Aps().forceRelayNodeIp.value,
    );
    
    // 监听forceRelayNodeIp的变化，同步到controller
    _forceRelayNodeSubscription = Aps().forceRelayNodeIp.listen((value) {
      if (_forceRelayNodeController.text != value) {
        _forceRelayNodeController.text = value;
      }
    });
  }

  @override
  void dispose() {
    _forceRelayNodeController.dispose();
    _forceRelayNodeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.network_settings.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              children: [
                // 协议选择
                ListTile(
                  title: Text(LocaleKeys.p2p_hole_punching.tr()),
                  subtitle: Text(LocaleKeys.preferred_protocol.tr()),
                  trailing: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<String>(
                        value:
                            Aps().defaultProtocol.watch(context).isEmpty
                                ? 'tcp'
                                : Aps().defaultProtocol.watch(context),
                        items: const [
                          DropdownMenuItem(
                            value: 'tcp',
                            child: Text('TCP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'udp',
                            child: Text('UDP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'ws',
                            child: Text(
                              'WebSocket',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'wss',
                            child: Text('WSS', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'quic',
                            child: Text('QUIC', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDefaultProtocol(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // 基础网络设置
                SwitchListTile(
                  title: Text(LocaleKeys.enable_encryption.tr()),
                  subtitle: Text(LocaleKeys.auto_set_mtu.tr()),
                  value: Aps().enableEncryption.watch(context),
                  onChanged: (value) {
                    Aps().updateEnableEncryption(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.latency_first.tr()),
                  subtitle: Text(LocaleKeys.latency_first_desc.tr()),
                  value: Aps().latencyFirst.watch(context),
                  onChanged: (value) {
                    Aps().updateLatencyFirst(value);
                  },
                ),

                // 强制中转节点IP配置
                ListTile(
                  title: const Text('强制中转节点'),
                  subtitle: const Text('指定成员IP进行全局中转访问'),
                  trailing: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _forceRelayNodeController,
                      decoration: const InputDecoration(
                        hintText: '输入成员IP地址',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (value) {
                        Aps().updateForceRelayNodeIp(value.trim());
                      },
                      onChanged: (value) {
                        // 实时更新状态，但不立即保存到数据库
                        setState(() {});
                      },
                      onEditingComplete: () {
                        // 当用户完成编辑时保存
                        Aps().updateForceRelayNodeIp(_forceRelayNodeController.text.trim());
                      },
                    ),
                  ),
                ),

                const Divider(),

                SwitchListTile(
                  title: Text(LocaleKeys.magic_dns.tr()),
                  subtitle: Text(LocaleKeys.magic_dns_desc.tr()),
                  value: Aps().accept_dns.watch(context),
                  onChanged: (value) {
                    Aps().updateAcceptDns(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.tun_device.tr()),
                  subtitle: Text(LocaleKeys.tun_device_desc.tr()),
                  value: Aps().noTun.watch(context),
                  onChanged: (value) {
                    Aps().updateNoTun(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 高级网络设置
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('高级网络设置'),
                  subtitle: Text('专业用户配置选项'),
                  leading: const Icon(Icons.settings_ethernet),
                ),

                const Divider(),

                SwitchListTile(
                  title: Row(
                    children: [
                      Text(LocaleKeys.smoltcp_stack.tr()),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          LocaleKeys.not_recommended.tr(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(LocaleKeys.smoltcp_stack_desc.tr()),
                  value: Aps().useSmoltcp.watch(context),
                  onChanged: (value) {
                    Aps().updateUseSmoltcp(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.disable_p2p.tr()),
                  subtitle: Text(LocaleKeys.disable_p2p_desc.tr()),
                  value: Aps().disableP2p.watch(context),
                  onChanged: (value) {
                    Aps().updateDisableP2p(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.relay_peer_rpc.tr()),
                  subtitle: Text(LocaleKeys.relay_peer_rpc_desc.tr()),
                  value: Aps().relayAllPeerRpc.watch(context),
                  onChanged: (value) {
                    Aps().updateRelayAllPeerRpc(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.disable_udp_hole_punching.tr()),
                  subtitle: Text(
                    LocaleKeys.disable_udp_hole_punching_desc.tr(),
                  ),
                  value: Aps().disableUdpHolePunching.watch(context),
                  onChanged: (value) {
                    Aps().updateDisableUdpHolePunching(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.enable_multi_thread.tr()),
                  subtitle: Text(LocaleKeys.enable_multi_thread_desc.tr()),
                  value: Aps().multiThread.watch(context),
                  onChanged: (value) {
                    Aps().updateMultiThread(value);
                  },
                ),

                // 压缩算法选择
                ListTile(
                  title: Text(LocaleKeys.compression_algorithm.tr()),
                  subtitle: Text(LocaleKeys.compression_algorithm_desc.tr()),
                  trailing: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<int>(
                        value: Aps().dataCompressAlgo.watch(context),
                        items: [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              LocaleKeys.no_compression.tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              LocaleKeys.high_performance_compression.tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDataCompressAlgo(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.bind_device.tr()),
                  subtitle: Text(LocaleKeys.bind_device_desc.tr()),
                  value: Aps().bindDevice.watch(context),
                  onChanged: (value) {
                    Aps().updateBindDevice(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.enable_kcp_proxy.tr()),
                  subtitle: Text(LocaleKeys.enable_kcp_proxy_desc.tr()),
                  value: Aps().enableKcpProxy.watch(context),
                  onChanged: (value) {
                    Aps().updateEnableKcpProxy(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.kcp_input.tr()),
                  subtitle: Text(LocaleKeys.kcp_input_desc.tr()),
                  value: Aps().disableKcpInput.watch(context),
                  onChanged: (value) {
                    Aps().updateDisableKcpInput(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.disable_relay_kcp.tr()),
                  subtitle: Text(LocaleKeys.disable_relay_kcp_desc.tr()),
                  value: Aps().disableRelayKcp.watch(context),
                  onChanged: (value) {
                    Aps().updateDisableRelayKcp(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.private_mode.tr()),
                  subtitle: Text(LocaleKeys.private_mode_desc.tr()),
                  value: Aps().privateMode.watch(context),
                  onChanged: (value) {
                    Aps().updatePrivateMode(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.enable_quic_proxy.tr()),
                  subtitle: Text(LocaleKeys.enable_quic_proxy_desc.tr()),
                  value: Aps().enableQuicProxy.watch(context),
                  onChanged: (value) {
                    Aps().updateEnableQuicProxy(value);
                  },
                ),

                SwitchListTile(
                  title: Text(LocaleKeys.disable_quic_input.tr()),
                  subtitle: Text(LocaleKeys.disable_quic_input_desc.tr()),
                  value: Aps().disableQuicInput.watch(context),
                  onChanged: (value) {
                    Aps().updateDisableQuicInput(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
