# Спецификация доступа Hermes Bridge

## Короткая версия

Hermes Bridge пишет в этот GBrain через HTTP MCP.

- Endpoint: `https://<gbrain-host>/mcp`
- Токен доступа: `gbrain_xxx`
- Создание токена: `gbrain auth create "hermes-bridge"`
- Предпочтительный заголовок: `X-GBrain-API-Key: <token>`
- Альтернативный заголовок: `Authorization: Bearer <token>`

Минимальная проверка:

1. HTTP-сервер GBrain запущен.
2. Hermes передаёт токен в одном из поддерживаемых заголовков.
3. `tools/list` выполняется успешно.
4. Успешно выполняется MCP-вызов с правом записи.

## Блок `.env` для Hermes

```dotenv
# Доступ Hermes Bridge -> GBrain
HERMES_GBRAIN_MCP_URL=https://<gbrain-host>/mcp
HERMES_GBRAIN_TOKEN=gbrain_xxx

# Предпочтительный режим auth для service-to-service вызовов
HERMES_GBRAIN_AUTH_MODE=api_key
HERMES_GBRAIN_API_KEY_HEADER=X-GBrain-API-Key
```

Вариант с bearer-аутентификацией:

```dotenv
# Доступ Hermes Bridge -> GBrain
HERMES_GBRAIN_MCP_URL=https://<gbrain-host>/mcp
HERMES_GBRAIN_TOKEN=gbrain_xxx

# Если Hermes уже использует стандартную bearer-схему
HERMES_GBRAIN_AUTH_MODE=bearer
```

## Назначение

Этот документ определяет, как проект Hermes Bridge получает доступ на запись
в этот экземпляр GBrain через HTTP MCP.

## Модель аутентификации

Hermes Bridge аутентифицируется с помощью access token GBrain, созданного на
стороне хоста GBrain.

- Формат токена: `gbrain_xxx`
- Источник токена: `gbrain auth create "<client-name>"`
- Транспорт: HTTP-заголовок

Поддерживаемые заголовки запроса:

```http
Authorization: Bearer <token>
```

или

```http
X-GBrain-API-Key: <token>
```

Совместимый fallback-вариант:

```http
X-API-Key: <token>
```

`GBRAIN_API_KEY` не является стандартным именем секрета в этом проекте. Если
Hermes хранит токен в переменной окружения, используйте локальное имя вроде
`HERMES_GBRAIN_TOKEN` или `GBRAIN_REMOTE_TOKEN`.

## Выдача токена

Создайте токен на стороне GBrain:

```bash
gbrain auth create "hermes-bridge"
```

Команда выводит токен один раз. Сохраните его в секрет-хранилище Hermes. Не
коммитьте токен в репозиторий.

## Endpoint

Hermes Bridge пишет в HTTP MCP endpoint:

```text
https://<gbrain-host>/mcp
```

На стороне GBrain сервер должен быть запущен с включённым HTTP transport,
например:

```bash
gbrain serve --http --bind 0.0.0.0 --public-url https://<gbrain-host>
```

## Минимальные требования к запросу

Hermes Bridge должен отправлять:

- `POST /mcp`
- `Content-Type: application/json`
- один из поддерживаемых auth-заголовков
- корректный JSON-RPC MCP payload

Пример:

```http
POST /mcp HTTP/1.1
Host: <gbrain-host>
Content-Type: application/json
X-GBrain-API-Key: gbrain_xxx
Accept: application/json, text/event-stream
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/list"
}
```

## Права доступа

Для операций записи Hermes Bridge нужен токен, которому разрешены
write-операции MCP для этого экземпляра GBrain.

Практически это означает:

- read-only токены недостаточны для сценариев записи
- токен должен быть создан и управляться оператором этого GBrain
- жизненный цикл токена управляется через `gbrain auth create`,
  `gbrain auth list` и `gbrain auth revoke`

## Операционные правила

- Для service-to-service интеграции предпочитайте `X-GBrain-API-Key`.
- Используйте `Authorization: Bearer <token>`, если клиент уже построен на
  стандартной bearer-схеме.
- Ротируйте токены так: создайте новый токен, обновите секреты Hermes, затем
  отзовите старый токен.
- Считайте токен full-access секретом, если в конкретном деплое нет
  дополнительных ограничений.

## Типовые ошибки

Типовые ошибки аутентификации:

- `401 invalid_token`: токен отсутствует, некорректен, неизвестен или отозван
- `403` или scope-related ошибка: токен валиден, но не имеет нужных прав
- `429`: клиент попал под rate limit

## Чеклист проверки

1. HTTP MCP endpoint GBrain доступен по `/mcp`.
2. Токен создан на целевом хосте GBrain.
3. Hermes отправляет `X-GBrain-API-Key` или `Authorization: Bearer`.
4. `tools/list` выполняется успешно.
5. Успешно выполняется MCP-вызов с правом записи.
