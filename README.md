# MikrotikClientsMonitoring - скрипт мониторинга состояния клиентов сети 
Скрипт предназначен для оповещения системного администратора о смене статуса клиентов сети и подразумевает работу на устройстве с поднятыми сетевым мостом и DHCP-сервером, из которых черпается информация о клиентах сети и их активности (устройство в роли типового домашнего шлюза с поднятыми сетевыми службами).

Во время работы скрипт формирует в памяти устройства базу клиентов и актуализирует её при каждом запуске. В случае смены статуса сетевого клиента, скрипт вносит соответствующую запись в журнал устройства. Для отправки уведомлений в Телеграм следует задействовать TLGRM: https://github.com/drpioneer/MikrotikTelegramMessageHandler .

В скрипте имеется вспомогательная база клиентов, в которую при необходимости можно внести игнорируемых клиентов или удобочитаемые имена клиентов.

Обкатка скрипта проводилась на актуальных версиях RouterOS 6.49.++ и 7.16.++ . Тело скрипта необходимо закинуть в 'System/Scripts' и настроить запуск по расписанию 'System/Scheduler' с периодом 1 минуту. В случае ОБНОВЛЕНИЯ скрипта, перед его запуском необходимо удалить из памяти устройства переменную 'clients', находящуюся в 'System/Scripts/Enviroment'.

Пример работы скрипта в связке с TLGRM:
```
Notification, [03.10.2024 17:38]
🍒 Mikrotik2: 17:37:57 ++ Erop OKOJlO 'Mikrotik2' ++

Notification, [03.10.2024 18:26]
🍒 Mikrotik2: 18:25:57 ++ AHDpeu OKOJlO 'Mikrotik2' ++

Notification, [03.10.2024 19:12]
🍒 Mikrotik2: 19:11:57 -- Erop BHE 3OHbl 'Mikrotik2' c 18:53 --

Notification, [03.10.2024 19:18]
🍒 Mikrotik2: 19:17:57 -- AHDpeu BHE 3OHbl 'Mikrotik2' c 18:59 --

Notification, [03.10.2024 19:37]
🍒 Mikrotik1: 19:37:35 -- TaTbRHa BHE 3OHbl 'Mikrotik1' c 19:19 --

Notification, [03.10.2024 19:52]
🍒 Mikrotik1: 19:52:35 ++ Desktop 6opoDa OKOJlO 'Mikrotik1' ++

Notification, [03.10.2024 20:25]
🍒 Mikrotik1: 20:25:35 -- Desktop 6opoDa BHE 3OHbl 'Mikrotik1' c 20:07 --

Notification, [03.10.2024 21:40]
🍒 Mikrotik2:
21:39:57 ++ Erop OKOJlO 'Mikrotik2' ++
21:39:57 ++ Desktop DaHuuJl eth OKOJlO 'Mikrotik2' ++

Notification, [03.10.2024 22:06]
🍒 Mikrotik2: 22:05:57 ++ AHDpeu OKOJlO 'Mikrotik2' ++

Notification, [03.10.2024 22:15]
🍒 Mikrotik1: 22:15:35 ++ DuMoH OKOJlO 'Mikrotik1' ++

Notification, [03.10.2024 22:33]
🍒 Mikrotik2: 22:32:56 ++ DaHuuJl OKOJlO 'Mikrotik2' ++

Notification, [04.10.2024 4:55]
🍒 Mikrotik2: 04:54:56 ++ Printer Brother OKOJlO 'Mikrotik2' ++

Notification, [04.10.2024 6:15]
🍒 Mikrotik2: 06:14:57 -- Printer Brother BHE 3OHbl 'Mikrotik2' c 05:56 --

Notification, [04.10.2024 6:29]
🍒 Mikrotik2: 06:28:56 ++ Printer Brother OKOJlO 'Mikrotik2' ++

Notification, [04.10.2024 7:06]
🍒 Mikrotik1: 07:06:35 ++ Desktop 6opoDa OKOJlO 'Mikrotik1' ++

Notification, [04.10.2024 7:33]
🍒 Mikrotik2: 07:32:57 -- AHDpeu BHE 3OHbl 'Mikrotik2' c 07:14 --

Notification, [04.10.2024 8:04]
🍒 Mikrotik1: 08:04:35 -- Desktop 6opoDa BHE 3OHbl 'Mikrotik1' c 07:46 --
```
