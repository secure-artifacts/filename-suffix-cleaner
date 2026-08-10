# Filename Suffix Cleaner

一个面向 Windows 的小型批量改名工具，用来删除文件名末尾的：

```text
_行数字_subtitled
```

例如：

```text
示例视频-9_行11_subtitled.mp4
→
示例视频-9.mp4
```

项目完全使用 Windows PowerShell 编写，无需安装第三方软件、无需联网，也不需要管理员权限。

## 功能

- 在文件夹右键菜单中一键批量清理文件名。
- 支持把文件夹拖到批处理入口上直接处理。
- 仅匹配文件名末尾的 `_行数字_subtitled`，不会误删正文中间的类似文本。
- 保留文件扩展名和文件内容。
- 目标文件已存在时自动跳过，避免覆盖。
- 自动保存改名记录，可从右键菜单撤销上一次操作。
- 安装只写入当前用户注册表，不需要管理员权限。
- 卸载时保留改名历史，避免误删恢复信息。

## 系统要求

- Windows 10 或 Windows 11
- Windows PowerShell 5.1 或更高版本
- 文件资源管理器

## 普通用户使用

### 安装右键菜单

1. 完整解压发布包。
2. 双击 `安装右键菜单.cmd`。
3. 打开待处理文件所在的文件夹。
4. 在文件夹空白处右键。
5. Windows 11 用户先选择“显示更多选项”。
6. 点击“一键去掉 _行xx_subtitled”。

也可以直接右键某个文件夹，再选择同一菜单。

### 免安装使用

把目标文件夹拖到 `拖入文件夹立即清理.cmd` 上。

### 撤销

在刚才处理过的文件夹中右键，选择“撤销上次改名”。工具会恢复最近一次尚未撤销的改名记录。

### 卸载

双击 `卸载右键菜单.cmd`。

## 匹配规则

内部使用的正则表达式等价于：

```regex
_行\d+_subtitled$
```

匹配不区分 `subtitled` 的大小写，仅处理当前文件夹中的文件，不递归处理子文件夹。

| 原文件名 | 结果 |
|---|---|
| `demo_行1_subtitled.mp4` | `demo.mp4` |
| `demo_行25_SUBTITLED.mkv` | `demo.mkv` |
| `demo_行1_subtitled_final.mp4` | 不处理 |
| `demo_subtitled.mp4` | 不处理 |

## 项目结构

```text
filename-suffix-cleaner-source/
├─ .github/workflows/release.yml
├─ .gitattributes
├─ .gitignore
├─ README.md
├─ CHANGELOG.md
├─ VERSION
├─ LICENSE-NOTICE.md
├─ SECURITY.md
├─ src/
│  ├─ Install.ps1
│  ├─ Remove-XxSubtitled.ps1
│  ├─ Undo-XxSubtitled.ps1
│  └─ Uninstall.ps1
├─ launchers/
│  ├─ 安装右键菜单.cmd
│  ├─ 卸载右键菜单.cmd
│  └─ 拖入文件夹立即清理.cmd
├─ docs/
│  ├─ 用户说明.txt
│  ├─ 实现说明.md
│  └─ 提交审核清单.md
├─ tests/
│  ├─ Test-FilenameSuffixCleaner.ps1
│  ├─ Test-ReleaseWorkflow.ps1
│  └─ 运行测试.cmd
└─ tools/
   └─ Build-Release.ps1
```

## 开发与测试

在项目根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-FilenameSuffixCleaner.ps1
```

或者双击 `tests\运行测试.cmd`。

测试会在系统临时目录中创建隔离样例，验证：

- 正常匹配和改名；
- 非匹配文件保持不变；
- 重名保护；
- 改名历史；
- 撤销恢复。
- 发布 Workflow 的 tag、权限、Attestation 和 Release 配置。

## 构建发布包

运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-Release.ps1
```

生成文件位于 `dist` 目录。发布包为扁平结构，普通用户解压后即可双击使用。

## GitHub 安全发布

仓库包含 `.github/workflows/release.yml`。推送与 `VERSION` 一致的 `v*` tag 后，GitHub Actions 会在 `windows-latest` 上运行测试和构建，为最终 `dist/*` 产物生成 Artifact Attestation，再由 `github-actions[bot]` 创建 Release。

提交 `secure-artifacts` 审核前，请完整执行 [`docs/提交审核清单.md`](docs/提交审核清单.md)。不要手工向 Release 上传文件，也不要用个人 PAT 代替默认 `GITHUB_TOKEN`。

## 安全与隐私

- 工具不读取或修改文件内容，只修改文件名。
- 工具不联网，不上传任何数据。
- 改名日志保存在：

```text
%LOCALAPPDATA%\FilenameSuffixCleaner\logs
```

- 右键菜单注册在当前用户范围：

```text
HKEY_CURRENT_USER\Software\Classes\Directory
```

更多技术细节见 [`docs/实现说明.md`](docs/实现说明.md)。

## 许可证说明

当前源码包未主动声明开源许可证。公开发布或允许他人再分发前，请由项目所有者选择并添加合适的许可证。详见 [`LICENSE-NOTICE.md`](LICENSE-NOTICE.md)。公开仓库提交前还必须确认不含任何内部信息或真实业务数据。
