<div>

[**English**](README.md)

</div>

## FlClash

[![Downloads](https://img.shields.io/github/downloads/makriq3/FlClash/total?style=flat-square&logo=github)](https://github.com/makriq3/FlClash/releases/)[![Last Version](https://img.shields.io/github/release/makriq3/FlClash/all.svg?style=flat-square)](https://github.com/makriq3/FlClash/releases/)[![License](https://img.shields.io/github/license/makriq3/FlClash?style=flat-square)](LICENSE)

这是由 `makriq3` 独立维护的 FlClash 发布线，重点在于 Android 隐私加固、更顺手的更新体验，以及完全由本仓库掌控的发布流程。

- 研究文档: [docs/android-vpn-hardening.md](docs/android-vpn-hardening.md)
- 安全策略: [SECURITY.md](SECURITY.md)
- 变更记录: [CHANGELOG.md](CHANGELOG.md)

on Desktop:
<p style="text-align: center;">
    <img alt="desktop" src="snapshots/desktop.gif">
</p>

on Mobile:
<p style="text-align: center;">
    <img alt="mobile" src="snapshots/mobile.gif">
</p>

## Features

✈️ 多平台: Android, Windows, macOS and Linux

💻 自适应多个屏幕尺寸,多种颜色主题可供选择

💡 基本 Material You 设计, 类[Surfboard](https://github.com/getsurfboard/surfboard)用户界面

☁️ 支持通过WebDAV同步数据

✨ 支持一键导入订阅, 深色模式

## Use

### Linux

⚠️ 使用前请确保安装以下依赖

   ```bash
    sudo apt-get install libayatana-appindicator3-dev
    sudo apt-get install libkeybinder-3.0-dev
   ```

### Android

支持下列操作

   ```bash
    com.makriq.flclash.action.START
    
    com.makriq.flclash.action.STOP
    
    com.makriq.flclash.action.TOGGLE
   ```

## Download

<a href="https://github.com/makriq3/FlClash/releases"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" width="200px"/></a>

## Build

1. 更新 submodules
   ```bash
   git submodule update --init --recursive
   ```

2. 安装 `Flutter` 以及 `Golang` 环境

3. 构建应用

    - android

        1. 安装  `Android SDK` ,  `Android NDK`

        2. 设置 `ANDROID_NDK` 环境变量

        3. 运行构建脚本

           ```bash
           dart .\setup.dart android
           ```

    - windows

        1. 你需要一个windows客户端

        2. 安装 `Gcc`，`Inno Setup`

        3. 运行构建脚本

           ```bash
           dart .\setup.dart windows --arch <arm64 | amd64>
           ```

    - linux

        1. 你需要一个linux客户端

        2. 运行构建脚本

           ```bash
           dart .\setup.dart linux --arch <arm64 | amd64>
           ```

    - macOS

        1. 你需要一个macOS客户端

        2. 运行构建脚本

           ```bash
           dart .\setup.dart macos --arch <arm64 | amd64>
           ```

## 方向

本仓库作为独立发布线持续维护，逐步建设自己的：

- Android 隐私加固策略
- 应用标识与打包元数据
- 发布流水线
- 安全文档
- 产品路线图
