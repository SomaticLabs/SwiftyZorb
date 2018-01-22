# SwiftyZorb

*iOS development kit for integrating with the [Somatic Zorb Engine](https://somaticlabs.io)*

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/SomaticLabs/SwiftyZorb/blob/master/LICENSE)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@SomaticLabs-orange.svg?style=flat)](http://twitter.com/SomaticLabs)

## About

SwiftyZorb allows developers to build iOS applications that communicate with devices powered by Somatic Labs' Zorb Engine, enabling new user experiences that allow communication entirely through your sense of touch.

This library is made to be used in conjuction with our embedded Javascript SDK. To get started developing your own haptic animations, check out our [Zorb Design Studio](https://zorbtouch.com)..

Animations and programs created in the design studio can be ran on ZorbEngine powered devices using this library, either by sending a embedding the Javascript directly in your application or by storing your scripts somewhere with a publicly accessible URL (such as in a Github gist) that can be referenced from within your application.

For a quick reference to the SwiftyZorb documents, please refer to [this guide](https://somaticlabs.github.io/SwiftyZorb).

## Requirements

- iOS 9.0+
- Xcode 8.1+
- Swift 4.0+

## Troubleshooting & Contributions

- If you **need help**, [send us an email](mailto:developers@somaticlabs.io).
- If you'd like to **ask a general question**, [send us an email](mailto:developers@somaticlabs.io).
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

To integrate SwiftyZorb into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "SomaticLabs/SwiftyZorb" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `SwiftyZorb.framework` into your Xcode project.

You must also drag the built dependencies `Alamofire.framework`, `SwiftyBluetooth.framework`, and `SwiftyJSON.framework` into your project.

## Usage

There are two ways to use this libary. If you intend FIXME

### Connecting

Before being able to communicate with Moment, you must establish a Bluetooth LE connection with your device.

```swift
import SwiftyZorb

SwiftyZorb.connect { result in
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
SwiftyZorb.disconnect()
```

After connecting to a device for the first time, the SwiftyZorb saves a reference to that device for quicker reconnection in the future. If you would like to connect to a new device, you must forget the old connection.

```swift
SwiftyZorb.forget()
```

Note that simply disconnecting from the device will not forget a stored connection and, likewise, forgetting a connection will not force a disconnect.

### Sending Javascript

There are two ways to send Javascript to Moment to be executed on the device—by embedding it as a `String` in your application, or by passing a `URL` to a hosted file such as a [Github Gist](https://gist.github.com) that contains your code.

To send Javascript from a `String` in your application:

```swift
let javascript = "Moment.on('timertick', function () {" +
    "var ms = Moment.uptime();" +
    "// do something time-related here" +
    "});"
SwiftyZorb.writeJavascript(javascript) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
}
```

To send Javascript from a script saved in file hosted online:

```swift
let url = URL(string: "https://gist.github.com/shantanubala/1f7d0dfb9bbef3edca8d0bb164c56aa0/raw")!
SwiftyZorb.writeJavascript(at url) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
}
```

Using the two above methods will always require an HTTP request to the MomentSDK Javascript compiler, which produces the Javascript bytecode that is executed on Moment's internal virtual machine. If you would like to avoid this HTTP request, you can send pre-compiled bytecode instead.

To send pre-compiled Javascript bytecode as a base64 encoded `String` in your application:

 ```swift
let bytecode = "BgAAAFAAAAAsAAAAAQAAAAQAAQABAAUAAAEDBAYAAQACAAYAOwABKQIDxEYBAAAABAABACEAAwABAgMDAAAGAAgAOwECt8gARgAAAAAAAAAFAAAAAAAAAAIAb24JAHRpbWVydGljawABAHQABgBNb21lbnQGAHVwdGltZQ=="
SwiftyZorb.writeBytecode(bytecode) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
}
 ```

To reset Moment's Javascript virtual machine:

```swift
SwiftyZorb.reset { result in
    switch result {
    case .success:
        // Reset succeeded
    case .failure(let error):
        // An error occurred during reset
    }
}
```

## Style Guide

Contributions to this project should conform to the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and [this style guide](https://github.com/github/swift-style-guide).

## License

The SwiftyZorb is released under the [MIT license](https://github.com/SomaticLabs/SwiftyZorb/blob/master/LICENSE).
