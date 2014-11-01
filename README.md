# NationBuilder iOS SDK 

[![CI Status](http://img.shields.io/travis/3dna/nationbuilder-ios.svg?style=flat)](https://travis-ci.org/3dna/nationbuilder-ios)
[![Version](https://img.shields.io/cocoapods/v/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![License](https://img.shields.io/cocoapods/l/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![Platform](https://img.shields.io/cocoapods/p/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)

## Usage

To run the NBClientExample project, open the NBClient workspace and build the
NBClientExample scheme. You will need to 1) install the NBClientTests app for
your nation and 2) sign into and authorize with your nation's account. Refer to
the NationBuilder [iOS developer documentation][] for code samples.

## Requirements

The SDK requires iOS 7 and above. All included UI components (the accounts
component, the sample app) are universal, supporting both iPhone and iPad.

## Installation

NBClient is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NBClient'
```

Refer to the NationBuilder [iOS developer documentation][] for a detailed
getting-started guide.

## License

NBClient is available under the MIT license. See the LICENSE file for more info.

## Testing

```bash
# Install dependencies:
~> gem install -N xcpretty
~> sudo gem install -N cocoapods
nationbuilder-ios> pod install

# Run unit tests against sandbox:
nationbuilder-ios> rake test
```

[iOS developer documentation]: http://nationbuilder.com/developers
