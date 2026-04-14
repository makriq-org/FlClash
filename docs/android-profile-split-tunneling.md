# Раздельное туннелирование Android через профиль

Этот форк умеет читать Android split tunneling по приложениям прямо из профиля и передавать его в системный `VpnService`.

## Что поддерживается

- `tun.exclude-package`
  Эти приложения полностью обходят VPN, независимо от доменов, IP-адресов и правил маршрутизации.
- `tun.include-package`
  Через VPN идут только перечисленные приложения. Все остальные Android-приложения обходят VPN.
- `tun.exclude-package-file`
  Один путь или список путей к файлам со списками пакетов для исключения из VPN.
- `tun.include-package-file`
  Один путь или список путей к файлам со списками пакетов для whitelist-режима.

Эти поля читаются из итогового профиля перед запуском Android VPN и имеют приоритет над app-side списком приложений, настроенным вручную в интерфейсе.

## Что писать в профиле

### Исключить приложения из VPN

```yaml
tun:
  enable: true
  stack: system
  exclude-package:
    - org.telegram.messenger
    - com.android.chrome
```

Результат:

- `org.telegram.messenger` и `com.android.chrome` всегда идут мимо VPN;
- остальные приложения продолжают идти через VPN как обычно.

### Пустить через VPN только выбранные приложения

```yaml
tun:
  enable: true
  stack: system
  include-package:
    - com.termux
    - org.mozilla.firefox
```

Результат:

- через VPN идут только `com.termux` и `org.mozilla.firefox`;
- остальные приложения обходят VPN.

### Подключить список пакетов из файла

```yaml
tun:
  enable: true
  exclude-package-file:
    - lists/android-bypass.txt
    - /storage/emulated/0/FlClash/more-bypass.txt
```

Поддерживаются:

- один путь строкой;
- YAML-список путей;
- относительные пути от каталога профилей FlClash;
- абсолютные пути.

Файл со списком пакетов может быть в одном из двух форматов.

Обычный текст:

```text
# один пакет на строку
org.telegram.messenger
com.android.chrome
```

Или YAML-список:

```yaml
- org.telegram.messenger
- com.android.chrome
```

Содержимое файлов автоматически подмешивается в `tun.include-package` или `tun.exclude-package`, а сами поля `*-package-file` используются только клиентом FlClash.

## Ограничения и правила

- Используй только один режим: либо `tun.include-package` / `tun.include-package-file`, либо `tun.exclude-package` / `tun.exclude-package-file`.
- Если одновременно заданы include- и exclude-режимы, FlClash отклонит такой профиль как конфликтный.
- Эти поля применяются только в Android VPN-режиме.
- Это split tunneling по приложениям, а не по адресам: если приложение исключено из VPN, весь его трафик идет мимо VPN.

## Что не требуется

Для этого режима не нужно настраивать `allowBypass`. В этом форке `allowBypass` всё равно принудительно отключается в hardened Android VPN-режиме и не используется как основной механизм profile-driven split tunneling.
