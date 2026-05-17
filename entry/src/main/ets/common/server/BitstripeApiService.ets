import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import CommonConstants from '../constants/CommonConstants';
import { HuaweiAccountSession } from '../account/HuaweiAccountService';
import { AccountRecordInput } from '../rdbUtils/RdbUtils';

export interface BitstripeAuthResult {
  userId: string;
  huaweiSub: string;
  token: string;
  expiresAt: number;
}

export interface ServerAccountRecord {
  recordId: string;
  tag: string;
  tagId?: number;
  isUserTag?: boolean;
  type: string;
  amount: string;
  note: string;
  occurredAt: string;
  updatedAt: string;
  deviceId: string;
  version: number;
  isDeleted: boolean;
  serverUpdatedAt?: string;
}

interface HuaweiAuthPayload {
  authorizationCode: string;
}

interface ServerRecordPayload {
  recordId?: string;
  tag: string;
  tagId?: number;
  isUserTag?: boolean;
  type: string;
  amount: string;
  note: string;
  occurredAt?: string;
  updatedAt?: string;
  deviceId?: string;
  version: number;
  isDeleted: boolean;
}

interface BatchRecordsPayload {
  items: ReceiptRecognitionItem[];
}

interface AnalyzeStatisticsPayload {
  month: string;
}

interface EmptyPayload {}

export interface ReceiptRequestPayload {
  imageBase64: string;
  mimeType: string;
  fileName: string;
}

interface CreateRecordResult {
  record: ServerAccountRecord;
}

interface BatchRecordsResult {
  insertedCount: number;
  records: ServerAccountRecord[];
}

interface SyncRecordsResult {
  records: ServerAccountRecord[];
}

interface ApiEnvelope<T> {
  success: boolean;
  data?: T;
  error?: ApiError;
}

interface ApiError {
  code?: string;
  message?: string;
}

export interface ReceiptRecognitionResult {
  isReceipt?: boolean;
  text: string;
  amount?: string;
  tag?: string;
  confidence?: number;
  items?: ReceiptRecognitionItem[];
  provider?: string;
}

export interface ReceiptRecognitionItem {
  description: string;
  amount: string;
  type: string;
  category: string;
  date?: string;
  selected?: boolean;
}

export interface ServerProfile {
  userId: string;
  displayName: string;
  avatarUrl: string;
  inviteCode: string;
  isPremium: boolean;
}

export interface ServerProfilePayload {
  displayName?: string;
  avatarUrl?: string;
}

export interface ServerStatisticsOverview {
  income: string;
  cost: string;
  balance: string;
  recordCount: number;
}

export interface ServerStatisticsTag {
  tag: string;
  type: string;
  amount: string;
  count: number;
}

export interface ServerStatisticsResult {
  month: string;
  overview: ServerStatisticsOverview;
  byTag: ServerStatisticsTag[];
  daily: Array<Record<string, string>>;
  summary: Record<string, string>;
}

export interface ServerGoal {
  goalId: string;
  type: string;
  title: string;
  targetAmount: string;
  currentAmount: string;
  monthlyIncome: string;
  description: string;
  planText: string;
  dailySavings: string;
  dailyMaxExpense: string;
  timeToGoalDays: number;
  status: string;
}

export interface ServerGoalPayload {
  goalId?: string;
  type: string;
  title: string;
  targetAmount: string;
  currentAmount?: string;
  monthlyIncome: string;
  description?: string;
}

export interface ServerTag {
  id: number;
  name: string;
  icon: string;
  type: string;
  isDefault: boolean;
  sortOrder: number;
}

export interface ServerTagPayload {
  name: string;
  icon: string;
  type: string;
}

interface ProfileResult {
  profile: ServerProfile;
}

interface StatisticsResult {
  month: string;
  overview: ServerStatisticsOverview;
  byTag: ServerStatisticsTag[];
  daily: Array<Record<string, string>>;
  summary: Record<string, string>;
}

interface GoalsResult {
  goals: ServerGoal[];
}

