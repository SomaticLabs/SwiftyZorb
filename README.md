![Moment Logo](https://github.com/SomaticLabs/SwiftMomentSDK/raw/master/images/moment.png)

# SwiftMomentSDK

*iOS development kit for [Moment](https://wearmoment.com)*

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/SomaticLabs/SwiftMomentSDK/blob/master/LICENSE)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@SomaticLabs-orange.svg?style=flat)](http://twitter.com/SomaticLabs)

## About

The SwiftMomentSDK allows developers to build iOS applications that communicate with Moment, the first wearable that communicates entirely through your sense of touch. 

This library is made to be used in conjuction with our [embedded Javascript SDK](https://github.com/somaticlabs/moment-sdk).

To get started developing your own haptic animations, check out our [Moment simulator](https://somaticlabs.github.io/moment-sim/).

![Moment Simulator](https://github.com/SomaticLabs/SwiftMomentSDK/raw/master/images/sim.png)

Animations and programs created in the simulator can be ran on Moment using this library, either by sending a embedding the Javascript directly in your application or by storing your scripts in [Github Gists](https://gist.github.com) and referencing those in your applications. 

For more information regarding using the Moment Javascript SDK, please refer to our [documentation](https://somaticlabs.github.io/moment-sdk/).

## Requirements

- iOS 9.0+
- Xcode 8.1+
- Swift 3.0+

## Troubleshooting & Contributions

- If you **need help**, use our [discussion forum](https://talk.wearmoment.com) or [send us an email](mailto:developers@somaticlabs.io).
- If you'd like to **ask a general question**, use our [discussion forum](https://talk.wearmoment.com) or [send us an email](mailto:developers@somaticlabs.io).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate SwiftMomentSDK into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "SomaticLabs/SwiftMomentSDK" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `SwiftMomentSDK.framework` into your Xcode project.

You must also drag the built dependencies `Alamofire.framework` and `SwiftyBluetooth.framework` into your project.

## Usage

### Connecting

Before being able to communicate with Moment, you must establish a Bluetooth LE connection with your device.

```swift 
import SwiftMomentSDK

SwiftMomentSDK.connect { result in
  switch result {
  case .success:
    // Connected succeeded
  case .failure(let error):
    // An error occurred during connection
  }
}
```

If you would like to trigger a manual disconnect, you can do so like this:

```swift
SwiftMomentSDK.disconnect()
```

After connecting to a device for the first time, the SwiftMomentSDK saves a reference to that device for quicker reconnection in the future. If you would like to connect to a new device, you must forget the old connection.

```swift
SwiftMomentSDK.forget()
```

Note that simply disconnecting from the device will not forget a stored connection and, likewise, forgetting a connection will not force a disconnect.

### Sending Javascript

There are two ways to send Javascript to Moment to be executed on the device—by embedding it as a `String` in your application, or by passing a `URL` to a [Github Gist](https://gist.github.com) that contains your code.

Additionally, the SwiftMomentSDK provides the option to optimize your Javascript using the [Google Closure Compiler](https://developers.google.com/closure/compiler/) before sending it to Moment. This is valuable because it highly compresses the number of bytes that need to be sent to Moment over BLE, dramatically decreasing the transmission time. This is especially important for longer scripts. 

By default optimization is turned on, but this can be overridden if your Javascript is already optimized and you would like to prevent the additional HTTP request.

To send Javascript from a script saved in a Gist:

```swift
let url = URL(string: "https://gist.github.com/jakerockland/1de44467c3eaf132a2089b6c88d680b8")!
SwiftMomentSDK.writeScript(at url) { result in
  switch result {
  case .success:
    // Write succeeded
  case .failure(let error):
    // An error occurred during write
  }
}
```

To send Javascript from a `String` in your application:

```swift
let javascript = "Moment.LED.setColor(Moment.Color.ORANGE);"
SwiftMomentSDK.writeContents(of javascript, optimize: false) { result in
  switch result {
  case .success:
    // Write succeeded
  case .failure(let error):
    // An error occurred during write
  }
}
```

## License

The SwiftMomentSDK is released under the [MIT license](https://github.com/SomaticLabs/SwiftMomentSDK/blob/master/LICENSE).
