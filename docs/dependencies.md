# 直接依赖与用途

阶段 1 的实际解析版本以 `pubspec.lock` 为准。下表许可已核对本机下载包的 LICENSE；Flutter SDK 自身为 BSD-3-Clause。插件用于能力验证，其生产业务尚未实现。

| 依赖 | 当前版本 | 用途 | 许可 |
| --- | --- | --- | --- |
| flutter_riverpod | 3.4.3 | 依赖作用域、异步资源生命周期 | MIT |
| go_router | 18.1.1 | 集中路由及底部导航 | BSD-3-Clause |
| drift | 2.35.2 | SQLite 持久化与事务 | MIT |
| file_picker | 13.1.0 | 双端系统保存/选择文件 | MIT |
| path_provider | 2.1.6 | 应用私有与临时目录 | BSD-3-Clause |
| flutter_local_notifications | 22.3.2 | 权限、通知排程及查询/取消 | BSD-3-Clause |
| flutter_timezone | 5.1.1 | 读取设备实际时区标识 | Apache-2.0 |
| timezone | 0.11.2 | 时区数据库及通知排程时间 | BSD-2-Clause |
| cupertino_icons | 2.0.0 | Flutter 页面使用的 Cupertino 图标字体 | MIT |

Flutter 本地化、测试与集成测试来自同一 SDK；flutter_lints 提供静态检查基线。升级时需重新验证兼容性、许可与锁文件，尤其复查 file_picker 的 Android Gradle 对齐规则。二进制保留 Flutter 汇总的第三方许可资产；正式交付阶段还须核对素材来源及用户可访问的许可展示。