interface GoalResult {
  goal: ServerGoal;
}

interface TagsResult {
  tags: ServerTag[];
}

interface TagResult {
  tag: ServerTag;
}

interface AnalyzeStatisticsResult {
  tips: string[];
  notEnoughData?: boolean;
}

export interface ServerGoalAnalysis {
  id: number;
  goalId: string;
  suggestions: string[];
  actionableSteps: string[];
  challenges: Array<Record<string, string>>;
  rawOutput: string;
  createdAt: string;
}

interface AnalyzeGoalResult {
  analysis: ServerGoalAnalysis;
}

interface GoalStreamDonePayload {
  analysis?: ServerGoalAnalysis;
}

interface GoalStreamDeltaPayload {
  delta?: string;
}

interface InviteRedeemPayload {
  code: string;
}

export interface ServerInviteCode {
  code: string;
  maxUses: number;
  usesCount: number;
  isActive: boolean;
  expiresAt: string;
}

interface InviteCodesResult {
  inviteCodes: ServerInviteCode[];
}

interface InviteCodeResult {
  inviteCode: ServerInviteCode;
}

interface InviteCodePayload {
  code?: string;
  maxUses: number;
}

export class BitstripeApiService {
  private static serverHost: string = CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;

  static setServerHost(host: string) {
    const normalized = BitstripeApiService.normalizeHost(host);
    BitstripeApiService.serverHost = normalized || CommonConstants.BITSTRIPE_KOUSOU_DEFAULT_HOST;
  }

  static getServerHost(): string {
    return BitstripeApiService.serverHost;
  }

  static async authHuawei(session: HuaweiAccountSession): Promise<BitstripeAuthResult> {
    const payload: HuaweiAuthPayload = {
      authorizationCode: session.authorizationCode
    };
    const envelope = await BitstripeApiService.post<BitstripeAuthResult>('/auth/huawei', payload);
    return envelope;
  }

  static async createRecord(token: string, record: AccountRecordInput): Promise<ServerAccountRecord> {
    const envelope = await BitstripeApiService.post<CreateRecordResult>(
      '/records',
      BitstripeApiService.toServerRecord(record),
      token
    );
    return envelope.record;
  }

  static async batchCreateRecords(token: string, items: ReceiptRecognitionItem[]): Promise<BatchRecordsResult> {
    const payload: BatchRecordsPayload = { items };
    return BitstripeApiService.post<BatchRecordsResult>('/records/batch', payload, token);
  }

  static async syncRecords(token: string, updatedAfter?: string): Promise<ServerAccountRecord[]> {
    const path = updatedAfter ? `/sync?updatedAfter=${encodeURIComponent(updatedAfter)}` : '/sync';
    const envelope = await BitstripeApiService.get<SyncRecordsResult>(path, token);
    return envelope.records;
  }

  static async recognizeReceipt(token: string, payload: ReceiptRequestPayload): Promise<ReceiptRecognitionResult> {
    return BitstripeApiService.post<ReceiptRecognitionResult>('/receipt/recognize', payload, token);
  }

  static async getProfile(token: string): Promise<ServerProfile> {
    const envelope = await BitstripeApiService.get<ProfileResult>('/profile', token);
    return envelope.profile;
  }

  static async updateProfile(token: string, payload: ServerProfilePayload): Promise<ServerProfile> {
    const envelope = await BitstripeApiService.put<ProfileResult>('/profile', payload, token);
    return envelope.profile;
  }

  static async getStatistics(token: string, month: string): Promise<ServerStatisticsResult> {
    return BitstripeApiService.get<StatisticsResult>(`/statistics?month=${encodeURIComponent(month)}`, token);
  }

  static async analyzeStatistics(token: string, month: string): Promise<AnalyzeStatisticsResult> {
    const payload: AnalyzeStatisticsPayload = { month };
    return BitstripeApiService.post<AnalyzeStatisticsResult>('/statistics/analyze', payload, token);
  }

  static async getGoals(token: string): Promise<ServerGoal[]> {
    const envelope = await BitstripeApiService.get<GoalsResult>('/goals', token);
    return envelope.goals;
  }

