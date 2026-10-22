# 阶段 1 执行记录

记录日期：2026-10-22。状态：基础工程与 Android 构建完成，平台功能验收未完成，尚不标记阶段 1 全部通过。**正式工时录入、工资计算、统计、备份和每日提醒业务尚未实现**。用户已授权通过 `codex/stage1-download` 分支和 GitHub Actions 分发源码及开发验证包，要求附上阶段说明；不代表正式业务版交付。

## 已完成

- 固定 Flutter 3.47.7 官方提交、Dart 3.13.5、Java 21、Android SDK 36、NDK、Gradle 及依赖锁。工具版本和下载校验见 `toolchains.lock.json`、Gradle wrapper 与 `pubspec.lock`。
- 用官方生成器建立 Android/iOS 工程，保留已确认方案。实现中文奶油手账主题、首页/月历/统计/设置四个入口和明确的空状态。
- 建立独立平台验证页：SQLite 计数器、受大小限制的版本化 JSON、系统保存/打开文件、通知权限及排程/查询/取消。它不保存工时或收入，也不是正式备份功能。
- 建立分层维护规则、格式化/分析/测试脚本和 GitHub Actions 基线；远端结果单独以对应 Actions 运行记录为准。
- 完整安装脚本 `scripts/setup-cloud.sh` 已在当前环境执行成功；Android 引导重复安装及版本核对通过。容器使用正常可写用户目录，不重设 HOME；保留代理、TLS 和下载完整性校验。

## 最新验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式化 | 13 个 Dart 文件，无需改动 |
| 静态分析 | `No issues found` |
| 共享代码测试 | 5 项通过：SQLite 重开持久化与事务回滚；JSON 往返、流大小限制与无效输入；中文启动及四入口导航 |
| Android 正常应用构建 | 最终开发版 APK 构建通过；独立副本和 SHA-256 在 `artifacts`，入口为 MainActivity，含 ARMv7、ARM64 与 x64 |
| Android AOT 验证构建 | API 36 x64 profile APK 构建通过，已安装并显示真实应用页面 |
| Android UI 平台检查 | 失败：UIAutomator 未能读回页面，报告 0 项功能通过；实际截图显示应用已正常呈现，不能据此代替文件、数据库和通知的设备验收 |
| 原生 Dart 集成用例 | 4 项未执行：JIT 测试 APK 安装失败，不能报告通过 |
| Android 真机 | 未安装或验证 |
| iOS | 工程已生成；未编译、签名或真机验证 |

本次最终共享检查日志：`/workspace/.toolchains/logs/final-shared-checks.log`。Android 构建与设备操作分别记录在 `final-android-build.log`、`profile-apk-build.log`、`profile-ui-smoke.log`；`ui-logcat.txt` 保存系统 UIAutomation 连接超时及媒体/电话系统服务启动 ANR 的原始证据。这些是当前工作区证据，不假定远端 CI 或新环境恢复已运行。

## 设备验证方法与限制

云机没有 `/dev/kvm`，使用 API 36 AOSP x86_64 revision 2 的单核软件模拟器。冷启动耗时较长；Google APIs 镜像的早期尝试未作为成功证据。

真实系统日志显示慢速类加载触发 Android 默认 Watchdog，导致 system_server 重启。根据 Android 16 的公开设置，将**自有测试 AVD** 的 `watchdog_timeout_millis` 调至 300000，保留监控。没有修改应用断言、启动完成标记或通知时间。此措施不代表手机性能验收。

大体积 JIT 集成测试包在安装期间出现断连/系统重启，4 项 Dart 集成用例尚未执行。保留原用例，并另建较小的 AOT profile 包，通过真实 UI 与系统对话框验证：

1. 应用启动及导航。
2. SQLite 写入、强制停止应用、重开后读回相同值。
3. 本地 JSON 文件往返。
4. 系统保存到 Downloads，再通过系统选择器打开，核对原值。
5. 实际请求通知权限，核对排程后待处理状态，再取消并核对为空。

开发版显式打开语义树，便于系统可访问性工具读取控件；模拟器密度固定为 160。检查读取实际结果，不模拟平台通道。即使排程/取消通过，也不等于通知已经送达或每日提醒业务已验收。

最终 AOT 运行中，安装返回 Success，系统记录 MainActivity 已显示，截图可见中文首页。UIAutomation 的连接却发生 TimeoutException，多次尝试后检查超时，5 项 UI 功能均未通过；并非读取到工资算法错误。退出时模拟器还报告了原生段错误。上述限制需要在具备硬件加速的模拟器或真实手机上复验；没有删除断言或虚构平台成功。

## 环境问题与修复

- 用户发布网络配置后，`storage.googleapis.com` 的官方引擎产物下载成功。旧发布索引返回 404；引导按固定源码的 `engine.version` 检查实际官方产物，不以不存在的索引阻挡源码安装。
- 宿主机用户目录只读，ADB/Dart 无法保存自身状态。使用非特权容器的自然 `/home/builder` 解决，没有重设 HOME 或修改官方工具。
- 平台 CA 在运行时挂载至系统默认信任位置；Java 使用临时信任库。SQLite 原生资产校验保持开启。
- 文件选择插件的 Android Gradle 版本对齐和 Maven 仓库范围调整见 [architecture.md](architecture.md)。没有修改第三方缓存或使用未知镜像。

最新完整安装脚本及启动说明已保存为环境配置草稿；草稿不等于发布。当前运行已验证的下载权限不再阻塞开发。若要让后续任务恢复新增工具和工程，可在环境界面审阅、保存并发布这份更新；不假定进程或模拟器随快照继续运行。

## 产物与后续条件

- `artifacts/worktime-journal-stage1-debug.apk`：正常应用入口，开发版平台验证可见；不是最终业务 APP。
- `artifacts/worktime-journal-stage1-x64-profile.apk`：软件模拟器专用，不用于普通 ARM 手机安装。
- `artifacts/SHA256SUMS`：产物校验；`android-ui-smoke.json`：失败报告，`stage1-screen.png`：实际首页截图。此次未成功导出 UI XML，不提供虚构的 `last-ui.xml`。

安装和手机复验步骤见 [stage-1-install.md](stage-1-install.md)。

iOS 编译与签名需要 Mac/Xcode；仍需用户的目标安卓/iPhone 型号、系统版本和苹果账号条件。条件不足单独记录，不用 Android 结果替代 iPhone 验证。平台基础验证完成后，下一阶段是整数工资计算、时薪版本、历史快照与正式数据库。
