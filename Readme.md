# Галерея BQ

Этот проект создан для формирования Галери BQ, состоящий из снимков, сделанных на смартфоны BQ. Фотографии берутся их ["Клуба поклонников/хэйтеров BQ"](http://4pda.ru/forum/index.php?showtopic=758535) на 4PDA и публикуются на канале ["Галеря BQ"](https://t.me/bqgallery) в Telegram. 

## Использование

Проект построен на платформозависимых решениях и разработан для ОС Linux.

### Зависимости

* Установить ["зависимости Nokogiri"](http://www.nokogiri.org/tutorials/installing_nokogiri.html)
* Установить ["зависимости Exif"](https://github.com/tonytonyjan/exif#installation)
* Установить зависимости sqlite3: `apt install sqlite3 libsqlite3-dev`

### Установка

```
bundle
```

## Тесты

```
rspec
```

## Настройка

### Файл конфигурации

Пример файла конфигурации (`assets/config.yml`):

```yaml
---
# номер ветки на 4PDA
:topic: 758535
# страница, с которой начинать чтение ветки
:page: 620
# имя файла БД в директории assets
:db: gallery.db
# имя файла с сессией 4PDA
:cookies: 4pda.cookies
# токен Telegram API
:telegram_token: 123456789:Ajl0
# идентификатор чата Telegram
:chat_id: -0101234567890
# токен Google API
:google_api: kO80J6jH_sk098dIu8
```

### Структура БД

```sql
CREATE TABLE images (
link TEXT,
post TEXT,
user TEXT,
model TEXT,
mid INTEGER,
fid TEXT,
rating INTEGER
);

CREATE table tlg_users (
id INTEGER
);

CREATE table likes (
mid INTEGER,
uid INTEGER
);
```
* post - сокращенная goo.gl ссылкна на пост 4PDA с изобрадением
* user - имя пользователя 4PDA
* mid - идентификатор сообщения Telegram
* fid - идентификатор файла Telegram
* uid - идентификатор пользователя Telegram

### Файл сессии 4PDA

Содержимое файла сессии может быть получено, например, с помощью расширения ["cookie-txt-export"](https://code.google.com/archive/p/cookie-txt-export/) для браузера Chromium.

## Использование

### poster.rb

0. Запускается по расписанию, например, через cron: `*/3 * * * * /usr/bin/flock -n /tmp/postercron.lck /home/user/path/to/bin/poster.rb`
1. Парсит страницы выбранной ветки на 4PDA
2. Находит все прикрепленные изображения с расширением jpg
3. Проверяет, что найденные изображения ещё не были отправлены в Telegram
4. Скачивает изображения в директорию `tmp`
5. Проверяет, что их размер не превышает 10 МБ, а в exif указан производитель камеры - BQ
6. Отправляет удовлетворяющие критериям изображения в Telegram
7. Удаляет временные файлы из директории `tmp`

### listener.rb

0. Запускается, например, с помощью monit:
```
check process listener.rb
matching "listener.rb"
start program = "/bin/bash -c 'export PATH=/home/user/.rvm/gems/ruby-2.3.0/bin:/home/user/.rvm/gems/ruby-2.3.0@global/bin:/home/user/.rvm/rubies/ruby-2.3.0/bin:/home/user/.rvm/gems/ruby-2.3.0/bin:/home/user/.rvm/gems/ruby-2.3.0@global/bin:/home/user/.rvm/rubies/ruby-2.3.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games:/home/user/.rvm/bin:/home/user/.rvm/bin; export GEM_HOME=/home/user/.rvm/gems/ruby-2.3.0; export GEM_PATH=/home/user/.rvm/gems/ruby-2.3.0:/home/user/.rvm/gems/ruby-2.3.0@global; export MY_RUBY_HOME=/home/user/.rvm/rubies/ruby-2.3.0; export IRBRC=/home/user/.rvm/rubies/ruby-2.3.0/.irbrc; /home/user/path/to/bin/listener.rb'" 
	as uid userid and gid groupid
stop program = "/bin/bash -c  'killall listener.rb'"
```
1. Слушает сообщения из Telegram
2. Учитывает результаты голосования в БД
3. Отправляет уведомления проголосовавшим пользователям
