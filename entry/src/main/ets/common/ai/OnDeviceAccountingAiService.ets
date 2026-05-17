import { INIT_TAG, Tag } from '../../pages/components/Money';

export interface AccountingIntent {
  amount: string;
  tag: Tag;
}

interface TagKeyword {
  tag: string;
  words: string[];
}

const TAG_KEYWORDS: TagKeyword[] = [
  { tag: '餐饮', words: ['吃', '饭', '餐', '奶茶', '咖啡', '早餐', '午餐', '晚餐', '外卖'] },
  { tag: '公交车', words: ['地铁', '公交', '公交车'] },
  { tag: '出租车', words: ['打车', '出租车', '网约车'] },
  { tag: '火车', words: ['高铁', '火车'] },
  { tag: '飞机', words: ['机票', '飞机'] },
  { tag: '加油', words: ['加油', '停车'] },
  { tag: '购物', words: ['买', '购物', '淘宝', '京东', '拼多多', '衣服', '鞋'] },
  { tag: '水电', words: ['水费', '电费', '燃气', '物业'] },
  { tag: '房租', words: ['房租', '租金'] },
  { tag: '教育', words: ['书', '课程', '培训', '学习'] },
  { tag: '娱乐', words: ['电影', '游戏', '演出', '会员'] },
  { tag: '旅游', words: ['酒店', '旅行', '旅游', '门票'] },
  { tag: '工资', words: ['工资', '薪水', '薪资'] },
  { tag: '奖金', words: ['奖金', '奖励'] },
  { tag: '红包', words: ['红包'] },
  { tag: '报销', words: ['报销'] }
];

export class OnDeviceAccountingAiService {
  static parse(text: string): AccountingIntent | null {
    const amount = OnDeviceAccountingAiService.extractAmount(text);
    if (!amount) {
      return null;
    }
    const tag = OnDeviceAccountingAiService.matchTag(text);
    if (!tag) {
      return null;
    }
    return { amount, tag };
  }

  private static extractAmount(text: string): string {
    const normalizedText = text.replace(/[,，]/g, '');
    const keywordMatch = normalizedText.match(/(?:合计|总计|应收|实收|金额|付款|支付|消费|小计|价税合计)[^\d]{0,12}(\d+(?:\.\d{1,2})?)/);
    if (keywordMatch) {
      return keywordMatch[1];
    }
    const currencyMatch = normalizedText.match(/[¥￥]\s*(\d+(?:\.\d{1,2})?)/);
    if (currencyMatch) {
      return currencyMatch[1];
    }
    const match = normalizedText.match(/(\d+(?:\.\d{1,2})?)/);
    return match ? match[1] : '';
  }

  private static matchTag(text: string): Tag | null {
    for (let i = 0; i < TAG_KEYWORDS.length; i++) {
      const item = TAG_KEYWORDS[i];
      for (let j = 0; j < item.words.length; j++) {
        if (text.includes(item.words[j])) {
          return INIT_TAG.find((tag: Tag) => tag.name === item.tag) ?? null;
        }
      }
    }
    return INIT_TAG.find((tag: Tag) => tag.name === '日用品') ?? null;
  }
}
