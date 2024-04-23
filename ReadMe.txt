Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.

Необходимая информация в письме:

Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
Ошибки веб-сервера/приложения c момента последнего запуска;
Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.

В письме должен быть прописан обрабатываемый временной диапазон.

    Для отработки скриптов на просторе интернета нашел пример файла access.log
    Задание выполняю на ВМ на базе ubuntu 20.04  


#################################################################################################################################################3
1. Настройка отправки  почты (https://www.dmosk.ru/miniinstruktions.php?mini=postfix-over-yandex)

    apt install cyrus-imapd cyrus-clients cyrus-doc cyrus-admin sasl2-bin

    Открываем конфигурационный файл postfix: /etc/postfix/main.cf
    Добавим следующие строки:

    relayhost =
    smtp_sasl_auth_enable = yes
    smtp_sasl_password_maps = hash:/etc/postfix/private/sasl_passwd
    smtp_sasl_security_options = noanonymous
    smtp_sasl_type = cyrus
    smtp_sasl_mechanism_filter = login
    smtp_sender_dependent_authentication = yes
    sender_dependent_relayhost_maps = hash:/etc/postfix/private/sender_relay
    smtp_tls_CAfile = /etc/postfix/ca.pem
    smtp_use_tls = yes


    Создаем каталог для конфигов:
    mkdir /etc/postfix/private


    Создаем файл с правилами пересылки сообщений:
    /etc/postfix/private/sender_relay
    root@tep:~# cat /etc/postfix/private/sender_relay
    @yandex.ru    smtp.yandex.ru


    Создаем файл с настройкой привязки логинов и паролей:
    root@tep:~# cat /etc/postfix/private/sasl_passwd
    info-it@tsumvrn.ru	info-it@tsumvrn.ru:********
    ПАРОЛЬ ГЕНЕРИМ ДЛЯ ПРИЛОЖЕНИЙ!


    Создаем карты для данных файлов:
    postmap /etc/postfix/private/{sasl_passwd,sender_relay}


    Получаем сертификат от Яндекса, для этого выполняем запрос:
    openssl s_client -starttls smtp -crlf -connect smtp.yandex.ru:25
    на экран будет выведена различная информация — нам нужна вся, 
    что заключена между -----BEGIN CERTIFICATE----- и -----END CERTIFICATE-----. Копируем ее и создаем файл сертификата:
    root@tep:~# cat /etc/postfix/ca.pem
    -----BEGIN CERTIFICATE-----
    MIIGzTCCBbWgAwIBAgIMNc4q479kk29pKO73MA0GCSqGSIb3DQEBCwUAMFAxCzAJ
    BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
     и т.д



    Перезапускаем Postfix:
    systemctl restart postfix

    Проверка
    Для проверки можно использовать консольную команду mail.

    apt-get install mailutils
    root@tep:~# echo "Test text" | mail -s "Test title" info-it@tsumvrn.ru -aFrom:info-it@tsumvrn.ru

    root@tep:~# cat /var/log/mail.log 
    Apr 22 09:05:37 tep postfix/pickup[4264]: 518C0120543: uid=0 from=<info-it@tsumvrn.ru>
    Apr 22 09:05:37 tep postfix/cleanup[4635]: 518C0120543: message-id=<20240422090537.518C0120543@tep.localdomain>
    Apr 22 09:05:37 tep postfix/qmgr[4265]: 518C0120543: from=<info-it@tsumvrn.ru>, size=336, nrcpt=1 (queue active)
    Apr 22 09:05:38 tep postfix/smtp[4637]: 518C0120543: to=<info-it@tsumvrn.ru>, relay=mx.yandex.net[77.88.21.249]:25, 
    delay=1.2, delays=0.02/0/0.58/0.61, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued on mail-nwsmtp-mxfront-production-main-63.myt.yp-c.yandex.net 1713776738-b5Fuwi0olW20-QT44GJVK)
    Apr 22 09:05:38 tep postfix/qmgr[4265]: 518C0120543: removed



