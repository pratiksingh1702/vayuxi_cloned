73 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib/main.dart on iPhone 16e in debug mode...
Running pod install...                                           1,954ms
Running Xcode build...                                                  
Xcode build done.                                           50.8s
Failed to build iOS app
Error output from Xcode build:
↳
    ** BUILD FAILED **


Xcode's output:
↳
    Writing result bundle at path:
    	/var/folders/z3/r1b4lpyj18bgpl7c9hpq2vjh0000gn/T/flutter_tools.xkdcV5/flutt
    	er_ios_build_temp_dirfvmfPI/temporary_xcresult_bundle

    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/S
    wiftFlutterTtsPlugin.swift:10:7: warning: stored property 'synthesizer' of
    'Sendable'-conforming class 'SwiftFlutterTtsPlugin' has non-Sendable type
    'AVSpeechSynthesizer'
      let synthesizer = AVSpeechSynthesizer()
          ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/AVFAudio.
    framework/Headers/AVSpeechSynthesis.h:227:12: note: class
    'AVSpeechSynthesizer' does not conform to the 'Sendable' protocol
    @interface AVSpeechSynthesizer : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/S
    wiftFlutterTtsPlugin.swift:10:7: warning: stored property 'synthesizer' of
    'Sendable'-conforming class 'SwiftFlutterTtsPlugin' has non-Sendable type
    'AVSpeechSynthesizer'
      let synthesizer = AVSpeechSynthesizer()
          ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/AVFAudio.
    framework/Headers/AVSpeechSynthesis.h:227:12: note: class
    'AVSpeechSynthesizer' does not conform to the 'Sendable' protocol
    @interface AVSpeechSynthesizer : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.6/ios/url_
    launcher_ios/Sources/url_launcher_ios/URLLauncherPlugin.swift:22:26:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
        UIApplication.shared.keyWindow?.rootViewController?.topViewController
                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/url_launcher_ios-6.3.6/ios/url_
    launcher_ios/Sources/url_launcher_ios/URLLauncherPlugin.swift:22:26:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
        UIApplication.shared.keyWindow?.rootViewController?.topViewController
                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/InputHelper.swift:15:70: warning: 'allowBluetooth' was
    deprecated in iOS 8.0: renamed to
    'AVAudioSession.CategoryOptions.allowBluetoothHFP'
      let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
      .allowBluetooth]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/InputHelper.swift:15:70: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
      let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
      .allowBluetooth]
                                                                      ^~~~~~~~~~
                                                                      ~~~~
                                                                      AVAudioSes
                                                                      sion.Categ
                                                                      oryOptions
                                                                      .allowBlue
                                                                      toothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/RecordIosPlugin.swift:294:47: warning: 'allowBluetooth'
    was deprecated in iOS 8.0: renamed to
    'AVAudioSession.CategoryOptions.allowBluetoothHFP'
            case "allowBluetooth": result.insert(.allowBluetooth)
                                                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/RecordIosPlugin.swift:294:47: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
            case "allowBluetooth": result.insert(.allowBluetooth)
                                                  ^~~~~~~~~~~~~~
                                                  AVAudioSession.CategoryOptions
                                                  .allowBluetoothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/InputHelper.swift:15:70: warning: 'allowBluetooth' was
    deprecated in iOS 8.0: renamed to
    'AVAudioSession.CategoryOptions.allowBluetoothHFP'
      let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
      .allowBluetooth]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/InputHelper.swift:15:70: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
      let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
      .allowBluetooth]
                                                                      ^~~~~~~~~~
                                                                      ~~~~
                                                                      AVAudioSes
                                                                      sion.Categ
                                                                      oryOptions
                                                                      .allowBlue
                                                                      toothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/RecordIosPlugin.swift:294:47: warning: 'allowBluetooth'
    was deprecated in iOS 8.0: renamed to
    'AVAudioSession.CategoryOptions.allowBluetoothHFP'
            case "allowBluetooth": result.insert(.allowBluetooth)
                                                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/record_ios-1.2.0/ios/record_ios
    /Sources/record_ios/RecordIosPlugin.swift:294:47: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
            case "allowBluetooth": result.insert(.allowBluetooth)
                                                  ^~~~~~~~~~~~~~
                                                  AVAudioSession.CategoryOptions
                                                  .allowBluetoothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:269:70: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let controller: UIViewController? =
                UIApplication.shared.keyWindow?.rootViewController
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:273:30: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
            UIApplication.shared.keyWindow?.rootViewController?.present(activity
            ViewController, animated: true)
                                 ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:356:74: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let viewController: UIViewController? =
                UIApplication.shared.keyWindow?.rootViewController
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:269:70: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let controller: UIViewController? =
                UIApplication.shared.keyWindow?.rootViewController
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:273:30: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
            UIApplication.shared.keyWindow?.rootViewController?.present(activity
            ViewController, animated: true)
                                 ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/printing-5.14.2/ios/Classes/Pri
    ntJob.swift:356:74: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let viewController: UIViewController? =
                UIApplication.shared.keyWindow?.rootViewController
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/share_plus-12.0.1/ios/share_plu
    s/Sources/share_plus/FPPSharePlusPlugin.m:25:46: warning: 'keyWindow' is
    deprecated: first deprecated in iOS 13.0 - Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes [-Wdeprecated-declarations]
       25 |     return [UIApplication
       sharedApplication].keyWindow.rootViewController;
          |                                              ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/share_plus/share_plus-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:108:51: note: 'keyWindow' has been explicitly
    marked deprecated here
      108 | @property(nullable, nonatomic,readonly) UIWindow *keyWindow
      API_DEPRECATED("Should not be used for applications that support multiple
      scenes as it returns a key window across all connected scenes", ios(2.0,
      13.0)) API_UNAVAILABLE(visionos, watchos);
          |                                                   ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/share_plus-12.0.1/ios/share_plu
    s/Sources/share_plus/FPPSharePlusPlugin.m:25:46: warning: 'keyWindow' is
    deprecated: first deprecated in iOS 13.0 - Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes [-Wdeprecated-declarations]
       25 |     return [UIApplication
       sharedApplication].keyWindow.rootViewController;
          |                                              ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/share_plus/share_plus-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:108:51: note: 'keyWindow' has been explicitly
    marked deprecated here
      108 | @property(nullable, nonatomic,readonly) UIWindow *keyWindow
      API_DEPRECATED("Should not be used for applications that support multiple
      scenes as it returns a key window across all connected scenes", ios(2.0,
      13.0)) API_UNAVAILABLE(visionos, watchos);
          |                                                   ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/permission_handler_apple-9.4.7/
    ios/Classes/strategies/PhonePermissionStrategy.m:49:35: warning:
    'subscriberCellularProvider' is deprecated: first deprecated in iOS 12.0
    [-Wdeprecated-declarations]
       49 |     CTCarrier *carrier = [netInfo subscriberCellularProvider];
          |                                   ^~~~~~~~~~~~~~~~~~~~~~~~~~
          |                                   serviceSubscriberCellularProviders
    In module 'CoreTelephony' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/permission_handler_apple-9.4.7/
    ios/Classes/strategies/PhonePermissionStrategy.m:8:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreTelephony
    .framework/Headers/CTTelephonyNetworkInfo.h:114:50: note: property
    'subscriberCellularProvider' is declared deprecated here
      114 | @property(readonly, retain, nullable) CTCarrier
      *subscriberCellularProvider
      API_DEPRECATED_WITH_REPLACEMENT("serviceSubscriberCellularProviders",
      ios(4.0, 12.0)) API_UNAVAILABLE(macos);
          |                                                  ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreTelephony
    .framework/Headers/CTTelephonyNetworkInfo.h:114:50: note:
    'subscriberCellularProvider' has been explicitly marked deprecated here
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/permission_handler_apple-9.4.7/
    ios/Classes/strategies/PhonePermissionStrategy.m:49:35: warning:
    'subscriberCellularProvider' is deprecated: first deprecated in iOS 12.0
    [-Wdeprecated-declarations]
       49 |     CTCarrier *carrier = [netInfo subscriberCellularProvider];
          |                                   ^~~~~~~~~~~~~~~~~~~~~~~~~~
          |                                   serviceSubscriberCellularProviders
    In module 'CoreTelephony' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/permission_handler_apple-9.4.7/
    ios/Classes/strategies/PhonePermissionStrategy.m:8:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreTelephony
    .framework/Headers/CTTelephonyNetworkInfo.h:114:50: note: property
    'subscriberCellularProvider' is declared deprecated here
      114 | @property(readonly, retain, nullable) CTCarrier
      *subscriberCellularProvider
      API_DEPRECATED_WITH_REPLACEMENT("serviceSubscriberCellularProviders",
      ios(4.0, 12.0)) API_UNAVAILABLE(macos);
          |                                                  ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreTelephony
    .framework/Headers/CTTelephonyNetworkInfo.h:114:50: note:
    'subscriberCellularProvider' has been explicitly marked deprecated here
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/open_file_ios-1.0.4/ios/open_fi
    le_ios/Sources/open_file_ios/OpenFilePlugin.m:95:9: warning:
    'UI_USER_INTERFACE_IDIOM' is deprecated: first deprecated in iOS 13.0 - Use
    -[UIDevice userInterfaceIdiom] directly. [-Wdeprecated-declarations]
       95 |     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
          |         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/open_file_ios/open_file_ios-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDevice.h:77:36: note: 'UI_USER_INTERFACE_IDIOM' has been
    explicitly marked deprecated here
       77 | static inline UIUserInterfaceIdiom UI_USER_INTERFACE_IDIOM(void)
       API_DEPRECATED("Use -[UIDevice userInterfaceIdiom] directly.", ios(2.0,
       13.0), tvos(9.0, 11.0)) API_UNAVAILABLE(visionos, watchos) {
          |                                    ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/open_file_ios-1.0.4/ios/open_fi
    le_ios/Sources/open_file_ios/OpenFilePlugin.m:95:9: warning:
    'UI_USER_INTERFACE_IDIOM' is deprecated: first deprecated in iOS 13.0 - Use
    -[UIDevice userInterfaceIdiom] directly. [-Wdeprecated-declarations]
       95 |     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
          |         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/open_file_ios/open_file_ios-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDevice.h:77:36: note: 'UI_USER_INTERFACE_IDIOM' has been
    explicitly marked deprecated here
       77 | static inline UIUserInterfaceIdiom UI_USER_INTERFACE_IDIOM(void)
       API_DEPRECATED("Use -[UIDevice userInterfaceIdiom] directly.", ios(2.0,
       13.0), tvos(9.0, 11.0)) API_UNAVAILABLE(visionos, watchos) {
          |                                    ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerImageUtil.m:120:71:
    warning: 'kUTTypeGIF' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeGIF or UTType.gif (swift) instead. [-Wdeprecated-declarations]
      120 |   options[(NSString *)kCGImageSourceTypeIdentifierHint] = (NSString
      *)kUTTypeGIF;
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerImageUtil.m:6:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:729:26: note: 'kUTTypeGIF' has been
    explicitly marked deprecated here
      729 | extern const CFStringRef kUTTypeGIF
      API_DEPRECATED("Use UTTypeGIF or UTType.gif (swift) instead.", ios(3.0,
      15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerImageUtil.m:120:71:
    warning: 'kUTTypeGIF' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeGIF or UTType.gif (swift) instead. [-Wdeprecated-declarations]
      120 |   options[(NSString *)kCGImageSourceTypeIdentifierHint] = (NSString
      *)kUTTypeGIF;
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerImageUtil.m:6:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:729:26: note: 'kUTTypeGIF' has been
    explicitly marked deprecated here
      729 | extern const CFStringRef kUTTypeGIF
      API_DEPRECATED("Use UTTypeGIF or UTType.gif (swift) instead.", ios(3.0,
      15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/S
    wiftFlutterTtsPlugin.swift:10:7: warning: stored property 'synthesizer' of
    'Sendable'-conforming class 'SwiftFlutterTtsPlugin' has non-Sendable type
    'AVSpeechSynthesizer'
      let synthesizer = AVSpeechSynthesizer()
          ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/AVFAudio.
    framework/Headers/AVSpeechSynthesis.h:227:12: note: class
    'AVSpeechSynthesizer' does not conform to the 'Sendable' protocol
    @interface AVSpeechSynthesizer : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/A
    udioCategoryOptions.swift:25:15: warning: 'allowBluetooth' was deprecated in
    iOS 8.0: renamed to 'AVAudioSession.CategoryOptions.allowBluetoothHFP'
          return .allowBluetooth
                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/A
    udioCategoryOptions.swift:25:15: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
          return .allowBluetooth
                  ^~~~~~~~~~~~~~
                  AVAudioSession.CategoryOptions.allowBluetoothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/A
    udioCategoryOptions.swift:25:15: warning: 'allowBluetooth' was deprecated in
    iOS 8.0: renamed to 'AVAudioSession.CategoryOptions.allowBluetoothHFP'
          return .allowBluetooth
                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/A
    udioCategoryOptions.swift:25:15: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
          return .allowBluetooth
                  ^~~~~~~~~~~~~~
                  AVAudioSession.CategoryOptions.allowBluetoothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_tts-4.2.5/ios/Classes/S
    wiftFlutterTtsPlugin.swift:10:7: warning: stored property 'synthesizer' of
    'Sendable'-conforming class 'SwiftFlutterTtsPlugin' has non-Sendable type
    'AVSpeechSynthesizer'
      let synthesizer = AVSpeechSynthesizer()
          ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/AVFAudio.
    framework/Headers/AVSpeechSynthesis.h:227:12: note: class
    'AVSpeechSynthesizer' does not conform to the 'Sendable' protocol
    @interface AVSpeechSynthesizer : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_local_notifications-19.
    5.0/ios/flutter_local_notifications/Sources/flutter_local_notifications/Flut
    terLocalNotificationsPlugin.m:972:30: warning:
    'UNNotificationPresentationOptionAlert' is deprecated: first deprecated in
    iOS 14.0 [-Wdeprecated-declarations]
      972 |       presentationOptions |= UNNotificationPresentationOptionAlert;
          |                              ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |                              UNNotificationPresentationOptionList |
          UNNotificationPresentationOptionBanner
    In module 'UserNotifications' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_local_notifications-19.
    5.0/ios/flutter_local_notifications/Sources/flutter_local_notifications/./in
    clude/flutter_local_notifications/FlutterLocalNotificationsPlugin.h:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UserNotif
    ications.framework/Headers/UNUserNotificationCenter.h:84:5: note:
    'UNNotificationPresentationOptionAlert' has been explicitly marked
    deprecated here
       84 |     UNNotificationPresentationOptionAlert
       API_DEPRECATED_WITH_REPLACEMENT("UNNotificationPresentationOptionList |
       UNNotificationPresentationOptionBanner", macos(10.14, 11.0), ios(10.0,
       14.0), watchos(3.0, 7.0), tvos(10.0, 14.0)) = (1 << 2),
          |     ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_local_notifications-19.
    5.0/ios/flutter_local_notifications/Sources/flutter_local_notifications/Flut
    terLocalNotificationsPlugin.m:972:30: warning:
    'UNNotificationPresentationOptionAlert' is deprecated: first deprecated in
    iOS 14.0 [-Wdeprecated-declarations]
      972 |       presentationOptions |= UNNotificationPresentationOptionAlert;
          |                              ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |                              UNNotificationPresentationOptionList |
          UNNotificationPresentationOptionBanner
    In module 'UserNotifications' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_local_notifications-19.
    5.0/ios/flutter_local_notifications/Sources/flutter_local_notifications/./in
    clude/flutter_local_notifications/FlutterLocalNotificationsPlugin.h:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UserNotif
    ications.framework/Headers/UNUserNotificationCenter.h:84:5: note:
    'UNNotificationPresentationOptionAlert' has been explicitly marked
    deprecated here
       84 |     UNNotificationPresentationOptionAlert
       API_DEPRECATED_WITH_REPLACEMENT("UNNotificationPresentationOptionList |
       UNNotificationPresentationOptionBanner", macos(10.14, 11.0), ios(10.0,
       14.0), watchos(3.0, 7.0), tvos(10.0, 14.0)) = (1 << 2),
          |     ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:70:64:
    warning: 'windows' is deprecated: first deprecated in iOS 15.0 - Use
    UIWindowScene.windows on a relevant window scene instead
    [-Wdeprecated-declarations]
       70 |     for (UIWindow *window in [UIApplication
       sharedApplication].windows) {
          |                                                                ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/image_picker_ios/image_picker_ios-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:109:62: note: 'windows' has been explicitly
    marked deprecated here
      109 | @property(nonatomic,readonly) NSArray<__kindof UIWindow *>  *windows
      API_DEPRECATED("Use UIWindowScene.windows on a relevant window scene
      instead", ios(2.0, 15.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:128:39:
    warning: 'kUTTypeImage' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeImage or UTType.image (swift) instead. [-Wdeprecated-declarations]
      128 |     [mediaTypes addObject:(NSString *)kUTTypeImage];
          |                                       ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:131:39:
    warning: 'kUTTypeMovie' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeMovie or UTType.movie (swift) instead. [-Wdeprecated-declarations]
      131 |     [mediaTypes addObject:(NSString *)kUTTypeMovie];
          |                                       ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:880:26: note: 'kUTTypeMovie' has been
    explicitly marked deprecated here
      880 | extern const CFStringRef kUTTypeMovie
      API_DEPRECATED("Use UTTypeMovie or UTType.movie (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    3 warnings generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPhotoAssetUtil.m:102:
    56: warning: 'kUTTypeGIF' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeGIF or UTType.gif (swift) instead. [-Wdeprecated-declarations]
      102 |       (__bridge CFURLRef)[NSURL fileURLWithPath:path], kUTTypeGIF,
      gifInfo.images.count, NULL);
          |                                                        ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPhotoAssetUtil.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:729:26: note: 'kUTTypeGIF' has been
    explicitly marked deprecated here
      729 | extern const CFStringRef kUTTypeGIF
      API_DEPRECATED("Use UTTypeGIF or UTType.gif (swift) instead.", ios(3.0,
      15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:70:64:
    warning: 'windows' is deprecated: first deprecated in iOS 15.0 - Use
    UIWindowScene.windows on a relevant window scene instead
    [-Wdeprecated-declarations]
       70 |     for (UIWindow *window in [UIApplication
       sharedApplication].windows) {
          |                                                                ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/image_picker_ios/image_picker_ios-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:109:62: note: 'windows' has been explicitly
    marked deprecated here
      109 | @property(nonatomic,readonly) NSArray<__kindof UIWindow *>  *windows
      API_DEPRECATED("Use UIWindowScene.windows on a relevant window scene
      instead", ios(2.0, 15.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:128:39:
    warning: 'kUTTypeImage' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeImage or UTType.image (swift) instead. [-Wdeprecated-declarations]
      128 |     [mediaTypes addObject:(NSString *)kUTTypeImage];
          |                                       ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:131:39:
    warning: 'kUTTypeMovie' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeMovie or UTType.movie (swift) instead. [-Wdeprecated-declarations]
      131 |     [mediaTypes addObject:(NSString *)kUTTypeMovie];
          |                                       ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPlugin.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:880:26: note: 'kUTTypeMovie' has been
    explicitly marked deprecated here
      880 | extern const CFStringRef kUTTypeMovie
      API_DEPRECATED("Use UTTypeMovie or UTType.movie (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    3 warnings generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPhotoAssetUtil.m:102:
    56: warning: 'kUTTypeGIF' is deprecated: first deprecated in iOS 15.0 - Use
    UTTypeGIF or UTType.gif (swift) instead. [-Wdeprecated-declarations]
      102 |       (__bridge CFURLRef)[NSURL fileURLWithPath:path], kUTTypeGIF,
      gifInfo.images.count, NULL);
          |                                                        ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/image_picker_ios-0.8.13+3/ios/i
    mage_picker_ios/Sources/image_picker_ios/FLTImagePickerPhotoAssetUtil.m:9:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:729:26: note: 'kUTTypeGIF' has been
    explicitly marked deprecated here
      729 | extern const CFStringRef kUTTypeGIF
      API_DEPRECATED("Use UTTypeGIF or UTType.gif (swift) instead.", ios(3.0,
      15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/SaveFileDialog.swift:159:63: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let parentViewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/SaveFileDialog.swift:168:44: warning: 'init(url:in:)' was deprecated
    in iOS 14.0
            let documentPickerViewController =
            UIDocumentPickerViewController(url: fileUrl!, in: .exportToService)
                                               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:28:57: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let viewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                            ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:67: warning: 'kUTTypeText' was deprecated in
    iOS 15.0: Use UTTypeText or UTType.text (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:88: warning: 'kUTTypeContent' was deprecated
    in iOS 15.0: Use UTTypeContent or UTType.content (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:112: warning: 'kUTTypeItem' was deprecated in
    iOS 15.0: Use UTTypeItem or UTType.item (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:133: warning: 'kUTTypeData' was deprecated in
    iOS 15.0: Use UTTypeData or UTType.data (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:52:48: warning: 'init(documentTypes:in:)' was
    deprecated in iOS 14.0
                let documentPickerViewController =
                UIDocumentPickerViewController(documentTypes: documentTypes, in:
                .import)
                                                   ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:81:57: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let viewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                            ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:89:44: warning: 'init(documentTypes:in:)' was
    deprecated in iOS 14.0
            let documentPickerViewController =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as
            String], in: .open)
                                               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:89:91: warning: 'kUTTypeFolder' was deprecated
    in iOS 15.0: Use UTTypeFolder or UTType.folder (swift) instead.
            let documentPickerViewController =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as
            String], in: .open)
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/SaveFileDialog.swift:159:63: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let parentViewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                                  ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/SaveFileDialog.swift:168:44: warning: 'init(url:in:)' was deprecated
    in iOS 14.0
            let documentPickerViewController =
            UIDocumentPickerViewController(url: fileUrl!, in: .exportToService)
                                               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:28:57: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let viewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                            ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:67: warning: 'kUTTypeText' was deprecated in
    iOS 15.0: Use UTTypeText or UTType.text (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:88: warning: 'kUTTypeContent' was deprecated
    in iOS 15.0: Use UTTypeContent or UTType.content (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:112: warning: 'kUTTypeItem' was deprecated in
    iOS 15.0: Use UTTypeItem or UTType.item (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:50:133: warning: 'kUTTypeData' was deprecated in
    iOS 15.0: Use UTTypeData or UTType.data (swift) instead.
                let documentTypes = params.allowedUtiTypes ??
                [String(kUTTypeText), String(kUTTypeContent),
                String(kUTTypeItem), String(kUTTypeData)]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:52:48: warning: 'init(documentTypes:in:)' was
    deprecated in iOS 14.0
                let documentPickerViewController =
                UIDocumentPickerViewController(documentTypes: documentTypes, in:
                .import)
                                                   ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:81:57: warning: 'keyWindow' was deprecated in
    iOS 13.0: Should not be used for applications that support multiple scenes
    as it returns a key window across all connected scenes
            guard let viewController =
            UIApplication.shared.keyWindow?.rootViewController else {
                                                            ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:89:44: warning: 'init(documentTypes:in:)' was
    deprecated in iOS 14.0
            let documentPickerViewController =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as
            String], in: .open)
                                               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/flutter_file_dialog-3.0.3/ios/C
    lasses/OpenFileDialog.swift:89:91: warning: 'kUTTypeFolder' was deprecated
    in iOS 15.0: Use UTTypeFolder or UTType.folder (swift) instead.
            let documentPickerViewController =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as
            String], in: .open)
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_selector_ios-0.5.3+4/ios/f
    ile_selector_ios/Sources/file_selector_ios/FileSelectorPlugin.swift:61:10:
    warning: 'init(documentTypes:in:)' was deprecated in iOS 14.0
          ?? UIDocumentPickerViewController(
             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_selector_ios-0.5.3+4/ios/f
    ile_selector_ios/Sources/file_selector_ios/FileSelectorPlugin.swift:61:10:
    warning: 'init(documentTypes:in:)' was deprecated in iOS 14.0
          ?? UIDocumentPickerViewController(
             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_saver-0.3.1/ios/Classes/Di
    alog.swift:26:55: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let viewController = UIApplication.shared.keyWindow?
                                                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_saver-0.3.1/ios/Classes/Di
    alog.swift:26:55: warning: 'keyWindow' was deprecated in iOS 13.0: Should
    not be used for applications that support multiple scenes as it returns a
    key window across all connected scenes
                let viewController = UIApplication.shared.keyWindow?
                                                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/device_info_plus-12.3.0/ios/dev
    ice_info_plus/Sources/device_info_plus/FPPDeviceInfoPlusPlugin.m:96:45:
    warning: implicit conversion loses integer precision: 'vm_size_t' (aka
    'unsigned long') to 'natural_t' (aka 'unsigned int') [-Wshorten-64-to-32]
       96 |     natural_t mem_free = vm_stat.free_count * page_size;
          |               ~~~~~~~~   ~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/device_info_plus-12.3.0/ios/dev
    ice_info_plus/Sources/device_info_plus/FPPDeviceInfoPlusPlugin.m:96:45:
    warning: implicit conversion loses integer precision: 'vm_size_t' (aka
    'unsigned long') to 'natural_t' (aka 'unsigned int') [-Wshorten-64-to-32]
       96 |     natural_t mem_free = vm_stat.free_count * page_size;
          |               ~~~~~~~~   ~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:37:76: warning: 'allowBluetooth' was deprecated in
    iOS 8.0: renamed to 'AVAudioSession.CategoryOptions.allowBluetoothHFP'
            let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
            .allowBluetooth]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:37:76: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
            let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
            .allowBluetooth]
                                                                      ^~~~~~~~~~
                                                                      ~~~~
                                                                      AVAudioSes
                                                                      sion.Categ
                                                                      oryOptions
                                                                      .allowBlue
                                                                      toothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:138:82: warning: capture 'self' was never used
                AVAudioSession.sharedInstance().requestRecordPermission() {
                [unowned self] allowed in
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/WaveformExtractor.swift:171:13: warning: capture of 'self' with
    non-Sendable type 'WaveformExtractor' in a '@Sendable' closure
                self.flutterChannel.invokeMethod(
                ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/WaveformExtractor.swift:4:14: note: class 'WaveformExtractor' does not
    conform to the 'Sendable' protocol
    public class WaveformExtractor {
                 ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/WaveformExtractor.swift:171:13: warning: capture of 'self' with
    non-Sendable type 'WaveformExtractor' in a '@Sendable' closure
                self.flutterChannel.invokeMethod(
                ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/WaveformExtractor.swift:4:14: note: class 'WaveformExtractor' does not
    conform to the 'Sendable' protocol
    public class WaveformExtractor {
                 ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:37:76: warning: 'allowBluetooth' was deprecated in
    iOS 8.0: renamed to 'AVAudioSession.CategoryOptions.allowBluetoothHFP'
            let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
            .allowBluetooth]
                                                                      ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:37:76: note: use
    'AVAudioSession.CategoryOptions.allowBluetoothHFP' instead
            let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker,
            .allowBluetooth]
                                                                      ^~~~~~~~~~
                                                                      ~~~~
                                                                      AVAudioSes
                                                                      sion.Categ
                                                                      oryOptions
                                                                      .allowBlue
                                                                      toothHFP
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/audio_waveforms-2.0.2/ios/Class
    es/AudioRecorder.swift:138:82: warning: capture 'self' was never used
                AVAudioSession.sharedInstance().requestRecordPermission() {
                [unowned self] allowed in
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/TOCropViewControl
    ler/Objective-C/TOCropViewController/Views/TOCropToolbar.m:299:28: warning:
    'imageEdgeInsets' is deprecated: first deprecated in iOS 15.0 - This
    property is ignored when using UIButtonConfiguration
    [-Wdeprecated-declarations]
      299 |                     button.imageEdgeInsets = UIEdgeInsetsMake(0, 0,
      image.baselineOffsetFromBottom, 0);
          |                            ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/TOCropViewController/TOCropViewController-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIButton.h:164:35: note: 'imageEdgeInsets' has been
    explicitly marked deprecated here
      164 | @property(nonatomic) UIEdgeInsets imageEdgeInsets
      API_DEPRECATED("This property is ignored when using
      UIButtonConfiguration", ios(2.0, 15.0), tvos(2.0, 15.0), visionos(1.0,
      1.0)) API_UNAVAILABLE(watchos);                // default is
      UIEdgeInsetsZero
          |                                   ^
    1 warning generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/TOCropViewControl
    ler/Objective-C/TOCropViewController/Views/TOCropToolbar.m:299:28: warning:
    'imageEdgeInsets' is deprecated: first deprecated in iOS 15.0 - This
    property is ignored when using UIButtonConfiguration
    [-Wdeprecated-declarations]
      299 |                     button.imageEdgeInsets = UIEdgeInsetsMake(0, 0,
      image.baselineOffsetFromBottom, 0);
          |                            ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/TOCropViewController/TOCropViewController-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIButton.h:164:35: note: 'imageEdgeInsets' has been
    explicitly marked deprecated here
      164 | @property(nonatomic) UIEdgeInsets imageEdgeInsets
      API_DEPRECATED("This property is ignored when using
      UIButtonConfiguration", ios(2.0, 15.0), tvos(2.0, 15.0), visionos(1.0,
      1.0)) API_UNAVAILABLE(watchos);                // default is
      UIEdgeInsetsZero
          |                                   ^
    1 warning generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SwiftyGif/SwiftyG
    if/ObjcAssociatedWeakObject.swift:13:14: warning: weak variable 'weakValue'
    was never mutated; consider changing to 'let' constant
        weak var weakValue = value
             ~~~ ^
             let
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SwiftyGif/SwiftyG
    if/ObjcAssociatedWeakObject.swift:13:14: warning: weak variable 'weakValue'
    was never mutated; consider changing to 'let' constant
        weak var weakValue = value
             ~~~ ^
             let
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:102: warning: 'kUTTagClassFilenameExtension'
    is deprecated: first deprecated in iOS 15.0 - Use
    UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:173: warning: 'kUTTypeImage' is deprecated:
    first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image (swift)
    instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:210:17: warning: 'UTTypeIsDynamic' is deprecated:
    first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
      210 |             if (UTTypeIsDynamic((__bridge
      CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:102: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:173: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:654:17: warning: 'UTTypeIsDynamic' is
    deprecated: first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
      654 |             if (UTTypeIsDynamic((__bridge
      CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:102: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:173: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:91:17: warning: 'UTTypeIsDynamic' is
    deprecated: first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
       91 |             if (UTTypeIsDynamic((__bridge
       CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/NSData+ImageContentType.m:159:16: warning: 'UTTypeConformsTo' is
    deprecated: first deprecated in iOS 15.0 - Use -[UTType conformsToType:]
    instead. [-Wdeprecated-declarations]
      159 |     } else if (UTTypeConformsTo(uttype, kSDUTTypeRAW)) {
          |                ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/NSData+ImageContentType.m:14:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:472:1: note: 'UTTypeConformsTo' has been
    explicitly marked deprecated here
      472 | UTTypeConformsTo(
          | ^
    1 warning generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:102: warning: 'kUTTagClassFilenameExtension'
    is deprecated: first deprecated in iOS 15.0 - Use
    UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:208:173: warning: 'kUTTypeImage' is deprecated:
    first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image (swift)
    instead. [-Wdeprecated-declarations]
      208 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:210:17: warning: 'UTTypeIsDynamic' is deprecated:
    first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
      210 |             if (UTTypeIsDynamic((__bridge
      CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOCoder.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:102: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:652:173: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
      652 |             typeIdentifierHint = (__bridge_transfer NSString
      *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
      (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:654:17: warning: 'UTTypeIsDynamic' is
    deprecated: first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
      654 |             if (UTTypeIsDynamic((__bridge
      CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageIOAnimatedCoder.m:20:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:64: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |                                                                ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:102: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:89:173: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
       89 |             typeIdentifierHint = (__bridge_transfer NSString
       *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
          |
          ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:91:17: warning: 'UTTypeIsDynamic' is
    deprecated: first deprecated in iOS 15.0 - Use UTType.dynamic instead.
    [-Wdeprecated-declarations]
       91 |             if (UTTypeIsDynamic((__bridge
       CFStringRef)typeIdentifierHint)) {
          |                 ^
    In module 'CoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/SDImageCacheDefine.m:17:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:536:1: note: 'UTTypeIsDynamic' has been
    explicitly marked deprecated here
      536 | UTTypeIsDynamic(CFStringRef inUTI)
      API_DEPRECATED("Use UTType.dynamic instead.", ios(8.0, 15.0), macos(10.10,
      12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          | ^
    4 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/NSData+ImageContentType.m:159:16: warning: 'UTTypeConformsTo' is
    deprecated: first deprecated in iOS 15.0 - Use -[UTType conformsToType:]
    instead. [-Wdeprecated-declarations]
      159 |     } else if (UTTypeConformsTo(uttype, kSDUTTypeRAW)) {
          |                ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/SDWebImage/SDWebI
    mage/Core/NSData+ImageContentType.m:14:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:472:1: note: 'UTTypeConformsTo' has been
    explicitly marked deprecated here
      472 | UTTypeConformsTo(
          | ^
    1 warning generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:39:52: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDataSource: class {
                                                       ^~~~~
                                                       AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:55:50: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDelegate: class {
                                                     ^~~~~
                                                     AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: warning:
    'gray' was deprecated in iOS 13.0: renamed to
    'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:39:52: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDataSource: class {
                                                       ^~~~~
                                                       AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:55:50: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDelegate: class {
                                                     ^~~~~
                                                     AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: warning:
    'gray' was deprecated in iOS 13.0: renamed to
    'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:161:124: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            scrollView.addObserver(self, forKeyPath:
            DKPhotoIncrementalIndicator.contentSizeKeyPath, options: [.new],
            context: &DKPhotoIncrementalIndicator.context)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:162:126: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            scrollView.addObserver(self, forKeyPath:
            DKPhotoIncrementalIndicator.contentOffsetKeyPath, options: [.new],
            context: &DKPhotoIncrementalIndicator.context)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:171:23: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            if context == &DKPhotoIncrementalIndicator.context {
                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/QRCode/DKPhotoWebVC.swift:46:56: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            self.spinner = UIActivityIndicatorView(style: .gray)
                                                           ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/QRCode/DKPhotoWebVC.swift:46:56: note: use
    'UIActivityIndicatorView.Style.medium' instead
            self.spinner = UIActivityIndicatorView(style: .gray)
                                                           ^~~~
                                                           UIActivityIndicatorVi
                                                           ew.Style.medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: warning:
    'gray' was deprecated in iOS 13.0: renamed to
    'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:39:52: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDataSource: class {
                                                       ^~~~~
                                                       AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:55:50: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDelegate: class {
                                                     ^~~~~
                                                     AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:107:14: warning:
    'automaticallyAdjustsScrollViewInsets' was deprecated in iOS 11.0: Use
    UIScrollView's contentInsetAdjustmentBehavior instead
            self.automaticallyAdjustsScrollViewInsets = false
                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:161:124: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            scrollView.addObserver(self, forKeyPath:
            DKPhotoIncrementalIndicator.contentSizeKeyPath, options: [.new],
            context: &DKPhotoIncrementalIndicator.context)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:162:126: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            scrollView.addObserver(self, forKeyPath:
            DKPhotoIncrementalIndicator.contentOffsetKeyPath, options: [.new],
            context: &DKPhotoIncrementalIndicator.context)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoIncrementalIndicator.swift:171:23: warning: forming
    'UnsafeMutableRawPointer' to an inout variable of type String exposes the
    internal representation rather than the string contents.
            if context == &DKPhotoIncrementalIndicator.context {
                          ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImageDownloader.swift:92:87:
    warning: 'kUTTypeGIF' was deprecated in iOS 15.0: Use UTTypeGIF or
    UTType.gif (swift) instead.
                let isGif = (asset.value(forKey: "uniformTypeIdentifier") as?
                String) == (kUTTypeGIF as String)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImageDownloader.swift:94:42:
    warning: 'requestImageData(for:options:resultHandler:)' was deprecated in
    iOS 13
                    PHImageManager.default().requestImageData(for: asset,
                                             ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImagePreviewVC.swift:34:42:
    warning: 'contentEdgeInsets' was deprecated in iOS 15.0: This property is
    ignored when using UIButtonConfiguration
            self.downloadOriginalImageButton.contentEdgeInsets =
            UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                                             ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/QRCode/DKPhotoWebVC.swift:46:56: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            self.spinner = UIActivityIndicatorView(style: .gray)
                                                           ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/QRCode/DKPhotoWebVC.swift:46:56: note: use
    'UIActivityIndicatorView.Style.medium' instead
            self.spinner = UIActivityIndicatorView(style: .gray)
                                                           ^~~~
                                                           UIActivityIndicatorVi
                                                           ew.Style.medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: warning:
    'gray' was deprecated in iOS 13.0: renamed to
    'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PlayerPreview/DKPlayerView.swift:152:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoBaseImagePreviewVC.swift:171:30:
    warning: 'UIPreviewAction' was deprecated in iOS 13.0: Please use
    UIContextMenuInteraction.
            let saveActionItem = UIPreviewAction(title:
            DKPhotoGalleryResource.localizedStringWithKey("preview.3DTouch.saveI
            mage.title"),
                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: warning: 'gray' was
    deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
            return UIActivityIndicatorView(style: .gray)
                                                   ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/PDFPreview/DKPDFView.swift:50:48: note: use
    'UIActivityIndicatorView.Style.medium' instead
            return UIActivityIndicatorView(style: .gray)
                                                   ^~~~
                                                   UIActivityIndicatorView.Style
                                                   .medium
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoBaseImagePreviewVC.swift:171:30:
    warning: 'UIPreviewAction' was deprecated in iOS 13.0: Please use
    UIContextMenuInteraction.
            let saveActionItem = UIPreviewAction(title:
            DKPhotoGalleryResource.localizedStringWithKey("preview.3DTouch.saveI
            mage.title"),
                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImageDownloader.swift:92:87:
    warning: 'kUTTypeGIF' was deprecated in iOS 15.0: Use UTTypeGIF or
    UTType.gif (swift) instead.
                let isGif = (asset.value(forKey: "uniformTypeIdentifier") as?
                String) == (kUTTypeGIF as String)
                                                                      ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImageDownloader.swift:94:42:
    warning: 'requestImageData(for:options:resultHandler:)' was deprecated in
    iOS 13
                    PHImageManager.default().requestImageData(for: asset,
                                             ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/Preview/ImagePreview/DKPhotoImagePreviewVC.swift:34:42:
    warning: 'contentEdgeInsets' was deprecated in iOS 15.0: This property is
    ignored when using UIButtonConfiguration
            self.downloadOriginalImageButton.contentEdgeInsets =
            UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
                                             ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:39:52: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDataSource: class {
                                                       ^~~~~
                                                       AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:55:50: warning: using 'class'
    keyword to define a class-constrained protocol is deprecated; use
    'AnyObject' instead
    internal protocol DKPhotoGalleryContentDelegate: class {
                                                     ^~~~~
                                                     AnyObject
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGalleryContentVC.swift:107:14: warning:
    'automaticallyAdjustsScrollViewInsets' was deprecated in iOS 11.0: Use
    UIScrollView's contentInsetAdjustmentBehavior instead
            self.automaticallyAdjustsScrollViewInsets = false
                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKPhotoGallery/DK
    PhotoGallery/DKPhotoGallery.swift:144:62: warning: 'statusBarStyle' was
    deprecated in iOS 13.0: Use the statusBarManager property of the window
    scene instead.
        private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
                                                                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/View/DKAssetGroupDetailVC.swift:344:1
    4: warning: 'frameInterval' was deprecated in iOS 10.0:
    preferredFramesPerSecond
            link.frameInterval = 1
                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/View/DKAssetGroupDetailVC.swift:344:1
    4: warning: 'frameInterval' was deprecated in iOS 10.0:
    preferredFramesPerSecond
            link.frameInterval = 1
                 ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:38
    7:32: warning: 'UNNotificationPresentationOptionAlert' is deprecated: first
    deprecated in iOS 14.0 [-Wdeprecated-declarations]
      387 |         presentationOptions |=
      UNNotificationPresentationOptionAlert;
          |                                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |                                UNNotificationPresentationOptionList
          | UNNotificationPresentationOptionBanner
    In module 'UserNotifications' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/include/FLTFirebaseMessagingPlu
    gin.h:15:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UserNotif
    ications.framework/Headers/UNUserNotificationCenter.h:84:5: note:
    'UNNotificationPresentationOptionAlert' has been explicitly marked
    deprecated here
       84 |     UNNotificationPresentationOptionAlert
       API_DEPRECATED_WITH_REPLACEMENT("UNNotificationPresentationOptionList |
       UNNotificationPresentationOptionBanner", macos(10.14, 11.0), ios(10.0,
       14.0), watchos(3.0, 7.0), tvos(10.0, 14.0)) = (1 << 2),
          |     ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:36
    2:10: warning: @available does not guard availability here; use if
    (@available) instead [-Wunsupported-availability-guard]
      362 |     if (!@available(iOS 18.1, *)) {
          |          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:40
    2:10: warning: @available does not guard availability here; use if
    (@available) instead [-Wunsupported-availability-guard]
      402 |     if (!@available(iOS 18.1, *)) {
          |          ^
    3 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImagePickerController.swift:265:45:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
                targetVC = UIApplication.shared.keyWindow!.rootViewController!
                                                ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImagePickerController.swift:281:34:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
                UIApplication.shared.keyWindow!.rootViewController!.dismiss(anim
                ated: true,
                                     ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKPopoverViewController.swift:30:43:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
            let window = UIApplication.shared.keyWindow!
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKPopoverViewController.swift:43:43:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
            let window = UIApplication.shared.keyWindow!
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/View/DKAssetGroupDetailVC.swift:344:1
    4: warning: 'frameInterval' was deprecated in iOS 10.0:
    preferredFramesPerSecond
            link.frameInterval = 1
                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKPopoverViewController.swift:30:43:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
            let window = UIApplication.shared.keyWindow!
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKPopoverViewController.swift:43:43:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
            let window = UIApplication.shared.keyWindow!
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImageDataManager/DKImageDataManager.swift:154:43: warning:
    'requestImageData(for:options:resultHandler:)' was deprecated in iOS 13
            let imageRequestID = self.manager.requestImageData(
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImagePickerController.swift:265:45:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
                targetVC = UIApplication.shared.keyWindow!.rootViewController!
                                                ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImagePickerController.swift:281:34:
    warning: 'keyWindow' was deprecated in iOS 13.0: Should not be used for
    applications that support multiple scenes as it returns a key window across
    all connected scenes
                UIApplication.shared.keyWindow!.rootViewController!.dismiss(anim
                ated: true,
                                     ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImageAssetExporter.swift:557:38:
    warning: capture of 'fileManager' with non-Sendable type 'FileManager' in an
    isolated local function; this is an error in the Swift 6 language mode
                                    try? fileManager.removeItem(at:
                                    auxiliaryDirectory)
                                         ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/Foundatio
    n.framework/Headers/NSFileManager.h:96:12: note: class 'FileManager' does
    not conform to the 'Sendable' protocol
    @interface NSFileManager : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_core-4.4.0/ios/firebas
    e_core/Sources/firebase_core/FLTFirebaseCorePlugin.m:92:35: warning:
    incompatible pointer types assigning to 'NSString * _Nullable' from 'NSNull
    * _Nonnull' [-Wincompatible-pointer-types]
       92 |   pigeonOptions.deepLinkURLScheme = [NSNull null];
          |                                   ^ ~~~~~~~~~~~~~
    1 warning generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/Extensions/DKImageExtensionGallery.swift:35:38: warning:
    'keyWindow' was deprecated in iOS 13.0: Should not be used for applications
    that support multiple scenes as it returns a key window across all connected
    scenes
                    UIApplication.shared.keyWindow!.rootViewController!.present(
                    photoGallery: gallery)
                                         ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/DKImageAssetExporter.swift:557:38:
    warning: capture of 'fileManager' with non-Sendable type 'FileManager' in an
    isolated local function; this is an error in the Swift 6 language mode
                                    try? fileManager.removeItem(at:
                                    auxiliaryDirectory)
                                         ^
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/Foundatio
    n.framework/Headers/NSFileManager.h:96:12: note: class 'FileManager' does
    not conform to the 'Sendable' protocol
    @interface NSFileManager : NSObject
               ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:38
    7:32: warning: 'UNNotificationPresentationOptionAlert' is deprecated: first
    deprecated in iOS 14.0 [-Wdeprecated-declarations]
      387 |         presentationOptions |=
      UNNotificationPresentationOptionAlert;
          |                                ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |                                UNNotificationPresentationOptionList
          | UNNotificationPresentationOptionBanner
    In module 'UserNotifications' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/include/FLTFirebaseMessagingPlu
    gin.h:15:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UserNotif
    ications.framework/Headers/UNUserNotificationCenter.h:84:5: note:
    'UNNotificationPresentationOptionAlert' has been explicitly marked
    deprecated here
       84 |     UNNotificationPresentationOptionAlert
       API_DEPRECATED_WITH_REPLACEMENT("UNNotificationPresentationOptionList |
       UNNotificationPresentationOptionBanner", macos(10.14, 11.0), ios(10.0,
       14.0), watchos(3.0, 7.0), tvos(10.0, 14.0)) = (1 << 2),
          |     ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:36
    2:10: warning: @available does not guard availability here; use if
    (@available) instead [-Wunsupported-availability-guard]
      362 |     if (!@available(iOS 18.1, *)) {
          |          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_messaging-16.1.1/ios/f
    irebase_messaging/Sources/firebase_messaging/FLTFirebaseMessagingPlugin.m:40
    2:10: warning: @available does not guard availability here; use if
    (@available) instead [-Wunsupported-availability-guard]
      402 |     if (!@available(iOS 18.1, *)) {
          |          ^
    3 warnings generated.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImagePickerController/View/DKAssetGroupDetailVC.swift:344:1
    4: warning: 'frameInterval' was deprecated in iOS 10.0:
    preferredFramesPerSecond
            link.frameInterval = 1
                 ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/DKImageDataManager/DKImageDataManager.swift:154:43: warning:
    'requestImageData(for:options:resultHandler:)' was deprecated in iOS 13
            let imageRequestID = self.manager.requestImageData(
                                              ^
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/DKImagePickerCont
    roller/Sources/Extensions/DKImageExtensionGallery.swift:35:38: warning:
    'keyWindow' was deprecated in iOS 13.0: Should not be used for applications
    that support multiple scenes as it returns a key window across all connected
    scenes
                    UIApplication.shared.keyWindow!.rootViewController!.present(
                    photoGallery: gallery)
                                         ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/firebase_core-4.4.0/ios/firebas
    e_core/Sources/firebase_core/FLTFirebaseCorePlugin.m:92:35: warning:
    incompatible pointer types assigning to 'NSString * _Nullable' from 'NSNull
    * _Nonnull' [-Wincompatible-pointer-types]
       92 |   pigeonOptions.deepLinkURLScheme = [NSNull null];
          |                                   ^ ~~~~~~~~~~~~~
    1 warning generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FileUtils.m:52:31: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
       52 |             CFStringRef UTI =
       UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)[format pathExtension], NULL);
          |                               ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FileUtils.h:7:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FileUtils.m:52:69: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
       52 |             CFStringRef UTI =
       UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)[format pathExtension], NULL);
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FileUtils.h:7:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    2 warnings generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FileUtils.m:52:31: warning:
    'UTTypeCreatePreferredIdentifierForTag' is deprecated: first deprecated in
    iOS 15.0 - Use the UTType class instead. [-Wdeprecated-declarations]
       52 |             CFStringRef UTI =
       UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)[format pathExtension], NULL);
          |                               ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FileUtils.h:7:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:317:1: note:
    'UTTypeCreatePreferredIdentifierForTag' has been explicitly marked
    deprecated here
      317 | UTTypeCreatePreferredIdentifierForTag(
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FileUtils.m:52:69: warning:
    'kUTTagClassFilenameExtension' is deprecated: first deprecated in iOS 15.0 -
    Use UTTagClassFilenameExtension instead. [-Wdeprecated-declarations]
       52 |             CFStringRef UTI =
       UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
       (__bridge CFStringRef)[format pathExtension], NULL);
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FileUtils.h:7:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTType.h:258:26: note: 'kUTTagClassFilenameExtension'
    has been explicitly marked deprecated here
      258 | extern const CFStringRef kUTTagClassFilenameExtension
      API_DEPRECATED("Use UTTagClassFilenameExtension instead.", ios(3.0, 15.0),
      macos(10.3, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    2 warnings generated.
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:57:68: warning: 'windows' is
    deprecated: first deprecated in iOS 15.0 - Use UIWindowScene.windows on a
    relevant window scene instead [-Wdeprecated-declarations]
       57 |         for (UIWindow *window in [UIApplication
       sharedApplication].windows) {
          |                                                                    ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:109:62: note: 'windows' has been explicitly
    marked deprecated here
      109 | @property(nonatomic,readonly) NSArray<__kindof UIWindow *>  *windows
      API_DEPRECATED("Use UIWindowScene.windows on a relevant window scene
      instead", ios(2.0, 15.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:199:112: warning:
    'UIDocumentPickerModeExportToService' is deprecated: first deprecated in iOS
    14.0 - Use appropriate initializers instead [-Wdeprecated-declarations]
      199 |     self.documentPickerController = [[UIDocumentPickerViewController
      alloc] initWithURL:destinationPath
      inMode:UIDocumentPickerModeExportToService];
          |
          ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:199:77: warning:
    'initWithURL:inMode:' is deprecated: first deprecated in iOS 14.0
    [-Wdeprecated-declarations]
      199 |     self.documentPickerController = [[UIDocumentPickerViewController
      alloc] initWithURL:destinationPath
      inMode:UIDocumentPickerModeExportToService];
          |
          ^~~~~~~~~~~
          |
          use initForExportingURLs:asCopy: or initForExportingURLs: instead
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:53:1: note:
    'initWithURL:inMode:' has been explicitly marked deprecated here
       53 | - (instancetype)initWithURL:(NSURL *)url
       inMode:(UIDocumentPickerMode)mode NS_DESIGNATED_INITIALIZER
       API_DEPRECATED_WITH_REPLACEMENT("use initForExportingURLs:asCopy: or
       initForExportingURLs: instead", ios(8.0, 14.0), visionos(1.0, 1.0))
       API_UNAVAILABLE(tvos, watchos);
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:217:64: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      217 |                                          inMode: isDirectory ?
      UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
          |                                                                ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:217:91: warning:
    'UIDocumentPickerModeImport' is deprecated: first deprecated in iOS 14.0 -
    Use appropriate initializers instead [-Wdeprecated-declarations]
      217 |                                          inMode: isDirectory ?
      UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
          |
          ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:216:42: warning:
    'initWithDocumentTypes:inMode:' is deprecated: first deprecated in iOS 14.0
    [-Wdeprecated-declarations]
      216 |                                          initWithDocumentTypes:
      isDirectory ? @[@"public.folder"] : self.allowedExtensions
          |                                          ^~~~~~~~~~~~~~~~~~~~~
          |                                          use
          initForOpeningContentTypes:asCopy: or initForOpeningContentTypes:
          instead
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:41:1: note:
    'initWithDocumentTypes:inMode:' has been explicitly marked deprecated here
       41 | - (instancetype)initWithDocumentTypes:(NSArray <NSString
       *>*)allowedUTIs inMode:(UIDocumentPickerMode)mode
       NS_DESIGNATED_INITIALIZER API_DEPRECATED_WITH_REPLACEMENT("use
       initForOpeningContentTypes:asCopy: or initForOpeningContentTypes:
       instead", ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(tvos,
       watchos);
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:52: warning: 'kUTTypeMovie' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeMovie or UTType.movie
    (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |                                                    ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:880:26: note: 'kUTTypeMovie' has been
    explicitly marked deprecated here
      880 | extern const CFStringRef kUTTypeMovie
      API_DEPRECATED("Use UTTypeMovie or UTType.movie (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:77: warning: 'kUTTypeAVIMovie'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeAVI or UTType.avi
    (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:892:26: note: 'kUTTypeAVIMovie' has been
    explicitly marked deprecated here
      892 | extern const CFStringRef kUTTypeAVIMovie
      API_DEPRECATED("Use UTTypeAVI or UTType.avi (swift) instead.", ios(8.0,
      15.0), macos(10.10, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:105: warning: 'kUTTypeVideo'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeVideo or
    UTType.video (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:881:26: note: 'kUTTypeVideo' has been
    explicitly marked deprecated here
      881 | extern const CFStringRef kUTTypeVideo
      API_DEPRECATED("Use UTTypeVideo or UTType.video (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:130: warning: 'kUTTypeMPEG4'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeMPEG4Movie or
    UTType.mpeg4 (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:888:26: note: 'kUTTypeMPEG4' has been
    explicitly marked deprecated here
      888 | extern const CFStringRef kUTTypeMPEG4
      API_DEPRECATED("Use UTTypeMPEG4Movie or UTType.mpeg4 (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:261:53: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
      261 |     NSArray<NSString*> * imageTypes = @[(NSString *)kUTTypeImage];
          |                                                     ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:293:106: warning:
    'UIActivityIndicatorViewStyleWhite' is deprecated: first deprecated in iOS
    13.0 [-Wdeprecated-declarations]
      293 |     UIActivityIndicatorView* indicator = [[UIActivityIndicatorView
      alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
          |
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |
          UIActivityIndicatorViewStyleMedium
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIActivityIndicatorView.h:19:5: note:
    'UIActivityIndicatorViewStyleWhite' has been explicitly marked deprecated
    here
       19 |     UIActivityIndicatorViewStyleWhite
       API_DEPRECATED_WITH_REPLACEMENT("UIActivityIndicatorViewStyleMedium",
       ios(2.0, 13.0), tvos(9.0, 13.0)) API_UNAVAILABLE(visionos, watchos) = 1,
          |     ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:408:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      408 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:408:41: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      408 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:409:17: warning: incompatible
    pointer types assigning to 'NSMutableArray<NSURL *> *' from 'NSArray<NSURL
    *> *' [-Wincompatible-pointer-types]
      409 |         newUrls = urls;
          |                 ^ ~~~~
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:411:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      411 |     if(controller.documentPickerMode == UIDocumentPickerModeImport)
      {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:411:41: warning:
    'UIDocumentPickerModeImport' is deprecated: first deprecated in iOS 14.0 -
    Use appropriate initializers instead [-Wdeprecated-declarations]
      411 |     if(controller.documentPickerMode == UIDocumentPickerModeImport)
      {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:438:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      438 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:438:41: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      438 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    19 warnings generated.
    ld: warning: ignoring duplicate libraries: '-lc++'
    ld: warning: ignoring duplicate libraries: '-lc++'
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:57:68: warning: 'windows' is
    deprecated: first deprecated in iOS 15.0 - Use UIWindowScene.windows on a
    relevant window scene instead [-Wdeprecated-declarations]
       57 |         for (UIWindow *window in [UIApplication
       sharedApplication].windows) {
          |                                                                    ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIApplication.h:109:62: note: 'windows' has been explicitly
    marked deprecated here
      109 | @property(nonatomic,readonly) NSArray<__kindof UIWindow *>  *windows
      API_DEPRECATED("Use UIWindowScene.windows on a relevant window scene
      instead", ios(2.0, 15.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:199:112: warning:
    'UIDocumentPickerModeExportToService' is deprecated: first deprecated in iOS
    14.0 - Use appropriate initializers instead [-Wdeprecated-declarations]
      199 |     self.documentPickerController = [[UIDocumentPickerViewController
      alloc] initWithURL:destinationPath
      inMode:UIDocumentPickerModeExportToService];
          |
          ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:199:77: warning:
    'initWithURL:inMode:' is deprecated: first deprecated in iOS 14.0
    [-Wdeprecated-declarations]
      199 |     self.documentPickerController = [[UIDocumentPickerViewController
      alloc] initWithURL:destinationPath
      inMode:UIDocumentPickerModeExportToService];
          |
          ^~~~~~~~~~~
          |
          use initForExportingURLs:asCopy: or initForExportingURLs: instead
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:53:1: note:
    'initWithURL:inMode:' has been explicitly marked deprecated here
       53 | - (instancetype)initWithURL:(NSURL *)url
       inMode:(UIDocumentPickerMode)mode NS_DESIGNATED_INITIALIZER
       API_DEPRECATED_WITH_REPLACEMENT("use initForExportingURLs:asCopy: or
       initForExportingURLs: instead", ios(8.0, 14.0), visionos(1.0, 1.0))
       API_UNAVAILABLE(tvos, watchos);
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:217:64: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      217 |                                          inMode: isDirectory ?
      UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
          |                                                                ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:217:91: warning:
    'UIDocumentPickerModeImport' is deprecated: first deprecated in iOS 14.0 -
    Use appropriate initializers instead [-Wdeprecated-declarations]
      217 |                                          inMode: isDirectory ?
      UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
          |
          ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:216:42: warning:
    'initWithDocumentTypes:inMode:' is deprecated: first deprecated in iOS 14.0
    [-Wdeprecated-declarations]
      216 |                                          initWithDocumentTypes:
      isDirectory ? @[@"public.folder"] : self.allowedExtensions
          |                                          ^~~~~~~~~~~~~~~~~~~~~
          |                                          use
          initForOpeningContentTypes:asCopy: or initForOpeningContentTypes:
          instead
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:41:1: note:
    'initWithDocumentTypes:inMode:' has been explicitly marked deprecated here
       41 | - (instancetype)initWithDocumentTypes:(NSArray <NSString
       *>*)allowedUTIs inMode:(UIDocumentPickerMode)mode
       NS_DESIGNATED_INITIALIZER API_DEPRECATED_WITH_REPLACEMENT("use
       initForOpeningContentTypes:asCopy: or initForOpeningContentTypes:
       instead", ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(tvos,
       watchos);
          | ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:52: warning: 'kUTTypeMovie' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeMovie or UTType.movie
    (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |                                                    ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:880:26: note: 'kUTTypeMovie' has been
    explicitly marked deprecated here
      880 | extern const CFStringRef kUTTypeMovie
      API_DEPRECATED("Use UTTypeMovie or UTType.movie (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:77: warning: 'kUTTypeAVIMovie'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeAVI or UTType.avi
    (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:892:26: note: 'kUTTypeAVIMovie' has been
    explicitly marked deprecated here
      892 | extern const CFStringRef kUTTypeAVIMovie
      API_DEPRECATED("Use UTTypeAVI or UTType.avi (swift) instead.", ios(8.0,
      15.0), macos(10.10, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:105: warning: 'kUTTypeVideo'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeVideo or
    UTType.video (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:881:26: note: 'kUTTypeVideo' has been
    explicitly marked deprecated here
      881 | extern const CFStringRef kUTTypeVideo
      API_DEPRECATED("Use UTTypeVideo or UTType.video (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:260:130: warning: 'kUTTypeMPEG4'
    is deprecated: first deprecated in iOS 15.0 - Use UTTypeMPEG4Movie or
    UTType.mpeg4 (swift) instead. [-Wdeprecated-declarations]
      260 |     NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie,
      (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo,
      (NSString*)kUTTypeMPEG4];
          |
          ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:888:26: note: 'kUTTypeMPEG4' has been
    explicitly marked deprecated here
      888 | extern const CFStringRef kUTTypeMPEG4
      API_DEPRECATED("Use UTTypeMPEG4Movie or UTType.mpeg4 (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:261:53: warning: 'kUTTypeImage' is
    deprecated: first deprecated in iOS 15.0 - Use UTTypeImage or UTType.image
    (swift) instead. [-Wdeprecated-declarations]
      261 |     NSArray<NSString*> * imageTypes = @[(NSString *)kUTTypeImage];
          |                                                     ^
    In module 'MobileCoreServices' imported from
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/include/file_picker/FilePickerPlugin.h:5:
    In module 'CoreServices' imported from
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/MobileCoreSer
    vices.framework/Headers/MobileCoreServices.h:9:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/CoreServi
    ces.framework/Headers/UTCoreTypes.h:725:26: note: 'kUTTypeImage' has been
    explicitly marked deprecated here
      725 | extern const CFStringRef kUTTypeImage
      API_DEPRECATED("Use UTTypeImage or UTType.image (swift) instead.",
      ios(3.0, 15.0), macos(10.4, 12.0), tvos(9.0, 15.0), watchos(1.0, 8.0));
          |                          ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:293:106: warning:
    'UIActivityIndicatorViewStyleWhite' is deprecated: first deprecated in iOS
    13.0 [-Wdeprecated-declarations]
      293 |     UIActivityIndicatorView* indicator = [[UIActivityIndicatorView
      alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
          |
          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          |
          UIActivityIndicatorViewStyleMedium
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIActivityIndicatorView.h:19:5: note:
    'UIActivityIndicatorViewStyleWhite' has been explicitly marked deprecated
    here
       19 |     UIActivityIndicatorViewStyleWhite
       API_DEPRECATED_WITH_REPLACEMENT("UIActivityIndicatorViewStyleMedium",
       ios(2.0, 13.0), tvos(9.0, 13.0)) API_UNAVAILABLE(visionos, watchos) = 1,
          |     ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:408:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      408 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:408:41: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      408 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:409:17: warning: incompatible
    pointer types assigning to 'NSMutableArray<NSURL *> *' from 'NSArray<NSURL
    *> *' [-Wincompatible-pointer-types]
      409 |         newUrls = urls;
          |                 ^ ~~~~
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:411:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      411 |     if(controller.documentPickerMode == UIDocumentPickerModeImport)
      {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:411:41: warning:
    'UIDocumentPickerModeImport' is deprecated: first deprecated in iOS 14.0 -
    Use appropriate initializers instead [-Wdeprecated-declarations]
      411 |     if(controller.documentPickerMode == UIDocumentPickerModeImport)
      {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:438:19: warning:
    'documentPickerMode' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      438 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                   ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:66:62: note:
    'documentPickerMode' has been explicitly marked deprecated here
       66 | @property (nonatomic, assign, readonly) UIDocumentPickerMode
       documentPickerMode API_DEPRECATED("Use appropriate initializers instead",
       ios(8.0, 14.0), visionos(1.0, 1.0)) API_UNAVAILABLE(watchos);
          |                                                              ^
    /Users/shahdhruvil/.pub-cache/hosted/pub.dev/file_picker-8.3.7/ios/file_pick
    er/Sources/file_picker/FilePickerPlugin.m:438:41: warning:
    'UIDocumentPickerModeOpen' is deprecated: first deprecated in iOS 14.0 - Use
    appropriate initializers instead [-Wdeprecated-declarations]
      438 |     if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
          |                                         ^
    In module 'UIKit' imported from
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/ios/Pods/Target Support
    Files/file_picker/file_picker-prefix.pch:2:
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platfor
    m/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/UIKit.fra
    mework/Headers/UIDocumentPickerViewController.h:30:29: note:
    'UIDocumentPickerMode' has been explicitly marked deprecated here
       30 | typedef NS_ENUM(NSUInteger, UIDocumentPickerMode) {
          |                             ^
    19 warnings generated.
    Target debug_ios_bundle_flutter_assets failed: Exception: Failed to codesign
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/build/ios/Debug-iphonesimu
    lator/App.framework/App with identity -.
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/build/ios/Debug-iphonesimu
    lator/App.framework/App: replacing existing signature
    /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi/build/ios/Debug-iphonesimu
    lator/App.framework/App: resource fork, Finder information, or similar
    detritus not allowed
    Failed to package /Users/shahdhruvil/Documents/Project/FE-V2-Vayuxi.
    Command PhaseScriptExecution failed with a nonzero exit code
    note: Run script build phase 'Thin Binary' will be run during every build
    because the option to run the script phase "Based on dependency analysis" is
    unchecked. (in target 'Runner' from project 'Runner')
    note: Run script build phase 'Run Script' will be run during every build
    because the option to run the script phase "Based on dependency analysis" is
    unchecked. (in target 'Runner' from project 'Runner')

Could not build the application for the simulator.
Error launching application on iPhone 16e.
shahdhruvil@Shahs-Mac-mini FE-V2-Vayuxi % 
