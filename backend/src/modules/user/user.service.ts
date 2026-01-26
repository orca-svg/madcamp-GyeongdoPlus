import { 
  Injectable, 
  NotFoundException, 
  ConflictException,
  BadRequestException
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../redis/redis.service';
import { UpdateProfileDto, MatchHistoryQueryDto, DeleteAccountDto } from './user.dto';

@Injectable()
export class UserService {
  constructor(private prisma: PrismaService, private redisService: RedisService,) {}

  // 1. 내 프로필 조회 (GET /user/me)
  async getMyProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        stat: true,        // UserStat 테이블 Join
        achievements: true // UserAchievement 테이블 Join
      }
    });

    if (!user) throw new NotFoundException('사용자를 찾을 수 없습니다.');

    return {
      success: true,
      message: '내 프로필을 조회했습니다.',
      data: {
        user: {
          id: user.id,
          nickname: user.nickname,
          email: user.email,         // 본인이므로 이메일 노출
          profileImage: user.profileImage,
          provider: user.provider,
        },
        stat: user.stat,
        achievements: user.achievements,
      },
    };
  }

  // 2. 다른 유저 프로필 조회 (GET /user/profile/:userId)
  async getUserProfile(targetId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: targetId },
      include: {
        stat: true,
        achievements: true
      }
    });

    if (!user) throw new NotFoundException('사용자를 찾을 수 없습니다.');

    return {
      success: true,
      message: '유저 프로필을 조회했습니다.',
      data: {
        user: {
          id: user.id,
          nickname: user.nickname,
          profileImage: user.profileImage,
          createdAt: user.createdAt,
          // ⚠️ 이메일, provider 등 개인정보는 보안상 제외
        },
        stat: user.stat,
        achievements: user.achievements,
      },
    };
  }

  // 3. 프로필 수정 (PATCH /user/me)
  async updateProfile(userId: string, dto: UpdateProfileDto) {
    // 닉네임 중복 체크 (닉네임을 변경하는 경우에만)
    if (dto.nickname) {
      const existingUser = await this.prisma.user.findFirst({
        where: { nickname: dto.nickname },
      });
      if (existingUser && existingUser.id !== userId) {
        throw new ConflictException('이미 사용 중인 닉네임입니다.');
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...dto, // nickname, profileImage 업데이트
      },
    });

    return {
      success: true,
      message: '프로필이 수정되었습니다.',
      data: {
        nickname: updatedUser.nickname,
        updatedAt: updatedUser.updatedAt,
      },
    };
  }
  // ✅ 4. 전적 기록 조회 (GET /user/me/history)
    async getMatchHistory(userId: string, query: MatchHistoryQueryDto) {
      const page = query.page || 1;
      const limit = query.limit || 10;
      const skip = (page - 1) * limit;
  
      // DB 조회: 내 기록 + 게임 정보(Join)
      const records = await this.prisma.matchRecord.findMany({
        where: { userId },
        take: limit,
        skip: skip,
        orderBy: { match: { createdAt: 'desc' } }, // 최신순 정렬
        include: {
          match: true, // GameMatch 정보 같이 가져오기
        },
      });
  
      // 응답 데이터 가공 (Flattening)
      const formattedData = records.map((record) => {
      // 🧮 여기서 시간 차이 계산 (밀리초 -> 초 단위 변환)
      // startedAt이나 endedAt이 없는 경우(강제 종료 등)를 대비해 안전하게 0 처리
      let calculatedPlayTime = 0;
      
      const start = record.match.startedAt 
        ? new Date(record.match.startedAt).getTime() 
        : new Date(record.match.createdAt).getTime(); // startedAt 없으면 createdAt 대타 사용
        
      const end = record.match.endedAt 
        ? new Date(record.match.endedAt).getTime() 
        : null;

      if (end) {
        calculatedPlayTime = Math.floor((end - start) / 1000); // 밀리초를 초(s)로 변환
      }

      return {
        matchId: record.matchId,
        result: record.result,
        role: record.role,
        myStat: {
          catchCount: record.catchCount,
          contribution: record.contribution,
        },
        gameInfo: {
          mode: record.match.mode,
          
          maxPlayers: record.match.maxPlayers, 
          timeLimit: record.match.timeLimit,
          playTime: calculatedPlayTime, 
          
          playedAt: record.match.createdAt,
          mapConfig: record.match.mapConfig,
          rules: record.match.rules,
        },
      };
    });

    return {
      success: true,
      data: formattedData,
    };
  }
  
    // ✅ 5. 회원 탈퇴 (DELETE /user/me)
    async deleteAccount(userId: string, dto: DeleteAccountDto) {
      if (!dto.agreedToLoseData) {
        throw new BadRequestException('데이터 삭제에 동의해야 합니다.');
      }
  
      // 1. DB 삭제 (Cascade 설정 덕분에 UserStat, MatchRecord 등은 자동 삭제됨)
      await this.prisma.user.delete({
        where: { id: userId },
      });
  
      // 2. Redis 정리 (리프레시 토큰 삭제)
      // "auth:refresh_token:{userId}" 키 삭제
      await this.redisService.del(`auth:refresh_token:${userId}`);
  
      // (선택) 만약 게임 중이었다면 "game:*:player:{userId}"도 지워야 하는데, 
      // 이미 User가 삭제되었으므로 게임 로직에서 user lookup 실패 시 자동 처리되도록 두거나,
      // 여기서 현재 참여 중인 matchId를 조회해서 지우는 로직을 추가할 수 있습니다.
      
      return {
        success: true,
        message: '회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.',
        data: null,
      };
    }
}
