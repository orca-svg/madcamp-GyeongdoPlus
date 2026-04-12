-- CreateEnum
CREATE TYPE "Provider" AS ENUM ('LOCAL', 'KAKAO');

-- CreateEnum
CREATE TYPE "GameMode" AS ENUM ('NORMAL', 'ITEM', 'ABILITY');

-- CreateEnum
CREATE TYPE "Team" AS ENUM ('POLICE', 'THIEF');

-- CreateEnum
CREATE TYPE "MatchResult" AS ENUM ('WIN', 'LOSE', 'DRAW', 'ABANDON');

-- CreateEnum
CREATE TYPE "GameStatus" AS ENUM ('WAITING', 'PLAYING', 'ENDED');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "provider" "Provider" NOT NULL,
    "password" TEXT,
    "socialId" TEXT,
    "profileImage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserStat" (
    "userId" UUID NOT NULL,
    "policeMmr" INTEGER NOT NULL DEFAULT 1000,
    "thiefMmr" INTEGER NOT NULL DEFAULT 1000,
    "integrityScore" INTEGER NOT NULL DEFAULT 100,
    "totalCatch" INTEGER NOT NULL DEFAULT 0,
    "totalRelease" INTEGER NOT NULL DEFAULT 0,
    "totalSurvival" INTEGER NOT NULL DEFAULT 0,
    "totalDistance" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "totalMvpCount" INTEGER NOT NULL DEFAULT 0,
    "totalGames" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "UserStat_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "UserAchievement" (
    "userId" UUID NOT NULL,
    "achieveId" TEXT NOT NULL,
    "earnedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserAchievement_pkey" PRIMARY KEY ("userId","achieveId")
);

-- CreateTable
CREATE TABLE "GameMatch" (
    "id" UUID NOT NULL,
    "hostUserId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "endedAt" TIMESTAMP(3),
    "roomCode" TEXT NOT NULL,
    "mode" "GameMode" NOT NULL,
    "maxPlayers" INTEGER NOT NULL DEFAULT 8,
    "timeLimit" INTEGER NOT NULL DEFAULT 600,
    "mapConfig" JSONB NOT NULL,
    "rules" JSONB NOT NULL,
    "status" "GameStatus" NOT NULL DEFAULT 'WAITING',
    "winnerTeam" "Team",
    "mvpUserId" UUID,

    CONSTRAINT "GameMatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MatchRecord" (
    "matchId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "role" "Team" NOT NULL,
    "result" "MatchResult" NOT NULL,
    "catchCount" INTEGER NOT NULL DEFAULT 0,
    "distanceMoved" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "releaseCount" INTEGER NOT NULL DEFAULT 0,
    "survivalTime" INTEGER NOT NULL DEFAULT 0,
    "heartRateLog" JSONB,
    "heartRateMax" INTEGER,
    "contribution" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "MatchRecord_pkey" PRIMARY KEY ("matchId","userId")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_nickname_key" ON "User"("nickname");

-- CreateIndex
CREATE UNIQUE INDEX "GameMatch_roomCode_key" ON "GameMatch"("roomCode");

-- AddForeignKey
ALTER TABLE "UserStat" ADD CONSTRAINT "UserStat_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserAchievement" ADD CONSTRAINT "UserAchievement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GameMatch" ADD CONSTRAINT "GameMatch_mvpUserId_fkey" FOREIGN KEY ("mvpUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MatchRecord" ADD CONSTRAINT "MatchRecord_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "GameMatch"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MatchRecord" ADD CONSTRAINT "MatchRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
