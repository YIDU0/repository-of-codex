# repository-of-codex

用于开发安卓与 iPhone 的个人工时和收入手账 APP，暂名“工时手账”。无需登录，数据本地保存，采用奶油手账风。

## 当前状态

**第一阶段开发验证版，非正式记账版本。** 用户已授权通过 `codex/stage1-download` 分支与 GitHub Actions 分发。下载包附有 [版本说明](docs/stage-1-build-notes.md)、源码提交和校验值；构建是否成功须查看对应运行记录。

首个 GitHub 构建已成功并上传安装包：[打开下载区域](https://github.com/YIDU0/repository-of-codex/actions/runs/39732332051#artifacts)。登录 GitHub 后，下载 `worktime-journal-stage1-debug`，解压取得 APK 和说明；产物保留 7 天。

需求与开发方案已获确认，正在执行阶段 1。已建立 Flutter 双端工程、奶油手账风页面骨架和开发版平台验证工具，**尚未实现正式工时与工资功能**。

完整 SDK 与 Android 开发版 APK 已构建，静态分析和 5 项共享代码测试已通过。AOT 包在软件模拟器安装并呈现页面；系统 UI 自动化连接超时，设备功能检查未通过，阶段 1 尚未完整验收。iOS 尚未构建或真机验证。实际状态以阶段记录为准。

- [需求方案](docs/requirements.md)
- [开发步骤](docs/development-plan.md)
- [维护规则](docs/development-rules.md)
- [阶段 1 实际记录与阻碍](docs/phase-1.md)
- [第一阶段 Android 开发包安装说明](docs/stage-1-install.md)

## 云端工具链

使用当前隔离 checkout，无需额外 Git worktree。以下命令在仓库根目录运行；工具默认放在仓库同级的 `.toolchains` 中，不提交到 Git。

```bash
source scripts/env.sh
python3 scripts/bootstrap_android.py
python3 scripts/bootstrap_flutter.py
bash scripts/cloud-container.sh build
```

上述步骤已在当前 Linux x86_64 环境执行，Android 安装脚本已重复运行验证。容器提供实际可写的用户目录，解决本云主机 ADB、Dart 分析器和格式化工具的目录限制；不重设 HOME。构建时挂载 CA，运行时挂载会话及系统 CA，并保持下载校验与 TLS 验证。

完整 Flutter 引导使用固定源码声明的官方引擎产物，保持代理和 TLS 校验：

```bash
source scripts/env.sh
python3 scripts/bootstrap_flutter.py
```

`storage.googleapis.com` 已放通，完整引导成功。引导检查固定源码声明的官方引擎地址；旧的发布索引地址返回对象不存在，已不再把它作为源码安装的前提。不要为绕过下载错误而切换不受允许的代理或镜像。

仅检查已安装 Android 版本：

```bash
source scripts/env.sh
python3 scripts/bootstrap_android.py --verify-only
```

版本及校验信息位于 `toolchains.lock.json`，不要通过更改预期校验和或禁用证书校验解决下载错误。

## 运行检查与开发版

本云环境使用容器执行 Dart、Flutter 分析、测试与构建：

```bash
bash scripts/cloud-container.sh bash scripts/check.sh
bash scripts/cloud-container.sh bash scripts/check.sh --android
```

仅开启开发版平台验证入口的构建：

```bash
bash scripts/cloud-container.sh flutter build apk --debug --dart-define=ENABLE_PLATFORM_PROBES=true
```

默认构建不会显示该入口；debug、profile 开发构建需显式打开，release 构建始终禁用。平台验证使用独立数据库，只保存无个人信息的计数器，不作为正式工资数据库。正式工资计算、备份格式和每日提醒策略在后续阶段实现。

安卓模拟器验证需要额外 SDK 包及 AVD，且必须在同一容器里运行模拟器、ADB 和测试：

```bash
source scripts/env.sh
python3 scripts/bootstrap_android.py --with-emulator
bash scripts/cloud-container.sh bash scripts/android-integration.sh
```

脚本自动创建 API 36 AOSP AVD。无 KVM 软件模拟最长等待 15 分钟，测试 AVD 的系统 Watchdog 阈值设置为 300 秒，结束时停止自己启动的模拟器。模拟器日志在 `artifacts/emulator.log`；构建和 AVD 分别使用租约锁。

本云环境的大体积 JIT 测试 APK 在安装时触发了模拟器系统重启，未执行原生 Dart 用例。较小的 AOT profile 包提供相同平台操作的真实 UI 冒烟检查，须单独记录结果：

```bash
bash scripts/cloud-container.sh flutter build apk --profile --target-platform=android-x64 --dart-define=ENABLE_PLATFORM_PROBES=true
cp build/app/outputs/flutter-apk/app-profile.apk artifacts/worktime-journal-stage1-x64-profile.apk
bash scripts/cloud-container.sh bash scripts/android-integration.sh --profile-smoke
```

`--profile-smoke` 使用非流式 ADB 安装和真实系统保存/打开对话框。最近一次因系统 UIAutomation 连接超时失败，尚未执行文件和通知功能检查。结果在 `artifacts/android-ui-smoke.json`，截图在 `artifacts/stage1-screen.png`。x64 profile 包只用于该模拟器，手机测试使用另行生成的对应架构或通用 APK。

GitHub Actions 工作流包含开发版 APK、SHA-256 校验、构建来源和版本说明的上传步骤。从成功运行详情的 Artifacts 下载 `worktime-journal-stage1-debug` 压缩包，保留 7 天，具体步骤见 [安装说明](docs/stage-1-install.md)。源码与依赖锁文件纳入版本控制，SDK、设备数据、签名及构建产物由忽略规则排除。

iOS 原生编译、签名及真机安装需要 Mac/Xcode 与相应苹果账号条件；Linux 云端的结果不代表 iPhone 已验证。
