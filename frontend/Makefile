API_BASE_URL ?= http://127.0.0.1:3000
SOCKET_IO_URL ?= http://127.0.0.1:3000
WS_URL ?= ws://127.0.0.1:3000/v1/ws
KAKAO_JS_APP_KEY ?=
KAKAO_NATIVE_APP_KEY ?=
ALLOW_INMEM_AUTH ?= false

FLUTTER_DEFINES = \
	--dart-define=API_BASE_URL=$(API_BASE_URL) \
	--dart-define=SOCKET_IO_URL=$(SOCKET_IO_URL) \
	--dart-define=WS_URL=$(WS_URL) \
	--dart-define=KAKAO_JS_APP_KEY=$(KAKAO_JS_APP_KEY) \
	--dart-define=KAKAO_NATIVE_APP_KEY=$(KAKAO_NATIVE_APP_KEY) \
	--dart-define=ALLOW_INMEM_AUTH=$(ALLOW_INMEM_AUTH)

get:
	fvm flutter pub get

analyze:
	fvm flutter analyze

test:
	fvm flutter test

run-ios:
	fvm flutter run --debug $(FLUTTER_DEFINES)

run-android:
	fvm flutter run --debug $(FLUTTER_DEFINES)

build-ios-debug:
	fvm flutter build ios --debug --no-codesign $(FLUTTER_DEFINES)

clean:
	fvm flutter clean
	fvm flutter pub get
	cd ios && /opt/homebrew/opt/ruby/bin/bundle exec pod install
	cd ..
