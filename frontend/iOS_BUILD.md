# iOS 빌드 가이드

GyeongdoPlus 프로젝트의 iOS 빌드를 위한 완전한 가이드입니다.

## 요구사항

### 시스템 요구사항
- **macOS**: 26.2 (Darwin 25.x) 이상
- **Xcode**: 16.2 이상
- **Homebrew**: 최신 버전

### 필수 도구
- **Ruby**: 4.0.1 (Homebrew 설치)
- **Bundler**: 2.4.22 이상
- **FVM**: 3.2.1 이상
- **Flutter**: 3.38.7 (FVM으로 관리)

## 초기 설정

### 1. Homebrew Ruby 설치

시스템 Ruby(2.6.x)는 최신 gems와 호환되지 않으므로 Homebrew Ruby를 사용합니다.

```bash
# Homebrew Ruby 설치 (아직 없는 경우)
brew install ruby

# Ruby 버전 확인
/opt/homebrew/opt/ruby/bin/ruby --version
# 출력: ruby 4.0.1 (2026-01-13 revision e04267a14b) +PRISM [arm64-darwin25]
```

### 2. FVM 및 Flutter 설정

프로젝트는 FVM을 통해 Flutter 버전을 관리합니다.

```bash
# 프로젝트 루트로 이동 (git 리포지토리 루트)
cd /path/to/madcamp-GyeongdoPlus

# FVM이 없으면 설치
dart pub global activate fvm

# .fvmrc에 명시된 Flutter 버전 설치
# .fvmrc: { "flutter": "3.38.7" }
fvm install 3.38.7

# 프로젝트에 Flutter 버전 적용
fvm use 3.38.7
```

### 3. Flutter 의존성 설치

```bash
# frontend 디렉토리로 이동
cd frontend

# Flutter 의존성 설치
fvm flutter pub get

# iOS 엔진 바이너리 다운로드 (필수)
fvm flutter precache --ios
```

### 4. iOS CocoaPods 설정

프로젝트는 **Bundler**를 통해 CocoaPods 및 의존성을 관리합니다.
Homebrew CocoaPods 대신 반드시 `bundle exec`를 사용해야 합니다.

```bash
# ios 디렉토리로 이동
cd ios

# Bundler 의존성 설치
/opt/homebrew/opt/ruby/bin/bundle install

# CocoaPods 의존성 설치
/opt/homebrew/opt/ruby/bin/bundle exec pod install
```

#### Gemfile 구성

`ios/Gemfile`은 다음과 같이 구성되어 있습니다:

```ruby
source "https://rubygems.org"

# ActiveSupport for Ruby 4.0 compatibility
gem "activesupport", ">= 7.0"

# CocoaPods with objectVersion 70 support
gem "cocoapods", "~> 1.16"

# xcodeproj with Xcode 16.2 objectVersion 70 support
# PR: https://github.com/CocoaPods/Xcodeproj/pull/1007 (merged 2026-01-05)
gem "xcodeproj", git: "https://github.com/CocoaPods/Xcodeproj.git",
                  ref: "2cf6a2263d2b164b87c1fdaed340667046b4e44d"
```

**중요**:
- xcodeproj는 Xcode 16.2의 objectVersion 70을 지원하는 특정 커밋을 사용합니다
- 일반 `pod install` 대신 **반드시** `bundle exec pod install`을 사용해야 합니다

## 빌드 절차

### Clean Build (권장)

처음 빌드하거나 문제가 발생했을 때 사용합니다.

```bash
# frontend 디렉토리에서 실행

# 1. Flutter 클린 빌드
fvm flutter clean

# 2. Flutter 의존성 재설치
fvm flutter pub get

# 3. iOS 엔진 다운로드 (필요시)
fvm flutter precache --ios

# 4. CocoaPods 재설치
cd ios
/opt/homebrew/opt/ruby/bin/bundle exec pod install
cd ..

# 5. iOS 빌드 (코드사인 없이)
fvm flutter build ios --no-codesign
```

### 빠른 빌드

의존성 변경이 없을 때 사용합니다.

```bash
# frontend 디렉토리에서 실행
fvm flutter build ios --no-codesign
```

### Xcode에서 빌드

```bash
# Xcode로 워크스페이스 열기 (반드시 .xcworkspace 사용)
open ios/Runner.xcworkspace
```

Xcode에서:
1. Simulator 또는 Device 선택
2. ⌘+B (Build) 또는 ⌘+R (Run)

**주의**: `Runner.xcodeproj`가 아닌 `Runner.xcworkspace`를 열어야 CocoaPods 의존성이 포함됩니다.

## iOS 버전 정책

### 최소 지원 버전: iOS 15.0

프로젝트는 Apple Watch 연동 기능을 포함하며, Watch 앱이 iOS 15.0+ API를 사용하기 때문에 최소 버전이 15.0으로 설정되어 있습니다.