##############################################################################################################################
2. Защита от двойного запуска заданий cron

    Можно реализовать несколькими путями

    2.1 Самый простой это при запуске формировать некий файл и туда записывать "1", а в конце скрипта очищать "1"  или перезаписывать на "0"
    Вначале скрипта делать проверку на существование "1" в этом файле - если есть то прерывание, если нет то продолжаем выполнять скрипт

    2.2 На просторах интернета нашел статью https://habr.com/ru/articles/114622/ 
    Простая защита от двойного запуска заданий cron через утилиту lockrun

        Выполняю инструкции по этой статье.
        качаю исходник
            root@tep:~# wget unixwiz.net/tools/lockrun.c
        компиляция
            root@tep:~# gcc lockrun.c -o lockrun
        копирую в bin
            root@tep:~# sudo cp lockrun /usr/local/bin/


    Пример использования:
    * * * * * /usr/local/bin/lockrun --lockfile=/tmp/megacache.lockrun -- /path/to/megacache/generator  

    2.3 Сложный.
    Использовать в скрипте, который запускается по cron, проверку pid:

    Проверяем наличие pid файла с идентификатором процесса
    Проверяем, есть ли такой pid в памяти командой «ps -p PID»
    Если pid запущен, прерываем работу
    Иначе, пишем в pid файл свой pid и продолжаем

    
    2.4 Простой

    Есть замечательная утилитка в Linux, называется flock. В качестве параметра, утилита принимает имя файла лока и команду для исполнения. 
    flock ставит эксклюзивный лок на указанный файл и, при успехе, запускает указанную команду

    Пример, есть cron задача:
    * * * * *   user  /usr/bin/php /some/heavy/script.php
    
    С помощью небольшой модификации этой строки мы сможем предотвратить повторный запуск задачи во время выполнения предыдущей задачи:
    * * * * *   user  /usr/bin/flock -xn /var/lock/script.lock -c '/usr/bin/php /some/heavy/script.php'

####################################################################################################################################3

3.Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;

файл scriptip.sh:

    1.Читает лог
    2.awk берет столбец с ip адресами
    3.Сортировка
    4.Подсчет уникальных адресов с выводом количества повторений
    5.Вывод информации во временный файл
    6.Условие выведет на экран адреса с количеством повторений больше 10

    root@tep:/home/tep# ./scriptip.sh 
    from 14/Aug/2019:04:12:10 to 15/Aug/2019:00:25:46:
    Count ip > 10
    39 repeats with ip: 109.236.252.130
    22 repeats with ip: 148.251.223.21
    12 repeats with ip: 162.243.13.195
    12 repeats with ip: 185.142.236.35
    20 repeats with ip: 185.6.8.9
    33 repeats with ip: 188.43.241.106
    37 repeats with ip: 212.57.117.19
    17 repeats with ip: 217.118.66.161
    12 repeats with ip: 62.210.252.196
    24 repeats with ip: 62.75.198.172
    31 repeats with ip: 87.250.233.68
    45 repeats with ip: 93.158.167.130
    12 repeats with ip: 95.108.181.93
    16 repeats with ip: 95.165.18.146
    root@tep:/home/tep# 




####################################################################################################################################

4. Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
 
    файл scripturl.sh:

    1.Читаем лог
    2.Забираем URL
    3.Сортировка
    4.Подсчет уникальных URL с выводом количества повторений
    5.Вывод информации во временный файл
    6.Условие выведет на URL адреса с количеством повторений больше 5


    root@tep:/home/tep# ./scripturl.sh 
    URL > 5
    11 repeats with URL: http://www.bing.com
    124 repeats with URL: http://yandex.com
    166 repeats with URL: https://dbadmins.ru
    16 repeats with URL: http://dbadmins.ru
    20 repeats with URL: http://www.domaincrawler.com
    21 repeats with URL: http://www.semrush.com
    9 repeats with URL: http://www.google.com
    root@tep:/home/tep# 

    root@tep:/home/tep# ./scripturl.sh 
    URL > 5
    11 repeats with URL: http://www.bing.com
    124 repeats with URL: http://yandex.com
    166 repeats with URL: https://dbadmins.ru
    16 repeats with URL: http://dbadmins.ru
    20 repeats with URL: http://www.domaincrawler.com
    21 repeats with URL: http://www.semrush.com
    9 repeats with URL: http://www.google.com
    root@tep:/home/tep# 


####################################################################################################################################

