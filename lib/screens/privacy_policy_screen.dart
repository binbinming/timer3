import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: '引言',
            content: '我们重视您的隐私。本隐私政策说明了我们如何收集、使用、披露和保护您的个人信息。使用我们的应用即表示您同意本隐私政策中描述的数据实践。',
          ),
          _buildSection(
            context,
            title: '信息收集',
            content: '''我们可能收集以下类型的信息：

• 设备信息：设备型号、操作系统版本、唯一设备标识符
• 使用数据：应用功能使用情况、性能数据、崩溃报告
• 用户偏好：应用设置、主题选择、通知偏好''',
          ),
          _buildSection(
            context,
            title: '信息使用',
            content: '''我们使用收集的信息：

• 提供和维护应用服务
• 改进用户体验
• 发送服务相关通知
• 提供客户支持
• 防止欺诈和滥用''',
          ),
          _buildSection(
            context,
            title: '信息共享',
            content: '''我们不会出售您的个人信息。我们仅在以下情况下共享信息：

• 经您同意
• 遵守法律要求
• 保护我们的权利和财产
• 防止非法活动或人身安全威胁''',
          ),
          _buildSection(
            context,
            title: '数据安全',
            content: '我们采用行业标准的安全措施保护您的信息，防止未经授权的访问、披露、更改和破坏。',
          ),
          _buildSection(
            context,
            title: '儿童隐私',
            content: '我们的服务不面向13岁以下的儿童。如果我们发现无意中收集了儿童的个人信息，我们会立即删除这些信息。',
          ),
          _buildSection(
            context,
            title: '您的权利',
            content: '''您对您的个人信息拥有以下权利：

• 访问您的个人信息
• 更正不准确的信息
• 删除您的信息
• 撤回同意
• 选择退出某些数据收集''',
          ),
          _buildSection(
            context,
            title: '第三方服务',
            content: '我们的应用可能包含第三方服务（如分析工具）的链接。这些服务有自己的隐私政策，我们建议您查看这些政策。',
          ),
          _buildSection(
            context,
            title: '政策更新',
            content: '我们可能会更新本隐私政策。更新时，我们会在应用中通知您并更新"最后修改日期"。继续使用我们的服务即表示您接受更新后的政策。',
          ),
          _buildSection(
            context,
            title: '联系我们',
            content: '如果您对本隐私政策有任何问题或建议，请通过以下方式联系我们：\n\nEmail: support@wafusg.com',
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