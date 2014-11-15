# NationBuilder iOS SDK 

[![CI Status](http://img.shields.io/travis/3dna/nationbuilder-ios.svg?style=flat)](https://travis-ci.org/3dna/nationbuilder-ios)
[![Version](https://img.shields.io/cocoapods/v/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![License](https://img.shields.io/cocoapods/l/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![Platform](https://img.shields.io/cocoapods/p/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)

## Usage

To try out the sample app, run the NBClientExample project: 

1. Open the NBClient workspace and build the NBClientExample scheme. 
2. Through the Control Panel, install the NBClientTests app for your nation.
3. Sign into your account on your nation and authorize the app. 

## Installation

NBClient is available through [CocoaPods][]. To install it, simply add the
following line to your Podfile:

```ruby
pod 'NBClient', '~> 1.0.0'
```

## Requirements

The SDK requires iOS 7 and above. All included UI components (the accounts
component, the sample app) are universal, supporting both iPhone and iPad.

## Documentation

Refer to the NationBuilder [iOS developer documentation][] for a detailed
getting-started guide that includes code samples. Alternatively, if you prefer
reading on Github or want to contribute edits, the [guides are also available on
Github][Github guides].

## Testing

```bash
# Install dependencies:
~> gem install -N xcpretty
~> sudo gem install -N cocoapods
nationbuilder-ios> pod install

# Run unit tests against recorded production data:
nationbuilder-ios> rake test
```

## License

NBClient is available under the MIT license. See the LICENSE file for more info.

[CocoaPods]: http://cocoapods.org
[iOS developer documentation]: #TODO
[Github guides]: Documentation/Guides
