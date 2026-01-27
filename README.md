# 🏃‍♂️ GyeongdoPlus

**도시 전체가 게임 맵이 되는 순간, 추격전이 시작됩니다.**

GyeongdoPlus는 **추억의 놀이 '경찰과 도둑'**을 모바일 기술로 재해석한
**하이퍼 로컬 실시간 위치 기반(GPS) 추격 서바이벌 플랫폼**입니다.

복잡한 컨트롤러 없이, **실제 두 다리로 뛰고 숨으며**
스마트폰 지도를 통해 상대방의 위치를 파악하고 전략적인 심리전을 펼칠 수 있습니다.

---

## 🏃 Core UX: Real-World Chase

**GyeongdoPlus의 핵심은 '현실감'입니다.**

* 🛰️ **초정밀 실시간 GPS 동기화** (0.5초 단위 위치 추적)
* 👮‍♂️ **역동적인 역할 분담** (쫓는 경찰 vs 도망치는 도둑)
* ⚡ **전략적 아이템 운용** (연막탄, 미끼, 투명화)
* 🏫 **즉시 매치메이킹** (4자리 코드 공유로 친구들과 바로 시작)

> **화면만 보지 마세요.
> 신발 끈을 묶고, 지금 바로 뛰세요.**

---

## ✨ Why GyeongdoPlus?

### 🔥 1. "앉아서 하는 게임"의 종말

* 키보드나 터치가 아닌, **실제 이동(Running)**이 곧 컨트롤러입니다.
* 운동과 e스포츠의 경계를 허무는 몰입형 피지컬 액티비티

### ⚡ 2. 압도적인 동기화 성능

* **Socket.io + Redis** 아키텍처로 레이턴시 최소화
* 내가 골목을 도는 순간, 추격자의 화면 지도에서도 즉시 반영

### 🧠 3. 피지컬을 넘어서는 심리전

* 단순히 빠르다고 이기는 게임이 아닙니다.
* 지형지물 활용, 은폐, 아이템을 통한 교란과 팀워크가 핵심

---

## 🏗️ System Architecture

* **Mobile App**: Flutter (Google Maps API)
  → Native Map Interaction & GPS Logic
* **Backend**: NestJS (Socket.io)
  → Real-time Event Gateway & REST API
* **Hot Storage**: Redis
  → Game State, Location Caching (In-Memory)
* **Cold Storage**: Supabase (PostgreSQL)
  → Persistent Data (User Stats, Match History)
* **Auth**: Kakao OAuth
  → Fast & Easy Social Login
* **Infra**: AWS EC2 Runtime Environment

![GyeongdoPlus System Architecture](../gyeongdo_architecture.png)

> **Figure.** Overall system architecture of GyeongdoPlus, optimizing real-time interaction with Redis & Socket.io while ensuring data integrity with Supabase.

---

## 🚀 Key Features

* 📍 **Live Tracking**: Google Maps 기반 실시간 위치 공유
* 🤝 **Easy Join**: 4자리 랜덤 코드를 통한 간편한 방 입장
* 🎒 **Item Interaction**:
    * **Decoy**: 가짜 마커 생성으로 혼란 유도
    * **EMP**: 주변 플레이어의 지도 UI 일시 마비
* 🚨 **Auto Arrest**: GPS 거리 계산(Haversine)을 통한 자동 체포 판정
* 📊 **Personal Analytics**: MMR, 총 이동 거리, MVP 기록 등

---

## 🎯 Vision

GyeongdoPlus는
"가상 공간에 갇힌 게임"이 아니라,
"친구들과 함께 땀 흘리며 웃을 수 있는 **새로운 놀이 문화**"의 표준을 목표로 합니다.

> **Catch me if you can.**

---

## 📎 Tech Stack

| Category      | Technology                     |
| ------------- | ------------------------------ |
| Mobile App    | Flutter, Google Maps API       |
| Backend       | NestJS, Socket.io              |
| Database      | Supabase (PostgreSQL)          |
| Game State    | Redis (ioredis)                |
| ORM           | Prisma                         |
| Auth          | Kakao OAuth, JWT               |
| Infra         | AWS EC2                        |

---

## 👥 Our Team

| Name | Affiliation | Role |
|---|---|---|
| **신원영** | Dept. of Information System, Hanyang University | Frontend Developer (Flutter) |
| **최영운** | School of Computing, KAIST | Backend Developer (NestJS) |
