import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// 宣传卡片数据模型
class PromoCard {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? actionUrl;

  const PromoCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.actionUrl,
  });
}

/// 发现页面
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  // 宣传卡片列表
  List<PromoCard> get _promoCards => [
    const PromoCard(
      title: '欢迎使用 Astral',
      subtitle: '高性能的虚拟组网工具，让您的设备轻松互联',
      imageUrl: 'https://youke2.picui.cn/s1/2025/12/22/69494ff2dc9b2.png',
    ),
    const PromoCard(
      title: '快速部署',
      subtitle: '支持多平台，一键配置，开箱即用',
      imageUrl: 'https://youke2.picui.cn/s1/2025/12/22/69494ff2dc9b2.png',
    ),
    const PromoCard(
      title: '安全可靠',
      subtitle: '端到端加密，保护您的数据安全',
      imageUrl: 'https://youke2.picui.cn/s1/2025/12/22/69494ff2dc9b2.png',
    ),
    const PromoCard(
      title: '技术支持',
      subtitle: '加入官方QQ群获取帮助和最新资讯',
      imageUrl: 'https://youke2.picui.cn/s1/2025/12/22/69494ff2dc9b2.png',
      actionUrl: 'https://github.com/ldoubil/astral',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 卡片列表
          ..._promoCards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildPromoCard(context, card),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, PromoCard card) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            card.actionUrl != null ? () => _launchUrl(card.actionUrl!) : null,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 背景图片
              Positioned.fill(
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 渐变遮罩 - 更柔和的过渡
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // 发光效果
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // 文字内容
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 箭头图标（如果有链接）- 增强视觉效果
              if (card.actionUrl != null)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