  static async saveGoal(token: string, payload: ServerGoalPayload): Promise<ServerGoal> {
    const envelope = await BitstripeApiService.post<GoalResult>('/goals', payload, token);
    return envelope.goal;
  }

  static async updateGoal(token: string, goalId: string, payload: ServerGoalPayload): Promise<ServerGoal> {
    const envelope = await BitstripeApiService.put<GoalResult>(`/goals/${encodeURIComponent(goalId)}`, payload, token);
    return envelope.goal;
  }

  static async deleteGoal(token: string, goalId: string): Promise<ServerGoal> {
    const envelope = await BitstripeApiService.delete<GoalResult>(`/goals/${encodeURIComponent(goalId)}`, token);
    return envelope.goal;
  }

  static async analyzeGoal(token: string, goalId: string): Promise<ServerGoalAnalysis> {
    const payload: EmptyPayload = {};
    const envelope = await BitstripeApiService.post<AnalyzeGoalResult>(`/goals/${encodeURIComponent(goalId)}/analyze`, payload, token);
    return envelope.analysis;
  }

  static async analyzeGoalStream(
    token: string,
    goalId: string,
    onDelta: (text: string) => void
  ): Promise<ServerGoalAnalysis> {
    const request = http.createHttp();
    const decoder = util.TextDecoder.create('utf-8');
    let buffer = '';
    let finalAnalysis: ServerGoalAnalysis | null = null;

    const parseEvent = (rawEvent: string) => {
      const lines = rawEvent.split('\n');
      let eventName = 'message';
      let data = '';
      lines.forEach((line: string) => {
        if (line.startsWith('event:')) {
          eventName = line.slice(6).trim();
        } else if (line.startsWith('data:')) {
          data += line.slice(5).trim();
        }
      });
      if (!data) {
        return;
      }
      try {
        if (eventName === 'done') {
          const payload = JSON.parse(data) as GoalStreamDonePayload;
          if (payload.analysis) {
            finalAnalysis = payload.analysis;
          }
          return;
        }
        const payload = JSON.parse(data) as GoalStreamDeltaPayload;
        if (payload.delta) {
          onDelta(payload.delta);
        }
      } catch (_) {
        if (eventName !== 'done') {
          onDelta(data);
        }
      }
    };

    const flushBuffer = (force: boolean) => {
      let index = buffer.indexOf('\n\n');
      while (index >= 0) {
        const eventText = buffer.slice(0, index).trim();
        buffer = buffer.slice(index + 2);
        if (eventText) {
          parseEvent(eventText);
        }
        index = buffer.indexOf('\n\n');
      }
      if (force && buffer.trim()) {
        parseEvent(buffer.trim());
        buffer = '';
      }
    };

    request.on('dataReceive', (data: ArrayBuffer) => {
      const chunk = decoder.decodeToString(new Uint8Array(data));
      buffer += chunk;
      flushBuffer(false);
    });

    try {
      const responseCode = await request.requestInStream(
        `${BitstripeApiService.getBaseUrl()}/goals/${encodeURIComponent(goalId)}/analyze/stream`,
        {
          method: http.RequestMethod.POST,
          header: {
            'content-type': 'application/json',
            'accept': 'text/event-stream',
            Authorization: `Bearer ${token}`
          },
          extraData: JSON.stringify({}),
          connectTimeout: 10000,
          readTimeout: 120000
        }
      );
      flushBuffer(true);
      if (responseCode < 200 || responseCode >= 300 || !finalAnalysis) {
        throw new Error(`stream request failed: ${responseCode}`);
      }
      return finalAnalysis;
    } finally {
      request.off('dataReceive');
      request.destroy();
    }
  }

  static async getTags(token: string): Promise<ServerTag[]> {
    const envelope = await BitstripeApiService.get<TagsResult>('/tags', token);
    return envelope.tags;
  }

