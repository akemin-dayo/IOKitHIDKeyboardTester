#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/NSWorkspace.h>
#import <IOKit/hid/IOHIDManager.h>

#include <signal.h>
#include <sys/utsname.h>

void sigintPrintSensitiveDataReminder(int signalNumber) {
	// We're only interested in SIGINT and nothing else.
	if (signalNumber == 2) {
		// ANSI escape sequences aren't supported by Xcode's output console, but that's fine since you can't press Ctrl-C in Xcode, anyway.
		// (It /is/ possible to send a SIGINT to an Xcode-spawned process, but most people won't be doing that so I'm considering it out of scope for UX flow consideration.)
		
		// It's also possible to programmatically clear the Terminal scrollback using the following ANSI escape sequence, but I ultimately decided against such a destructive action for a very large variety of reasons.
		// printf("\e[2J\e[3J\e[H");
		
		printf("\n\033[31;1mCaught SIGINT (Ctrl-C), exiting…\033[0m\n");
		CFRunLoopStop(CFRunLoopGetCurrent());
		printf("\n\033[31;1mDon't forget to clear your Terminal scrollback after you're done copying any relevant output, as the scrollback contains your keyboard/keypad scancode history! (See the README.md file for more detailed information regarding this warning.)\033[0m\n\n");
		// There's an… interesting (but minor) visual bug where around 7 more lines of content will be printed /after/ the above "final" printf() statement, but seemingly only on systems with Karabiner-Elements's DriverKit dext installed… I wonder why that happens. (The kext does not exhibit the same behaviour.)
	}
}

void onKeyPress(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
	IOHIDElementRef ioHidElement = IOHIDValueGetElement(value);
	IOHIDDeviceRef ioHidDevice = IOHIDElementGetDevice(ioHidElement);
	NSLog(@"Received an event from IOHIDDevice device: %@", ioHidDevice);
	
	uint32_t ioHidUsagePage = IOHIDElementGetUsagePage(ioHidElement);
	if (ioHidUsagePage != kHIDPage_KeyboardOrKeypad) {
		// The Fn key on Apple keyboards returns 0xFF, and Fn+media key combinations return 0x0C
		// Using %02X format instead of %02x to remain consistent with Apple's capitalisation in IOHIDUsageTables.h
		NSLog(@"This IOHIDDevice's HID usage page (0x%02X) is not kHIDPage_KeyboardOrKeypad (0x07)!. Please refer to <IOKit/hid/IOHIDUsageTables.h> for more information.", ioHidUsagePage);
		printf("\n");
		return;
	}
	
	if (!IOHIDDeviceConformsTo(ioHidDevice, kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard) && !IOHIDDeviceConformsTo(ioHidDevice, kHIDPage_GenericDesktop, kHIDUsage_GD_Keypad)) {
		NSLog(@"This IOHIDDevice does not conform to kHIDPage_GenericDesktop + kHIDUsage_GD_Keyboard or kHIDPage_GenericDesktop + kHIDUsage_GD_Keypad!");
		printf("\n");
		return;
	}
	
	// Keyboard scancodes are sensitive data. Don't send them to the OS logger.
	printf("%s\n\n", [[NSString stringWithFormat:@"Received keyboard/keypad scancode: %u with state: %@", IOHIDElementGetUsage(ioHidElement), (IOHIDValueGetIntegerValue(value)) ? @"pressed (down)" : @"released (up)"] UTF8String]);
}

int main(void) {
	@autoreleasepool {
		signal(SIGINT, sigintPrintSensitiveDataReminder);
		
		struct utsname unameStruct;
		uname(&unameStruct);
		NSLog(@"IOKitHIDKeyboardTester started on macOS %@ (%s)", [[NSProcessInfo processInfo] operatingSystemVersionString], unameStruct.machine);
		NSLog(@"https://github.com/akemin-dayo/IOKitHIDKeyboardTester");
		
	    NSLog(@"AXIsProcessTrusted() == %d", AXIsProcessTrusted());
		if (!AXIsProcessTrusted()) {
			NSLog(@"IOKitHIDKeyboardTester does not have Accessibility/TCC authorisation. Opening the Security & Privacy → Accessibility preference pane…");
			// If the System Preferences app is already open, the below openURL call will (benignly) fail with the following error:
			// [open] LAUNCH: Launch failure with -10652/ <FSNode 0x10070e5d0> { isDir = y, path = '/System/Applications/System Preferences.app' }
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]];
			NSLog(@"Please authorise IOKitHIDKeyboardTester in the Security & Privacy → Accessibility preference pane, then run this tool again.");
			NSLog(@"If you have already authorised IOKitHIDKeyboardTester and you are still seeing this, OR if you can't even find its entry in the list of apps to begin with, please refer to the README.md file for more information on what to do.");
			return 1;
		}
		
		NSArray *allConnectedKeyboardsAndKeypads = @[
			@{
				@kIOHIDDeviceUsagePageKey : @(kHIDPage_GenericDesktop),
				@kIOHIDDeviceUsageKey : @(kHIDUsage_GD_Keyboard)
			},
			@{
				@kIOHIDDeviceUsagePageKey : @(kHIDPage_GenericDesktop),
				@kIOHIDDeviceUsageKey : @(kHIDUsage_GD_Keypad)
			}
		];
		
		IOHIDManagerRef ioHidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
		IOHIDManagerSetDeviceMatchingMultiple(ioHidManager, (__bridge CFArrayRef)allConnectedKeyboardsAndKeypads);
		IOHIDManagerRegisterInputValueCallback(ioHidManager, onKeyPress, nil);
		IOHIDManagerScheduleWithRunLoop(ioHidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		IOHIDManagerOpen(ioHidManager, kIOHIDOptionsTypeNone);
		
		printf("\nPress Ctrl-C (or the Stop button, if you're running this in Xcode) to exit IOKitHIDKeyboardTester.\n\n");
		CFRunLoopRun();
		
		IOHIDManagerUnscheduleFromRunLoop(ioHidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		IOHIDManagerClose(ioHidManager, kIOHIDOptionsTypeNone);
	}
	return 0;
}
