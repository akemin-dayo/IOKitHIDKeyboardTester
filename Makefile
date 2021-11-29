.PHONY: clean build analyze all
.DEFAULT_GOAL=build

clean::
	xcodebuild -project IOKitHIDKeyboardTester.xcodeproj -target IOKitHIDKeyboardTester -configuration Release clean

build::
	xcodebuild -project IOKitHIDKeyboardTester.xcodeproj -target IOKitHIDKeyboardTester -configuration Release

analyze::
	xcodebuild -project IOKitHIDKeyboardTester.xcodeproj -target IOKitHIDKeyboardTester -configuration Release analyze

test:: build
	build/Release/IOKitHIDKeyboardTester

all:: build
