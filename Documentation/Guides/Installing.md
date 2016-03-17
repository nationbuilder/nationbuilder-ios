# Installing

Installing using [CocoaPods][] is recommended. If you need help with other
installation methods, or if you're using Swift, we suggest referring to the
[developer forum][] if the general iOS community fails to help.

For CocoaPods, add to your [Podfile][]:

```ruby
pod 'NBClient', '~> 1.3.0'
```

Note that we [semantically version](http://semver.org) the SDK, so patch
versions should never break existing code.

## Importing

To start quickly using the entire SDK, you can import the main header files in
your app's precompile header (`*.pch`) file. (If your app has many classes, you
should consider only importing the headers for classes that require them.)

```objc
#import <NBClient/Main.h>
#import <NBClient/UI.h>
```

`NBClient/Main.h` gives you access to the Core component: client, authenticator,
account, accounts manager, additions and defines.

`NBClient/UI.h` gives you access to the UI component. They are the account
button, the accounts modal and popover, and UIKit additions.

### Selectively

You can pick which components to add to your workspace. You may want this to
avoid importing parts of the SDK you will not use. By default, CocoaPods adds
the `NBClient/Core`, `NBClient/UI`, and `NBClient/Locale/en` components
(subspecs) into your workspace. For example, to just include the Core, but also
include the (soon to be) French Locale component:

```ruby
pod 'NBClient/Core', '~> 1.3.0'
pod 'NBClient/Locale/fr', '~> 1.3.0'
```

You can refer to the subspecs in [NBClient.podspec][] to see the components and
their dependencies. We recommend using the default components when first getting
started.

### Fonts

If you want to use the UI widgets, you will also need to add our icon font to
your application info plist. Under `Fonts provided by application`, add an item
with the value `pe-icon-7-stroke.ttf`.

## Notes

### Namespacing

The Foundation and UIKit additions we provide in the SDK are prefixed with
`nb_`, so rest assured there won't be conflicts if you don't use that prefix in
your own additions.

__[Next: Using the Client ➔](Using-the-Client.md)__

[CocoaPods]: http://cocoapods.org
[Podfile]: http://guides.cocoapods.org/syntax/podfile
[NBClient.podspec]: ../../NBClient.podspec
[developer forum]: http://nationbuilder.com/api_developer_forum
