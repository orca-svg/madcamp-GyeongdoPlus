import { IsEmail, IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LocalSignupDto {
  @ApiProperty({
    example: 'thief123@example.com',
    description: '사용자 이메일 (중복 불가)',
  })
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  email: string;

  @ApiProperty({
    example: 'strongPassword123!',
    description: '비밀번호 (영문, 숫자, 특수문자 포함 8자 이상)',
  })
  @IsString()
  @MinLength(8, { message: '비밀번호는 최소 8자 이상이어야 합니다.' })
  @Matches(/^(?=.*[a-zA-Z])(?=.*[!@#$%^*+=-])(?=.*[0-9]).{8,25}$/, {
    message: '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다.',
  })
  password: string;

  @ApiProperty({
    example: 'lupin_the_third',
    description: '사용자 닉네임 (중복 불가)',
  })
  @IsNotEmpty()
  @IsString()
  nickname: string;
}