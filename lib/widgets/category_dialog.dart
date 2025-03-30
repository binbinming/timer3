import 'package:flutter/material.dart';
import '../models/app_model.dart';

/// 显示创建分类对话框（静态方法，避免使用Provider）
class CategoryDialog {
  /// 显示新建分类对话框
  static Future<void> show(
    BuildContext context,
    List<String> existingCategories,
    Function(String) onCategoryAdded,
  ) async {
    final TextEditingController controller = TextEditingController();

    // 创建一个简单对话框
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('新建分类'),
          contentPadding: const EdgeInsets.all(16),
          children: [
            // 分类名称输入框
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                final name = value.trim();
                if (name.isNotEmpty && !existingCategories.contains(name)) {
                  Navigator.pop(dialogContext, name);
                }
              },
            ),

            const SizedBox(height: 16),

            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty && !existingCategories.contains(name)) {
                      Navigator.pop(dialogContext, name);
                    }
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        );
      },
    ).then((newCategory) {
      // 释放控制器
      controller.dispose();

      // 处理新分类
      if (newCategory != null && newCategory.isNotEmpty) {
        // 调用回调函数添加分类
        onCategoryAdded(newCategory);

        // 通知其他组件有新分类
        AppEvents().categoryAddedNotifier.value = newCategory;
      }
    });
  }
}
