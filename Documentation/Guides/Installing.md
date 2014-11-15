# Installing

Installing using [CocoaPods][] is recommended. If you need help with other
installation methods, or if you're using Swift, we suggest referring to the
[developer forum][]. For CocoaPods, add to your [Podfile][]:

```ruby
pod 'NBClient', '~> 1.0.0'
```

## Importing

To start quickly using the entire SDK, you can import the main header files in
your app's precompile header (`*.pch`) file. (If your app has many classes, you
should consider only importing the headers for classes that require them.)

```objc
#import <NBClient/Main.h>
#import <NBClient/UI.h>
```

`NBClient/Main.h` gives you access to the core SDK: client, authenticator,
account, accounts manager, additions and defines.

`NBClient/UI.h` gives you access to the UI widgets: account button, accounts
modal and popover, additions. If you want to use the UI, you will also need to
add our icon font to your application info plist: under `Fonts provided by
application` add an item with the value `pe-icon-7-stroke.ttf`

(TODO: Submodules, resources.)

## Notes

When installing the pod, be aware the SDK supports iOS 7. Our current policy is
to not support iOS 8 features (size classes) if it means breaking backwards
compatibility with iOS 7.

The Foundation and UIKit additions we provide in the SDK are prefixed with
`nb_`, so rest assured there won't be conflicts if you don't use that prefix.

__[Next: Using the Client ➔](Using-the-Client.md)__

[CocoaPods]: http://cocoapods.org
[Podfile]: http://guides.cocoapods.org/syntax/podfile
[developer forum]: http://nationbuilder.com/api_developer_forum