  static async createTag(token: string, payload: ServerTagPayload): Promise<ServerTag> {
    const envelope = await BitstripeApiService.post<TagResult>('/tags', payload, token);
    return envelope.tag;
  }

  static async updateTag(token: string, tagId: number, payload: ServerTagPayload): Promise<ServerTag> {
    const envelope = await BitstripeApiService.put<TagResult>(`/tags/${tagId}`, payload, token);
    return envelope.tag;
  }

  static async deleteTag(token: string, tagId: number): Promise<ServerTag> {
    const envelope = await BitstripeApiService.delete<TagResult>(`/tags/${tagId}`, token);
    return envelope.tag;
  }

  static async redeemInvite(token: string, code: string): Promise<ServerProfile> {
    const payload: InviteRedeemPayload = { code };
    const envelope = await BitstripeApiService.post<ProfileResult>('/invite/redeem', payload, token);
    return envelope.profile;
  }

  static async getInviteCodes(token: string): Promise<ServerInviteCode[]> {
    const envelope = await BitstripeApiService.get<InviteCodesResult>('/invite/codes', token);
    return envelope.inviteCodes;
  }

  static async createInviteCode(token: string, payload: InviteCodePayload): Promise<ServerInviteCode> {
    const envelope = await BitstripeApiService.post<InviteCodeResult>('/invite/codes', payload, token);
    return envelope.inviteCode;
  }

  private static toServerRecord(record: AccountRecordInput): ServerRecordPayload {
    const payload: ServerRecordPayload = {
      recordId: record.RECORD_ID,
      tag: record.TAG,
      tagId: record.TAG_ID ?? 0,
      isUserTag: record.IS_USER_TAG === 1,
      type: record.TYPE,
      amount: record.AMOUNT,
      note: record.NOTE ?? '',
      occurredAt: record.CREATE_AT ?? record.UPDATED_AT,
      updatedAt: record.UPDATED_AT,
      deviceId: record.DEVICE_ID,
      version: record.VERSION ?? 1,
      isDeleted: record.IS_DELETED === 1
    };
    return payload;
  }

  private static async get<T>(path: string, token?: string): Promise<T> {
    return BitstripeApiService.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  private static async post<T>(path: string, payload: object, token?: string): Promise<T> {
    return BitstripeApiService.request<T>(path, http.RequestMethod.POST, payload, token);
  }

  private static async put<T>(path: string, payload: object, token?: string): Promise<T> {
    return BitstripeApiService.request<T>(path, http.RequestMethod.PUT, payload, token);
  }

  private static async delete<T>(path: string, token?: string): Promise<T> {
    return BitstripeApiService.request<T>(path, http.RequestMethod.DELETE, undefined, token);
  }

  private static async request<T>(path: string, method: http.RequestMethod, payload?: object, token?: string): Promise<T> {
    const request = http.createHttp();
    const header: Record<string, string> = {
      'content-type': 'application/json'
    };
    if (token) {
      header.Authorization = `Bearer ${token}`;
    }
    try {
      const response = await request.request(`${BitstripeApiService.getBaseUrl()}${path}`, {
        method,
        header,
        extraData: payload ? JSON.stringify(payload) : undefined,
        connectTimeout: 10000,
        readTimeout: 30000
      });
      const rawResult = response.result as string;
      const envelope = JSON.parse(rawResult) as ApiEnvelope<T>;
      if (response.responseCode < 200 || response.responseCode >= 300 || !envelope.success || !envelope.data) {
        throw new Error(envelope.error?.message ?? `bitstripe request failed: ${response.responseCode}`);
      }
      return envelope.data;
    } finally {
      request.destroy();
    }
  }

  private static getBaseUrl(): string {
    return `${BitstripeApiService.serverHost}${CommonConstants.BITSTRIPE_KOUSOU_API_BASE_PATH}`;
  }

  private static normalizeHost(host: string): string {
    const trimmed = (host || '').trim();
    if (!trimmed) {
      return '';
    }
    const withoutPath = trimmed.replace(/\/v1\/kousou\/?$/, '').replace(/\/$/, '');
    return withoutPath;
  }
}
