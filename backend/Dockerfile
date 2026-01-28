# 1. Node.js 설치된 리눅스 준비 (가벼운 버전)
FROM node:18-alpine

# 2. 작업 폴더 생성
WORKDIR /app

# 3. 패키지 파일들 먼저 복사 (캐싱 효과)
COPY package*.json ./

# 4. 라이브러리 설치
RUN npm install

# 5. 나머지 모든 소스 코드 복사
COPY . .

RUN npx prisma generate

# 6. (선택) TypeScript 빌드 (NestJS 등을 쓴다면 필수)
RUN npm run build

# 7. 서버 실행 (package.json에 적힌 시작 명령어)
CMD ["npm", "run", "start:prod"]