import { createServer } from 'node:http';

const PORT = Number(process.env.PORT || 8787);

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type'
  });
  response.end(JSON.stringify(body));
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.setEncoding('utf8');
    request.on('data', chunk => {
      body += chunk;
      if (body.length > 20 * 1024 * 1024) {
        reject(new Error('request body too large'));
      }
    });
    request.on('end', () => resolve(body));
    request.on('error', reject);
  });
}

function mockReceiptText(payload) {
  const fileName = typeof payload.fileName === 'string' ? payload.fileName : '';
  if (fileName.includes('salary') || fileName.includes('gongzi')) {
    return {
      text: '工资 8000.00',
      amount: '8000.00',
      tag: '工资',
      confidence: 0.91
    };
  }
  return {
    text: '午餐 合计 35.00',
    amount: '35.00',
    tag: '餐饮',
    confidence: 0.92
  };
}

const server = createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  if (request.method === 'GET' && request.url === '/health') {
    sendJson(response, 200, {
      ok: true,
      service: 'kousou-llm-mock'
    });
    return;
  }

  if (request.method === 'POST' && request.url === '/api/receipt/recognize') {
    try {
      const body = await readBody(request);
      const payload = JSON.parse(body || '{}');
      if (!payload.imageBase64 || typeof payload.imageBase64 !== 'string') {
        sendJson(response, 400, {
          error: {
            code: 'INVALID_IMAGE',
            message: 'imageBase64 is required'
          }
        });
        return;
      }
      sendJson(response, 200, {
        ...mockReceiptText(payload),
        provider: 'mock'
      });
    } catch (error) {
      sendJson(response, 400, {
        error: {
          code: 'BAD_REQUEST',
          message: error instanceof Error ? error.message : 'bad request'
        }
      });
    }
    return;
  }

  sendJson(response, 404, {
    error: {
      code: 'NOT_FOUND',
      message: 'not found'
    }
  });
});

server.listen(PORT, () => {
  console.log(`kousou receipt LLM mock listening on http://127.0.0.1:${PORT}`);
});

