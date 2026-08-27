const documents: Record<string, { title: string; sections: string[] }> = {
  terms: {
    title: '대길 서비스 이용약관 (개발 검증용)',
    sections: [
      '대길은 오늘의 운세를 오락·문화 목적으로 제공하는 모바일 서비스입니다.',
      '사용자는 만 14세 이상임을 확인하고 서비스 운영 정책을 준수해야 합니다.',
      '운세 결과는 의료·법률·재무 등 전문적인 판단을 대신하지 않습니다.',
    ],
  },
  privacy: {
    title: '대길 개인정보 처리 안내 (개발 검증용)',
    sections: [
      '출생일, 출생시간의 정확도, 출생 국가와 도시는 개인화된 운세 생성에 사용됩니다.',
      '인증 식별자와 동의 이력은 계정 및 법적 동의 상태를 관리하기 위해 저장됩니다.',
      '계정 삭제 시 관련 개인정보는 서비스 정책과 법적 보존 의무에 따라 삭제됩니다.',
    ],
  },
  ai: {
    title: '대길 AI 개인화 처리 동의 (개발 검증용)',
    sections: [
      '입력한 출생정보와 오늘 날짜는 운세 생성을 위해 서버의 AI 제공자에게 전달될 수 있습니다.',
      'AI 결과는 자동 생성되며 부정확하거나 기대와 다른 내용을 포함할 수 있습니다.',
      '동의를 철회하면 새로운 AI 운세 생성과 광고·패스 사용이 제한됩니다.',
    ],
  },
};

function escapeHtml(value: string) {
  return value.replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[character]!));
}

Deno.serve((request) => {
  if (request.method !== 'GET') return new Response('Method Not Allowed', { status: 405 });
  const key = new URL(request.url).searchParams.get('document') ?? '';
  const document = documents[key];
  if (!document) return new Response('Not Found', { status: 404 });
  const paragraphs = document.sections
    .map((section) => `<p>${escapeHtml(section)}</p>`)
    .join('');
  return new Response(
    `<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(document.title)}</title><style>body{max-width:720px;margin:0 auto;padding:32px 20px;background:#fff4de;color:#4a281d;font:16px/1.75 system-ui,sans-serif}main{background:#fffaf0;border:1px solid #d58a45;border-radius:20px;padding:24px}h1{font-size:24px;line-height:1.35}small{color:#755144}</style><main><h1>${escapeHtml(document.title)}</h1>${paragraphs}<small>출시 전 서비스 소유자 및 법률 검토가 필요한 문안입니다.</small></main></html>`,
    { headers: { 'Content-Type': 'text/html; charset=utf-8' } },
  );
});
