<div>

[**简体中文**](README_zh_CN.md)

</div>

# FlClash

[![Downloads](https://img.shields.io/github/downloads/makriq-org/FlClash/total?style=flat-square&logo=github)](https://github.com/makriq-org/FlClash/releases/)[![Last Version](https://img.shields.io/github/release/makriq-org/FlClash/all.svg?style=flat-square)](https://github.com/makriq-org/FlClash/releases/)[![License](https://img.shields.io/github/license/makriq-org/FlClash?style=flat-square)](LICENSE)

Android-first форк FlClash, который `makriq` развивает как самостоятельный продукт для Android VPN hardening, безопасных релизов и будущих сетевых функций вроде встроенного ByeByeDPI.

Репозиторий больше не позиционируется как кроссплатформенный продукт. В дереве всё ещё могут оставаться унаследованные desktop-компоненты апстрима, но они считаются legacy-слоем: не входят в публичный scope форка, не описываются как поддерживаемые и не участвуют в релизном контуре.

## Фокус форка

- устранять практические Android VPN-утечки и делать безопасные дефолты нормой;
- развивать Android-специфичные функции, которые имеют смысл именно для мобильного клиента;
- держать документацию, релизы и технические решения внутри этого репозитория;
- готовить основу для следующих Android-возможностей, включая встроенный ByeByeDPI.

## Что уже сделано

В hardened Android VPN-режиме этот форк уже закрывает и ограничивает такие client-side поверхности:

- локальные `mixed` / `socks` / `http` listeners;
- доступный с localhost `external-controller`;
- публикацию Android system proxy;
- стабильные, легко узнаваемые параметры туннеля.

Дополнительно форк восстанавливает корректную доменную маршрутизацию на усиленном TUN-пути и умеет принимать split tunneling по приложениям прямо из профиля через:

- `tun.exclude-package` и `tun.include-package`;
- `tun.exclude-package-file` и `tun.include-package-file`;
- `tun.exclude-package-url` и `tun.include-package-url`;
- маски, `re:`-регулярные выражения и `!`-исключения внутри списков пакетов.

Важно: цель форка в том, чтобы сократить клиентские признаки и устранить утечки, которые приложение создаёт само. Форк не заявляет о полном сокрытии Android VPN от публичных API без root/Xposed/LSPosed.

## Документация

- [Исследование защиты Android VPN](docs/android-vpn-hardening.md)
- [Раздельное туннелирование Android через профиль](docs/android-profile-split-tunneling.md)
- [Процесс Android-релизов](docs/releasing.md)
- [Политика сопровождения и коммитов](CONTRIBUTING.md)
- [Политика безопасности](SECURITY.md)
- [План развития](ROADMAP.md)
- [Журнал изменений](CHANGELOG.md)

## Интерфейс

<p style="text-align: center;">
    <img alt="mobile" src="snapshots/mobile.gif">
</p>

## Сборка

1. Обновите submodules.

   ```bash
   git submodule update --init --recursive
   ```

2. Установите `Flutter`, `Go`, `Android SDK` и `Android NDK`.

3. Соберите Android-артефакты.

   ```bash
   dart setup.dart android
   ```

## Релизы

- Веточные Android-артефакты публикует GitHub Actions workflow `android-веточная-сборка`.
- Теги `v*` публикуют стабильные Android-релизы, а `v*-preN` создают Android prerelease.
- Публичные release notes собираются из верхней секции `CHANGELOG.md`.
- Подробные технические заметки по релизу при необходимости живут в `docs/releases/`.