5.Ошибки веб-сервера/приложения c момента последнего запуска/cписок всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
    
    файл error.sh:

    1.Забираем коды ошибок в файл tmp
    2.Забираем в файл временной диапазон лога
    3.Выводим информацию со временем и коды ошибок


    root@tep:/home/tep# ./error2.sh 
    Ошибки запросов с 14/Aug/2019:04:12:10 до 15/Aug/2019:00:25:46 -
    коды возврата ошибок:
    301
    304
    400
    403
    404
    405
    499
    500
    ----------------------------------------------------
    все коды возврата:
    200
    301
    304
    400
    403
    404
    405
    499
    500
    root@tep:/home/tep# 



######################################################################################################################################
ИТОГ

Собираем вывод всех скриптов в один файл parse.sh


root@tep:/home/tep# ./parse.sh 
from 14/Aug/2019:04:12:10 to 15/Aug/2019:00:25:46:
Count ip > 10
39 repeats with ip: 109.236.252.130
22 repeats with ip: 148.251.223.21
12 repeats with ip: 162.243.13.195
12 repeats with ip: 185.142.236.35
20 repeats with ip: 185.6.8.9
33 repeats with ip: 188.43.241.106
37 repeats with ip: 212.57.117.19
17 repeats with ip: 217.118.66.161
12 repeats with ip: 62.210.252.196
24 repeats with ip: 62.75.198.172
31 repeats with ip: 87.250.233.68
45 repeats with ip: 93.158.167.130
12 repeats with ip: 95.108.181.93
16 repeats with ip: 95.165.18.146
URL > 5
11 repeats with URL: http://www.bing.com
124 repeats with URL: http://yandex.com
166 repeats with URL: https://dbadmins.ru
16 repeats with URL: http://dbadmins.ru
20 repeats with URL: http://www.domaincrawler.com
21 repeats with URL: http://www.semrush.com
9 repeats with URL: http://www.google.com
Ошибки запросов с 14/Aug/2019:04:12:10 до 15/Aug/2019:00:25:46 -
коды возврата ошибок:
301
304
400
403
404
405
499
500
----------------------------------------------------
все коды возврата:
200
301
304
400
403
404
405
499
500
root@tep:/home/tep# 
root@tep:/home/tep# 



Конфиг крона:
*/6 * * * *  user  /usr/bin/flock -xn /var/lock/script.lock -c '/home/tep/parse.sh | mail -s "Parser error access.log" info-it@tsumvrn.ru -aFrom:info-it@tsumvrn.ru'



Проверка

Apr 23 11:22:24 tep postfix[843]: Postfix is running with backwards-compatible default settings
Apr 23 11:22:24 tep postfix[843]: See http://www.postfix.org/COMPATIBILITY_README.html for details
Apr 23 11:22:24 tep postfix[843]: To disable backwards compatibility use "postconf compatibility_level=2" and "postfix reload"
Apr 23 11:22:25 tep postfix/postfix-script[913]: warning: symlink leaves directory: /etc/postfix/./makedefs.out
Apr 23 11:22:25 tep postfix/postfix-script[955]: starting the Postfix mail system
Apr 23 11:22:25 tep postfix/master[957]: daemon started -- version 3.4.13, configuration /etc/postfix
Apr 23 12:08:10 tep postfix/pickup[958]: EDA54120547: uid=0 from=<info-it@tsumvrn.ru>
Apr 23 12:08:10 tep postfix/cleanup[1987]: EDA54120547: message-id=<20240423120810.EDA54120547@tep.localdomain>
Apr 23 12:08:10 tep postfix/qmgr[959]: EDA54120547: from=<info-it@tsumvrn.ru>, size=1513, nrcpt=1 (queue active)
Apr 23 12:08:12 tep postfix/smtp[1989]: EDA54120547: to=<info-it@tsumvrn.ru>, relay=mx.yandex.net[77.88.21.249]:25, delay=1.1,
 delays=0.02/0.01/0.41/0.69, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued on mail-nwsmtp-mxfront-production-main-72.iva.yp-c.yandex.net 1713874092-B8JqP27dPGk0-kmgLq16I)
Apr 23 12:08:12 tep postfix/qmgr[959]: EDA54120547: removed
root@tep:/home/tep# 
