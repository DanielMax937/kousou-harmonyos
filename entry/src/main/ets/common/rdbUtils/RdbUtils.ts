import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export interface AccountRecordInput {
  RECORD_ID?: string;
  TAG: string;
  TAG_ID?: number;
  IS_USER_TAG?: number;
  TYPE: string;
  AMOUNT: string;
  USER_ID: string;
  NOTE?: string;
  SYNC_STATUS?: string;
  CREATE_AT?: string;
  UPDATED_AT?: string;
  DEVICE_ID?: string;
  IS_DELETED?: number;
  VERSION?: number;
}

export interface StoredKousouAuth {
  userId: string;
  token: string;
  expiresAt: number;
  accountLabel: string;
  lastSyncAt: string;
}

interface Tag {
  amount: string
  tag: string,
  type: string,
  createAt: string,
  userId: string,
  syncStatus: string,
}

export class MyTag {
  amount: string;
  tag: string;
  type: string;
  createAt: string;
  userId: string;
  syncStatus: string;

  constructor(tag: string, type: string, amount: string, createAt: string, userId: string, syncStatus: string) {
    this.amount =  amount;
    this.tag = tag;
    this.type = type;
    this.createAt = createAt;
    this.userId = userId;
    this.syncStatus = syncStatus;
  }

  toString() {
    return this.amount + this.tag + this.type + this.createAt
  }
}

export default class RdbUtils {
  static readonly ACCOUNT_TABLE: string = 'ACCOUNT_RECORD';
  private static readonly PREFERENCES_FILE_NAME: string = 'myStore';
  private static readonly PREFERENCES_KEY_DEVICE_ID: string = 'DeviceId';
  private static readonly PREFERENCES_KEY_KOUSOU_USER_ID: string = 'KousouUserId';
  private static readonly PREFERENCES_KEY_KOUSOU_TOKEN: string = 'KousouToken';
  private static readonly PREFERENCES_KEY_KOUSOU_TOKEN_EXPIRES_AT: string = 'KousouTokenExpiresAt';
  private static readonly PREFERENCES_KEY_KOUSOU_ACCOUNT_LABEL: string = 'KousouAccountLabel';
  private static readonly PREFERENCES_KEY_KOUSOU_LAST_SYNC_AT: string = 'KousouLastSyncAt';
  private static readonly PREFERENCES_KEY_KOUSOU_SERVER_HOST: string = 'KousouServerHost';
  static DEVICE_ID: string = RdbUtils.createDeviceId();
  private static rdbStore: relationalStore.RdbStore;
  private static readyPromise: Promise<void> = Promise.resolve();

  static setStore(store: relationalStore.RdbStore) {
    RdbUtils.rdbStore = store;
  }

  static getStore(): relationalStore.RdbStore {
    return RdbUtils.rdbStore;
  }

  static setReady(promise: Promise<void>) {
    RdbUtils.readyPromise = promise;
  }

  static waitReady(): Promise<void> {
    return RdbUtils.readyPromise;
  }

  static async initDeviceId(context: common.Context): Promise<void> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    const value = await store.get(RdbUtils.PREFERENCES_KEY_DEVICE_ID, '');
    if (typeof value === 'string' && value.length > 0) {
      RdbUtils.DEVICE_ID = value;
      return;
    }

