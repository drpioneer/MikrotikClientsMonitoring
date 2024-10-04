# MikrotikClientsMonitoring - скрипт мониторинга состояния клиентов сети 
Скрипт предназначен для оповещения системного администратора о смене статуса клиентов сети и подразумевает работу на устройстве с поднятыми сетевым мостом и DHCP-сервером, из которых черпается информация о клиентах сети и их активности (устройство в роли типового домашнего шлюза, на котором подняты все необходимые сетевые службы).

Во время работы скрипт формирует в памяти устройства базу клиентов и актуализирует её при каждом запуске. В случае смены статуса сетевого клиента, скрипт отправляет соответствующую запись в журнал устройства. Для дальнейшей отправки уведомлений в Телеграм можно задействовать скрипт TLGRM: https://github.com/drpioneer/MikrotikTelegramMessageHandler .

В скрипте предусмотрена вспомогательная база клиентов, в которую при необходимости можно внести удобочитаемые имена клиентов или клиентов, которых нужно игнорировать.

Обкатка скрипта проводилась на актуальных версиях RouterOS 6.49.++ и 7.14.++ . Тело скрипта необходимо закинуть в 'System/Scripts' и настроить запуск по расписанию из 'System/Scheduler' с периодом 1 минуту. В случае ОБНОВЛЕНИЯ скрипта, перед его запуском необходимо удалить из памяти устройства переменную 'clients', находящуюся в 'System/Scripts/Enviroment'.

Пример работы скрипта:
```
Notification, [03.10.2024 17:38]
🍒 roJloBHou: 17:37:57 ++ Erop OKOJlO 'roJloBHou' ++

Notification, [03.10.2024 18:26]
🍒 roJloBHou: 18:25:57 ++ AHDpeu OKOJlO 'roJloBHou' ++

Notification, [03.10.2024 19:12]
🍒 roJloBHou: 19:11:57 -- Erop BHE 3OHbl 'roJloBHou' c 18:53 --

Notification, [03.10.2024 19:18]
🍒 roJloBHou: 19:17:57 -- AHDpeu BHE 3OHbl 'roJloBHou' c 18:59 --

Notification, [03.10.2024 19:37]
🍒 DaJlbHuu: 19:37:35 -- TaTbRHa BHE 3OHbl 'DaJlbHuu' c 19:19 --

Notification, [03.10.2024 19:52]
🍒 DaJlbHuu: 19:52:35 ++ Desktop 6opoDa OKOJlO 'DaJlbHuu' ++

Notification, [03.10.2024 20:25]
🍒 DaJlbHuu: 20:25:35 -- Desktop 6opoDa BHE 3OHbl 'DaJlbHuu' c 20:07 --

Notification, [03.10.2024 21:40]
🍒 roJloBHou:
21:39:57 ++ Erop OKOJlO 'roJloBHou' ++
21:39:57 ++ Desktop DaHuuJl eth OKOJlO 'roJloBHou' ++

Notification, [03.10.2024 22:06]
🍒 roJloBHou: 22:05:57 ++ AHDpeu OKOJlO 'roJloBHou' ++

Notification, [03.10.2024 22:15]
🍒 DaJlbHuu: 22:15:35 ++ DuMoH OKOJlO 'DaJlbHuu' ++

Notification, [03.10.2024 22:33]
🍒 roJloBHou: 22:32:56 ++ DaHuuJl OKOJlO 'roJloBHou' ++

Notification, [04.10.2024 4:55]
🍒 roJloBHou: 04:54:56 ++ Printer Brother OKOJlO 'roJloBHou' ++

Notification, [04.10.2024 6:15]
🍒 roJloBHou: 06:14:57 -- Printer Brother BHE 3OHbl 'roJloBHou' c 05:56 --

Notification, [04.10.2024 6:29]
🍒 roJloBHou: 06:28:56 ++ Printer Brother OKOJlO 'roJloBHou' ++

Notification, [04.10.2024 7:06]
🍒 DaJlbHuu: 07:06:35 ++ Desktop 6opoDa OKOJlO 'DaJlbHuu' ++

Notification, [04.10.2024 7:33]
🍒 roJloBHou: 07:32:57 -- AHDpeu BHE 3OHbl 'roJloBHou' c 07:14 --

Notification, [04.10.2024 8:04]
🍒 DaJlbHuu: 08:04:35 -- Desktop 6opoDa BHE 3OHbl 'DaJlbHuu' c 07:46 --
```