**변경된 파일**:
- `ios/Podfile`: `platform :ios, '15.0'`
- `ios/Runner.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (3곳)

### Watch 앱 요구사항

- `GyeongdoPlusWatch Watch App` 타겟이 다음 API를 사용:
  - `foregroundStyle` (iOS 15.0+)
  - `tint` (iOS 15.0+)
  - `@main` (iOS 14.0+)
  - `Scene`, `WindowGroup` (iOS 14.0+)

iOS 13.0으로 다운그레이드하려면 Watch 앱의 SwiftUI 코드를 수정해야 합니다.

## 재현 가능한 빌드 환경

팀원이 동일한 환경을 구성하려면:

```bash
# 1. 프로젝트 클론
git clone <repository-url>
cd madcamp-GyeongdoPlus

# 2. FVM 설치 및 Flutter 버전 고정
dart pub global activate fvm
fvm install 3.38.7
fvm use 3.38.7

# 3. frontend 디렉토리로 이동
cd frontend

# 4. Flutter 의존성 설치
fvm flutter pub get
fvm flutter precache --ios

# 5. iOS CocoaPods 설치 (Bundler 사용)
cd ios
/opt/homebrew/opt/ruby/bin/bundle install
/opt/homebrew/opt/ruby/bin/bundle exec pod install
cd ..

# 6. 빌드 테스트
fvm flutter build ios --no-codesign
```

## 트러블슈팅

### 1. "Generated.xcconfig must exist" 오류

```bash
cd frontend
fvm flutter pub get
```

### 2. "sandbox is not in sync with Podfile.lock" 오류

```bash
cd frontend/ios
/opt/homebrew/opt/ruby/bin/bundle exec pod install
```

### 3. "Unable to find compatibility version string for object version 70" 오류

이 오류는 **Homebrew CocoaPods**를 사용했을 때 발생합니다.
반드시 `bundle exec`를 사용해야 합니다:

```bash
cd frontend/ios

# ❌ 잘못된 방법
pod install

# ✅ 올바른 방법
/opt/homebrew/opt/ruby/bin/bundle exec pod install
```

### 4. Ruby 버전 호환성 오류

시스템 Ruby(2.6.x)를 사용하면 ActiveSupport 호환성 문제가 발생합니다.
반드시 Homebrew Ruby 4.0.1을 사용해야 합니다:

```bash
# Homebrew Ruby 확인
/opt/homebrew/opt/ruby/bin/ruby --version

# Homebrew Ruby로 bundle 실행
/opt/homebrew/opt/ruby/bin/bundle install
/opt/homebrew/opt/ruby/bin/bundle exec pod install
```

### 5. FVM 버전 불일치

```bash
# FVM 재활성화
dart pub global activate fvm

# 올바른 Flutter 버전 사용
fvm use 3.38.7

# 확인
fvm flutter --version
# 출력: Flutter 3.38.7 • Dart 3.10.7
```

## Makefile 명령어

프로젝트 루트의 Makefile을 사용할 수 있습니다 (frontend 디렉토리 기준):

```bash
make get          # flutter pub get
make run-ios      # iOS 시뮬레이터 실행
make clean        # flutter clean
make analyze      # 정적 분석
make test         # 테스트 실행
```

**주의**: Makefile의 `run-ios` 명령 전에 CocoaPods 설치가 완료되어 있어야 합니다.

## 변경 이력

### 2026-01-25: iOS 빌드 환경 표준화

**변경 사항**:
1. Bundler를 통한 CocoaPods 버전 관리 (`ios/Gemfile`)
2. Xcode 16.2 objectVersion 70 지원 (xcodeproj 특정 커밋 사용)
3. iOS 최소 버전 13.0 → 15.0 (Apple Watch 요구사항)
4. FVM 버전 고정: `stable` → `3.38.7` (`.fvmrc`)
5. pubspec.yaml 타이포 수정: `flutter_lanuncher_icons` → `flutter_launcher_icons`

**변경된 파일**:
- `ios/Gemfile`: CocoaPods/xcodeproj/activesupport 버전 고정
- `ios/Podfile`: iOS 15.0 최소 버전 설정
- `ios/Runner.xcodeproj/project.pbxproj`:
  - objectVersion 70 복구
  - IPHONEOS_DEPLOYMENT_TARGET 15.0
- `.fvmrc`: Flutter 3.38.7 고정
- `pubspec.yaml`: flutter_launcher_icons 타이포 수정

## 참고 자료

- [CocoaPods Xcodeproj PR #1007](https://github.com/CocoaPods/Xcodeproj/pull/1007) - objectVersion 70 지원
- [Flutter FVM 공식 문서](https://fvm.app/)
- [Bundler 공식 문서](https://bundler.io/)
