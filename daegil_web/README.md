# daegil_web

대길의 독립 웹 체험판입니다. `daegil_app`과 별도 Next.js 패키지로 빌드하며, Supabase 인증/RPC/Edge Function을 공통 백엔드로 사용합니다.

## Local

```text
npm install
npm run typecheck
npm run build
```

환경변수는 `.env.example`을 참고합니다. Supabase 값이 없으면 개발용 데모 흐름으로 동작하고, 운영 배포에서는 Supabase publishable key와 웹 Rewarded 광고 단위를 반드시 설정해야 합니다.
