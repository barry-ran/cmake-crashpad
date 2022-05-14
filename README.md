# cmake-crashpad
cmake项目集成crashpad（win&mac平台）

当前crashpad版本：chromium 87.0.4280.9 2020年12月2日版本 -> crashpad Revision 36d4bb

- 支持win&mac平台
- github action自动编译crashpad并生成相关产物，方便后续复用
- cmake脚本引入crashpad
- crashpad基示例本代码

# 注意事项
- 构建crashpad时，要使用和Qt项目完全相同的Visual Studio版本，否则编译出错
- Qt项目不能与/MT /MTd一起使用，所以需要编译/MD /MDd版本

# 参考文档
- [Qt项目使用crashpad上报dump到BugSplat教程](https://docs.bugsplat.com/introduction/getting-started/integrations/cross-platform/qt/)
- [Qt项目使用crashpad上报dump到BugSplat示例](https://github.com/BugSplat-Git/my-qt-crasher)
- [crashpad编译官方教程](https://chromium.googlesource.com/crashpad/crashpad/+/HEAD/doc/developing.md)

- [crashpad上报dump到backtrace教程](https://support.backtrace.io/hc/en-us/articles/360040516131-Crashpad-Integration-Guide#InitialIntegration)
