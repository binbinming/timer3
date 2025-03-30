import 'package:flutter/material.dart';

class VersionInfoScreen extends StatelessWidget {
  const VersionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本说明'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVersionCard(
            context,
            version: '1.0.0',
            date: '2024年3月',
            features: [
              '全新界面设计，简洁直观的操作体验',
              '支持计时器、闹钟和秒表功能',
              '深色模式支持，保护夜间使用时的视觉体验',
              '声音和振动提醒功能',
              '可自定义的通知设置',
              '支持社交媒体分享',
              '支持用户评分反馈',
            ],
            isLatest: true,
          ),
          const SizedBox(height: 16),
          _buildVersionCard(
            context,
            version: '0.9.0 Beta',
            date: '2024年2月',
            features: [
              '基础计时器功能',
              '基础闹钟功能',
              '基础秒表功能',
              '界面优化和bug修复',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String version,
    required String date,
    required List<String> features,
    bool isLatest = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本号和日期
            Row(
              children: [
                Text(
                  'v$version',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '最新版本',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 功能列表
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
} 