/**
 * 방 참여 코드 생성 유틸리티
 * --------------------------
 * 구성: 숫자(0-9) + 영어 대문자(A-Z)
 * 길이: 5자리 (예: "7A9Z2", "B1C3D")
 */
export function generateRoomCode(): string {
  // 1. 사용할 문자셋 정의 (숫자 + 대문자)
  const characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const length = 5;
  let result = '';

  // 2. 랜덤하게 5글자 뽑기
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * characters.length);
    result += characters.charAt(randomIndex);
  }

  return result;
}