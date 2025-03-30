import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: '协议接受',
            content: '欢迎使用我们的应用。通过访问或使用本应用，您同意受本用户协议的约束。如果您不同意这些条款，请不要使用本应用。',
          ),
          _buildSection(
            context,
            title: '服务说明',
            content: '''本应用提供以下服务：

• 时间管理功能
• 计时器功能
• 数据存储和同步
• 个性化设置
• 其他相关功能和服务''',
          ),
          _buildSection(
            context,
            title: '用户责任',
            content: '''作为用户，您同意：

• 提供准确的信息（如适用）
• 保护您的账户安全
• 遵守所有适用的法律和法规
• 不从事任何可能损害应用运行的行为
• 不侵犯他人的知识产权''',
          ),
          _buildSection(
            context,
            title: '知识产权',
            content: '本应用及其原创内容、功能和设计受著作权、商标和其他知识产权法律保护。未经明确许可，用户不得复制、修改、传播或使用任何受保护内容。',
          ),
          _buildSection(
            context,
            title: '免责声明',
            content: '本应用按"现状"提供，不提供任何明示或暗示的保证。我们不保证服务不会中断或无错误，也不保证缺陷会被纠正。',
          ),
          _buildSection(
            context,
            title: '服务变更',
            content: '我们保留随时修改或终止服务的权利，恕不另行通知。我们不对任何服务修改、暂停或终止向用户或第三方负责。',
          ),
          _buildSection(
            context,
            title: '用户生成内容',
            content: '用户对其在应用中创建、传输或显示的任何内容负完全责任。我们保留删除任何违反本协议或适用法律的内容的权利。',
          ),
          _buildSection(
            context,
            title: '账户终止',
            content: '我们保留因违反本协议或长期不活动而终止用户账户的权利。账户终止后，用户对某些内容的访问可能会被立即禁止。',
          ),
          _buildSection(
            context,
            title: '法律适用',
            content: '本协议受中华人民共和国法律管辖。任何争议应通过友好协商解决，如协商不成，应提交至有管辖权的法院。',
          ),
          _buildSection(
            context,
            title: '联系我们',
            content: '如果您对本用户协议有任何问题或建议，请通过以下方式联系我们：\n\nEmail: support@wafusg.com',
          ),
          const SizedBox(height: 16),
          Text(
            '最后更新日期：2024年3月20日',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
} 