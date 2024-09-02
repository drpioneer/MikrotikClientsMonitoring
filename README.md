# MikrotikClientsMonitoring - скрипт мониторинга состояния абонентов сети 
Скрипт предназначен для оповещения администратора о смене статуса клиентов сети.
Код скрипта содержит в себе всё необходимое для работы и не имеет зависимостей. Скрипт подразумевает работу на устройстве с поднятыми DHCP-сервером и сетевым мостом, из которых черпается информация о сетевых клиентах и их активности. Скрипт формирует в памяти устройства базу клиентов и актуализирует её при каждом запуске. При смене статуса абонента скрипт выводит соответствующую запись в журнал устройства. Отправка записей в Телеграм может производиться при помощи скрипта оповещения в Телеграм (TLGRM): https://github.com/drpioneer/MikrotikTelegramMessageHandler . В скрипте предусмотрена вспомогательная база клиентов, в которую можно внести удобочитаемые имена клиентов, или тех клиентов, которых нужно игнорировать. Обкатка скрипта проводилась на актуальных версиях RouterOS 6.49.++ и 7.14.++ . Тело скрипта необходимо закинуть в System/Scripts и настроить запуск по расписанию из System/Scheduler с периодом 5 минут. При установке обновленной версии скрипта, перед его запуском необходимо удалить из памяти устройства переменную 'clients' (System/Scripts/Enviroment).
