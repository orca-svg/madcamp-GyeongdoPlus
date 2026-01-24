get:
	fvm flutter pub get

gen:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

watch:
	fvm flutter pub run build_runner watch --delete-conflicting-outputs

run-android:
	fvm flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=WS_URL=ws://10.0.2.2:3000

run-ios:
	fvm flutter run -d ios --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=WS_URL=ws://localhost:3000

fmt:
	fvm flutter format .

analyze:
	fvm flutter analyze

test:
	fvm flutter test
