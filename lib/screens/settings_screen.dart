import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'version_info_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // 头像部分
          _buildHeader(context),

          const SizedBox(height: 20),

          // 设置列表
          _buildSettingsList(context),

          const SizedBox(height: 20),

          // 分享和评分部分
          _buildShareAndRating(context),

          const SizedBox(height: 20),

          // 应用信息
          _buildAppInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 头像
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 16),

          // 用户名
          Text('时间管理大师', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 8),

          // 用户标语
          Text(
            '珍惜时间，提高效率',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 设置标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '设置',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 深色模式设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('深色模式'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
        ),

        // 振动设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.vibration,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('振动'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: 实现振动开关逻辑
              },
            ),
          ),
        ),

        // 声音设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.volume_up,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('声音'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: 实现声音开关逻辑
              },
            ),
          ),
        ),

        // 通知设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('通知'),
            subtitle: const Text('允许应用发送通知'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: 实现通知开关逻辑
              },
            ),
          ),
        ),

        // 数据备份
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.backup,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('数据备份'),
            subtitle: const Text('备份计时器和闹钟数据'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据备份功能即将上线')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShareAndRating(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '分享与评分',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 分享应用
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('分享应用'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildShareBottomSheet(context),
              );
            },
          ),
        ),

        // 评分
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.star,
              color: const Color(0xFFFFD700),
            ),
            title: const Text('给我们评分'),
            subtitle: Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('感谢您的${_rating}星评价！'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 关于标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '关于',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 应用版本
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VersionInfoScreen(),
                ),
              );
            },
          ),
        ),

        // 隐私政策
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('隐私政策'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ),

        // 用户协议
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('用户协议'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShareBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '分享到',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareButton(
                context,
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () => _shareToSocial('facebook'),
              ),
              _buildShareButton(
                context,
                icon: Icons.messenger_outline,
                label: 'Line',
                onTap: () => _shareToSocial('line'),
              ),
              _buildShareButton(
                context,
                icon: Icons.more_horiz,
                label: '更多',
                onTap: () => _shareToSocial('more'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _shareToSocial(String platform) {
    final String shareText = '推荐一个超好用的计时器应用！';
    final String shareUrl = 'https://your-app-store-link.com';
    
    switch (platform) {
      case 'facebook':
      case 'line':
      case 'more':
        Share.share('$shareText\n$shareUrl');
        break;
    }
    Navigator.pop(context); // 关闭底部弹窗
  }
} 