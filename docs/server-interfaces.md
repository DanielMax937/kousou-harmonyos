# 服务端接口清单

当前 App 的自有服务端由 bitstripe 的 `kousou` Django app 提供。华为账号只用于登录换取服务端 token；账单同步和图片票据识别都走 bitstripe 服务端接口。

## 1. 华为账号登录换 token

- Method: `POST`
- Path: `/v1/kousou/auth/huawei`
- 目的: App 使用华为 Account Kit 获取 `authorizationCode` 后，交给服务端调用华为 OAuth token 接口校验，并签发 bitstripe app token。

### Request

```json
{
  "authorizationCode": "code from Huawei Account Kit"
}
```

### Response 200

```json
{
  "success": true,
  "data": {
    "userId": "1",
    "huaweiSub": "huawei subject",
    "token": "bitstripe-signed-token",
    "expiresAt": 1781490000000
  }
}
```

后续接口统一使用：

```http
Authorization: Bearer <token>
```

## 2. 账单列表/新增

- Method: `POST`
- Path: `/v1/kousou/records`
- 目的: 新增或幂等更新一条账单。
- Content-Type: `application/json`

### Request

```json
{
  "recordId": "record_...",
  "tag": "餐饮",
  "type": "cost",
  "amount": "35.00",
  "note": "午餐",
  "occurredAt": "2026-05-16T03:00:00Z",
  "updatedAt": "2026-05-16T03:00:01Z",
  "deviceId": "device_...",
  "version": 1,
  "isDeleted": false
}
```

## 3. 账单详情

- Method: `GET | PUT | DELETE`
- Path: `/v1/kousou/records/<record_id>`
- 目的: 查询、更新或软删除单条账单。

## 4. 服务端同步拉取

- Method: `GET`
- Path: `/v1/kousou/sync?updatedAfter=<iso datetime>`
- 目的: 拉取当前账号服务端账单变更。`updatedAfter` 可选。

## 5. 票据图片 LLM 识别

- Method: `POST`
- Path: `/v1/kousou/receipt/recognize`
- 目的: App 选择小票/发票图片后，将图片交给 bitstripe 服务端 LLM 识别，返回可继续端侧解析的文本。
- Content-Type: `application/json`

### Request

```json
{
  "imageBase64": "base64 encoded image bytes",
  "mimeType": "image/jpeg",
  "fileName": "receipt.jpg"
}
```

### Response 200

```json
{
  "success": true,
  "data": {
    "text": "午餐 合计 35.00",
    "amount": "35.00",
    "tag": "餐饮",
    "confidence": 0.92,
    "provider": "llm"
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "INVALID_IMAGE",
    "message": "imageBase64 is required"
  }
}
```

## 服务端同步与多设备冲突策略

账目数据使用 bitstripe `KousouAccountRecord` 作为服务端真源。端侧 RDB 表 `ACCOUNT_RECORD` 只承担本地缓存和离线 pending 队列，不再使用 HarmonyOS `DISTRIBUTED_CLOUD`。

### 同步时机

- 登录成功后：先把 `USER_ID = local` 的本地记录迁移到服务端用户 ID，再上传 pending 记录并拉取服务端记录。
- App 回到前台后：已登录时上传 pending 记录并拉取服务端记录。
- 新增账单后：本地先写入 `ACCOUNT_RECORD`，已登录时标记为 `PENDING` 并立即提交到 `/records`；未登录时保留为 `LOCAL`，等登录后迁移并同步。
- 同步失败时：保留 `PENDING` 状态，下次登录、前台恢复或保存账单时继续重试。

### 冲突解决

- 每条账单使用全局唯一 `RECORD_ID` 作为主键，不同设备新增不同账单时直接合并。
- 同一条账单在多设备修改时，服务端比较 `updatedAt`，较新的修改覆盖较旧的修改；时间相同时使用 `version` 兜底。
- 端侧同时保存 `UPDATED_AT`、`DEVICE_ID`、`VERSION`、`IS_DELETED`，用于后续做可解释的冲突诊断和软删除扩展。
- `DEVICE_ID` 写入偏好存储并长期复用，避免 App 重启后设备身份变化导致冲突诊断不稳定。
