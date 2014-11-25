# NationBuilder iOS SDK 

[![CI Status](http://img.shields.io/travis/3dna/nationbuilder-ios.svg?style=flat)](https://travis-ci.org/3dna/nationbuilder-ios)
[![Version](https://img.shields.io/cocoapods/v/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![License](https://img.shields.io/cocoapods/l/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)
[![Platform](https://img.shields.io/cocoapods/p/NBClient.svg?style=flat)](http://cocoadocs.org/docsets/NBClient)

## Usage

To try out the sample app, follow these steps.

1. Make sure you clone this repo and download Xcode. You'll eventually need to
run and build the NBClientExample project.

2. Open `NBClient.workspace` and build the `NBClientExample` scheme. 

3. Using the NationBuilder Control Panel, go to `Settings` > `Apps` > `Install
new app install`. Install the `NBClientExample` app for your nation.

4. Build and open the app `NB Sample` in the iOS Simulator.

5. In the app, click the signin button on the top left. Provide your nation's slug. In
Safari, sign into your account on your nation and authorize the app.

Refer to the [documentation section][] on how to use the SDK to build your app.

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

Detailed guides and code samples are at NationBuilder [iOS developer
documentation][]. Or, if you prefer reading on Github or want to contribute
edits, the [guides][Github guides] are also available on Github.

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

## Credits

The NBClient/UI component uses the [Stroke 7 Icon Font Set by Pixeden][icon font].

[documentation section]: #documentation
[CocoaPods]: http://cocoapods.org
[iOS developer documentation]: #TODO
[Github guides]: Documentation/Guides
[icon font]: http://pixeden.com/icon-fonts/stroke-7-icon-font-set