    const deviceId = RdbUtils.createDeviceId();
    await store.put(RdbUtils.PREFERENCES_KEY_DEVICE_ID, deviceId);
    await store.flush();
    RdbUtils.DEVICE_ID = deviceId;
  }

  static async saveKousouAuth(context: common.Context, auth: StoredKousouAuth): Promise<void> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_USER_ID, auth.userId);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN, auth.token);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN_EXPIRES_AT, auth.expiresAt);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_ACCOUNT_LABEL, auth.accountLabel);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_LAST_SYNC_AT, auth.lastSyncAt);
    await store.flush();
  }

  static async loadKousouAuth(context: common.Context): Promise<StoredKousouAuth | null> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    const userId = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_USER_ID, '');
    const token = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN, '');
    const expiresAt = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN_EXPIRES_AT, 0);
    const accountLabel = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_ACCOUNT_LABEL, '');
    const lastSyncAt = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_LAST_SYNC_AT, '');
    if (typeof userId !== 'string' || typeof token !== 'string' || !userId || !token) {
      return null;
    }
    const expiresAtNumber = typeof expiresAt === 'number' ? expiresAt : Number(expiresAt);
    if (!expiresAtNumber || expiresAtNumber <= Date.now()) {
      return null;
    }
    return {
      userId,
      token,
      expiresAt: expiresAtNumber,
      accountLabel: typeof accountLabel === 'string' && accountLabel ? accountLabel : `已登录 ${userId}`,
      lastSyncAt: typeof lastSyncAt === 'string' ? lastSyncAt : ''
    };
  }

  static async clearKousouAuth(context: common.Context): Promise<void> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    await store.delete(RdbUtils.PREFERENCES_KEY_KOUSOU_USER_ID);
    await store.delete(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN);
    await store.delete(RdbUtils.PREFERENCES_KEY_KOUSOU_TOKEN_EXPIRES_AT);
    await store.delete(RdbUtils.PREFERENCES_KEY_KOUSOU_ACCOUNT_LABEL);
    await store.flush();
  }

  static async getKousouLastSyncAt(context: common.Context): Promise<string> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    const lastSyncAt = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_LAST_SYNC_AT, '');
    return typeof lastSyncAt === 'string' ? lastSyncAt : '';
  }

  static async saveKousouLastSyncAt(context: common.Context, lastSyncAt: string): Promise<void> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_LAST_SYNC_AT, lastSyncAt);
    await store.flush();
  }

  static async loadKousouServerHost(context: common.Context, defaultHost: string): Promise<string> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    const host = await store.get(RdbUtils.PREFERENCES_KEY_KOUSOU_SERVER_HOST, defaultHost);
    return typeof host === 'string' && host.length > 0 ? host : defaultHost;
  }

  static async saveKousouServerHost(context: common.Context, host: string): Promise<void> {
    const store = await preferences.getPreferences(context, RdbUtils.PREFERENCES_FILE_NAME);
    await store.put(RdbUtils.PREFERENCES_KEY_KOUSOU_SERVER_HOST, host);
    await store.flush();
  }

  static executeSql(sql: string): Promise<void> {
    return RdbUtils.getStore().executeSql(sql);
  }

  static insert(tableName: string, data:any): Promise<number> {
    return RdbUtils.getStore().insert(tableName, data);
  }

  static insertAccount(data: AccountRecordInput): Promise<number> {
    const now = RdbUtils.createTimestamp();
    return RdbUtils.waitReady().then(() => RdbUtils.getStore().insert(RdbUtils.ACCOUNT_TABLE, {
      RECORD_ID: data.RECORD_ID ?? RdbUtils.createRecordId(),
      TAG: data.TAG,
      TAG_ID: data.TAG_ID ?? 0,
      IS_USER_TAG: data.IS_USER_TAG ?? 0,
      TYPE: data.TYPE,
      AMOUNT: data.AMOUNT,
      CREATE_AT: data.CREATE_AT ?? now,
      USER_ID: data.USER_ID,
      NOTE: data.NOTE ?? '',
      SYNC_STATUS: data.SYNC_STATUS ?? 'LOCAL',
      UPDATED_AT: data.UPDATED_AT ?? now,
      DEVICE_ID: data.DEVICE_ID ?? RdbUtils.DEVICE_ID,
      IS_DELETED: data.IS_DELETED ?? 0,
      VERSION: data.VERSION ?? 1
    }));
  }

  static markSyncStatus(id: number, status: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('ROWID', id);
    return RdbUtils.getStore().update({
      SYNC_STATUS: status
    }, predicates);
  }

  static markPendingRecordsSynced(): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('SYNC_STATUS', 'PENDING');
    return RdbUtils.getStore().update({
      SYNC_STATUS: 'SYNCED'
    }, predicates);
  }

  static migrateLocalRecordsToUser(userId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('USER_ID', 'local');
    predicates.notEqualTo('IS_DELETED', 1);
    return RdbUtils.getStore().update({
      USER_ID: userId,
      SYNC_STATUS: 'PENDING',
      UPDATED_AT: RdbUtils.createTimestamp(),
      DEVICE_ID: RdbUtils.DEVICE_ID,
      VERSION: 2
    }, predicates);
  }

  static hasPendingRecords(): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('SYNC_STATUS', 'PENDING');
    return new Promise<boolean>((resolve, reject) => {
      RdbUtils.getStore().query(predicates, ['RECORD_ID']).then((result) => {
        const hasPending = result.goToNextRow();
        try {
          result.close();
        } catch (error) {
          console.warn(`[RdbInfo] close pending result failed: ${JSON.stringify(error)}`);
        }
        resolve(hasPending);
      }).catch((error) => {
        reject(error);
      });
    });
  }

  static queryPendingRecords(userId: string): Promise<Array<AccountRecordInput>> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('USER_ID', userId);
    predicates.equalTo('SYNC_STATUS', 'PENDING');
    return RdbUtils.queryRecords(predicates);
  }

  static markRecordSynced(recordId: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('RECORD_ID', recordId);
    return RdbUtils.getStore().update({
      SYNC_STATUS: 'SYNCED'
    }, predicates);
  }

  static upsertServerRecord(record: AccountRecordInput): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(RdbUtils.ACCOUNT_TABLE);
    predicates.equalTo('RECORD_ID', record.RECORD_ID ?? '');
    return RdbUtils.queryRecords(predicates).then((items) => {
      if (items.length === 0) {
        return RdbUtils.insertAccount(record).then(() => {});
      }
      const existing = items[0];
      if ((existing.UPDATED_AT ?? '') > (record.UPDATED_AT ?? '')) {
        return;
      }
      return RdbUtils.getStore().update({
        TAG: record.TAG,
        TAG_ID: record.TAG_ID ?? 0,
        IS_USER_TAG: record.IS_USER_TAG ?? 0,
        TYPE: record.TYPE,
        AMOUNT: record.AMOUNT,
        USER_ID: record.USER_ID,
        NOTE: record.NOTE ?? '',
        SYNC_STATUS: 'SYNCED',
        UPDATED_AT: record.UPDATED_AT,
        DEVICE_ID: record.DEVICE_ID,
        IS_DELETED: record.IS_DELETED ?? 0,
        VERSION: record.VERSION ?? 1
      }, predicates).then(() => {});
    });
  }

  static newRecordId(): string {
    return RdbUtils.createRecordId();
  }

  static nowIsoString(): string {
    return RdbUtils.createTimestamp();
  }

  static queryAll(tableName: string, userId: string = ''): Promise<Array<MyTag>> {
    let predicates = new relationalStore.RdbPredicates(tableName === 'ACCOUNT' ? RdbUtils.ACCOUNT_TABLE : tableName);
    if (userId) {
      predicates.equalTo('USER_ID', userId);
    }
    predicates.notEqualTo('IS_DELETED', 1);
    return RdbUtils.waitReady().then(() => new Promise<Array<MyTag>>((resolve, reject) => {
      RdbUtils.getStore().query(predicates).then((result)=> {
        let recordList: MyTag[]= new Array<MyTag>();
        while (result.goToNextRow()) {
          const tagValue = result.getValue(result.getColumnIndex('TAG')) as string;
          const typeValue = result.getValue(result.getColumnIndex('TYPE')) as string;
          const amountValue = result.getValue(result.getColumnIndex('AMOUNT')) as string;
          const utcDateString = result.getValue(result.getColumnIndex('CREATE_AT')) as string;
          const utcDate = new Date(utcDateString.includes('T') ? utcDateString : `${utcDateString.replace(' ', 'T')}Z`);
          const beijingTime = new Date(utcDate.getTime() + 8 * 60 * 60 * 1000);
          const beijingTimeStr = RdbUtils.formatDisplayTime(beijingTime);
          const userValue = result.getColumnIndex('USER_ID') >= 0 ? result.getValue(result.getColumnIndex('USER_ID')) as string : '';
          const syncValue = result.getColumnIndex('SYNC_STATUS') >= 0 ? result.getValue(result.getColumnIndex('SYNC_STATUS')) as string : 'LOCAL';
          recordList.push(new MyTag(tagValue, typeValue, amountValue, beijingTimeStr, userValue, syncValue))
        }
        try {
          result.close();
        } catch (error) {
          console.warn(`[RdbInfo] close query result failed: ${JSON.stringify(error)}`);
        }
        resolve(recordList)
      }).catch((error)=> {
        reject(error)
      })
    }))
  }

  private static queryRecords(predicates: relationalStore.RdbPredicates): Promise<Array<AccountRecordInput>> {
    return RdbUtils.waitReady().then(() => new Promise<Array<AccountRecordInput>>((resolve, reject) => {
      RdbUtils.getStore().query(predicates).then((result) => {
        const records: AccountRecordInput[] = [];
        while (result.goToNextRow()) {
          records.push({
            RECORD_ID: result.getValue(result.getColumnIndex('RECORD_ID')) as string,
            TAG: result.getValue(result.getColumnIndex('TAG')) as string,
            TAG_ID: result.getColumnIndex('TAG_ID') >= 0 ? Number(result.getValue(result.getColumnIndex('TAG_ID'))) : 0,
            IS_USER_TAG: result.getColumnIndex('IS_USER_TAG') >= 0 ? Number(result.getValue(result.getColumnIndex('IS_USER_TAG'))) : 0,
            TYPE: result.getValue(result.getColumnIndex('TYPE')) as string,
            AMOUNT: result.getValue(result.getColumnIndex('AMOUNT')) as string,
            USER_ID: result.getValue(result.getColumnIndex('USER_ID')) as string,
            NOTE: result.getValue(result.getColumnIndex('NOTE')) as string,
            SYNC_STATUS: result.getValue(result.getColumnIndex('SYNC_STATUS')) as string,
            CREATE_AT: result.getValue(result.getColumnIndex('CREATE_AT')) as string,
            UPDATED_AT: result.getValue(result.getColumnIndex('UPDATED_AT')) as string,
            DEVICE_ID: result.getValue(result.getColumnIndex('DEVICE_ID')) as string,
            IS_DELETED: Number(result.getValue(result.getColumnIndex('IS_DELETED'))),
            VERSION: Number(result.getValue(result.getColumnIndex('VERSION')))
          });
        }
        try {
          result.close();
        } catch (error) {
          console.warn(`[RdbInfo] close records result failed: ${JSON.stringify(error)}`);
        }
        resolve(records);
      }).catch((error) => {
        reject(error);
      });
    }));
  }

  private static createRecordId(): string {
    return `record_${Date.now()}_${Math.floor(Math.random() * 1000000)}`;
  }

  private static createTimestamp(): string {
    return new Date().toISOString();
  }

  private static formatDisplayTime(date: Date): string {
    const pad = (value: number) => value < 10 ? `0${value}` : value.toString();
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  private static createDeviceId(): string {
    return `device_${Date.now()}_${Math.floor(Math.random() * 1000000)}`;
  }
}
