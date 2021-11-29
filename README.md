# IOKitHIDKeyboardTester

**This tool is NOT useful to, or intended for general users.**

IOKitHIDKeyboardTester is an extremely simple ([one-file!](IOKitHIDKeyboardTester/IOKitHIDKeyboardTester.m)) CLI tool that was created to diagnose and further understand an issue in DriverKit causing `kIOHIDOptionsTypeSeizeDevice` to behave incorrectly when used in DriverKit system extensions.

Aside from that, it can also be used as example/reference code for any developers who also wish to implement and use `IOHIDManagerRegisterInputValueCallback`, `IOHIDManagerSetDeviceMatchingMultiple`, and other related functions of IOKit/IOHIDManager.

---

The aforementioned DriverKit issue was breaking global hotkey functionality in applications such as Discord ([example on Twitter](https://twitter.com/akemin_dayo/status/1464234080216629251)) when DriverKit system extensions such as Karabiner-Elements (see [my GitHub issue #2895](https://github.com/pqrs-org/Karabiner-Elements/issues/2895)) were installed on a system.

I actively use both of these products, which is how I noticed the bug in the first place (Discord uses the IOKit/IOHIDManager functions mentioned above for its global hotkey functionality, which I discovered by running `nm -um "${HOME}/Library/Application Support/$DISCORD_VARIANT_HERE/$VERSION_NUMBER_HERE/modules/discord_utils/discord_utils.node"`).

Also of note is that this issue affects some macOS built-in hotkey-related functionality too, such as the "Press the Option key five times to toggle Mouse Keys" feature that many use to quickly toggle locking their MacBook's built-in trackpad.

---

## IMPORTANT — PLEASE READ THIS, IF NOTHING ELSE

Please be aware that **this tool prints out keyboard scancodes directly to _standard output_ which correspond to your keystrokes**!

**Please** do not leave it running and/or type anything sensitive while using the tool, and remember to completely clear your Terminal scrollback when you are done using the tool and have copied any relevant output you may want!

**The entire source code is _very_ simple and exists entirely in just [one file](IOKitHIDKeyboardTester/IOKitHIDKeyboardTester.m), so _please_ do your due diligence and read through the code, making sure that you _fully_ understand what it _does_ and _doesn't_ do before compiling and running it!**

---

## Building

**Xcode:** Press the "Run" button.

**CLI:** `xcodebuild -configuration Release` or simply just `make`. (※ The latter actually just calls `xcodebuild` for you.)

---

## I've already authorised Accessibility/TCC permissions (or it simply does not show up at all), but it still keeps asking me in a loop…

### If you're running from Xcode…

Please uncheck and recheck the existing `IOKitHIDKeyboardTester` entry from your Accessibility/TCC permissions list, then run the tool again.

This occurs because the Xcode project is set to use ad-hoc signing, which results in the code signature changing every time a new binary is built. This invalidates the old Accessibility/TCC authorisation that was given for a previously-signed binary.

If you want to fix this behaviour for your own development builds, simply change the project's codesigning team to your own Apple Developer Team ID.

**※ Note:** On some older versions of Xcode (such as 9.4.1), you may have to grant Accessibility/TCC permissions to Xcode itself, similar to the Terminal instructions below.

### If you're running from a compiled binary via a Terminal instance…

Please grant your **Terminal application** the Accessibility/TCC authorisation. This applies to both Apple's Terminal.app and _any_ third-party applications like it, such as iTerm2.

Manually adding the `IOKitHIDKeyboardTester` binary to the list will **not** work.

---

## License

Licensed under the [MIT License](https://opensource.org/licenses/MIT).
