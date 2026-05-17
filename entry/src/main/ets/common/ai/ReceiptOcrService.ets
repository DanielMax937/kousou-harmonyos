import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { util } from '@kit.ArkTS';
import { BitstripeApiService, ReceiptRecognitionItem, ReceiptRequestPayload } from '../server/BitstripeApiService';

export interface ReceiptOcrResult {
  imageUri: string;
  text: string;
  amount: string;
  tag: string;
  items: ReceiptRecognitionItem[];
}

interface ReceiptOcrRecognition {
  text: string;
  amount?: string;
  tag?: string;
  items?: ReceiptRecognitionItem[];
}

export class ReceiptOcrService {
  static async recognizeFromPicker(token: string): Promise<ReceiptOcrResult | null> {
    const uri = await ReceiptOcrService.pickImage();
    if (!uri) {
      return null;
    }
    const result = await ReceiptOcrService.recognizeImage(token, uri);
    return {
      imageUri: uri,
      text: result.text,
      amount: result.amount ?? '',
      tag: result.tag ?? '',
      items: result.items ?? []
    };
  }

  private static async pickImage(): Promise<string> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    const result = await picker.select(options);
    if (!result.photoUris || result.photoUris.length === 0) {
      return '';
    }
    return result.photoUris[0];
  }

  private static async recognizeImage(token: string, uri: string): Promise<ReceiptOcrRecognition> {
    const imageBase64 = await ReceiptOcrService.readImageBase64(uri);
    const payload: ReceiptRequestPayload = {
      imageBase64,
      mimeType: ReceiptOcrService.resolveMimeType(uri),
      fileName: ReceiptOcrService.resolveFileName(uri)
    };
    const response = await BitstripeApiService.recognizeReceipt(token, payload);
    if (!response.text && (!response.items || response.items.length === 0)) {
      throw new Error('LLM receipt recognition returned empty text');
    }
    const result: ReceiptOcrRecognition = {
      text: response.text,
      amount: response.amount,
      tag: response.tag,
      items: response.items
    };
    return result;
  }

  private static async readImageBase64(uri: string): Promise<string> {
    let sourceFile: fileIo.File | null = null;
    try {
      sourceFile = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(sourceFile.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(sourceFile.fd, buffer);
      const bytes = new Uint8Array(buffer);
      return new util.Base64Helper().encodeToStringSync(bytes);
    } finally {
      if (sourceFile) {
        await fileIo.close(sourceFile).catch(() => {});
      }
    }
  }

  private static resolveMimeType(uri: string): string {
    const lowerUri = uri.toLowerCase();
    if (lowerUri.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerUri.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  private static resolveFileName(uri: string): string {
    const segments = uri.split('/');
    return segments[segments.length - 1] || 'receipt.jpg';
  }
}
