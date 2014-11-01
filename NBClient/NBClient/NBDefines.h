//
//  NBDefines.h
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Constants

extern NSString * const NBErrorDomain;
extern NSUInteger const NBErrorCodeInvalidArgument;

// Names for a dedicated NationBuilder Info.plist file, which is the suggested
// method for storing relevant configuration.
extern NSString * const NBInfoFileName;
extern NSString * const NBInfoBaseURLFormatKey;
extern NSString * const NBInfoClientIdentifierKey;
extern NSString * const NBInfoNationNameKey;
extern NSString * const NBInfoRedirectPathKey;
extern NSString * const NBInfoTestTokenKey;

// Storing the client secret is discouraged for apps not built by NationBuilder.
extern NSString * const NBInfoClientSecretKey;

// To use our icon font you must add 'pe-icon-7-stroke' to 'Fonts provided by
// application' in your Info.plist.
extern NSString * const NBIconFontFamilyName;

// Completion handlers are always called.
typedef void (^NBGenericCompletionHandler)(NSError *error);

#pragma mark - Logging

// Class(file)-based log levels give you more control over what library log messages
// show up.
typedef NS_ENUM(NSUInteger, NBLogLevel) {
    NBLogLevelNone,
    NBLogLevelError,
    NBLogLevelWarning,
    NBLogLevelInfo,
    NBLogLevelDebug,
};
// But they only work for classes that implement this protocol and allow you to
// change the log level. The common implementation uses a static var inside the
// implementation file to persist the log level for all class instances.
@protocol NBLogging <NSObject>

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel;

@end
// This library uses the NBLog preprocessor macro for improved logging during development.
#if DEBUG
#   define NBLog(fmt, ...) NSLog((@"%s [%@:%d]\n> " fmt @"\n\n"), __PRETTY_FUNCTION__, @(__FILE__).lastPathComponent, __LINE__, ##__VA_ARGS__)
#else
#   define NBLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#endif
// NBLog is used in the form of these log-level-driven logging convenience macros.
#define NBLogError(fmt, ...)    if (LogLevel >= NBLogLevelError)    NBLog(@"ERROR: " fmt, ##__VA_ARGS__)
#define NBLogWarning(fmt, ...)  if (LogLevel >= NBLogLevelWarning)  NBLog(@"WARNING: " fmt, ##__VA_ARGS__)
#define NBLogInfo(fmt, ...)     if (LogLevel >= NBLogLevelInfo)     NBLog(@"INFO: " fmt, ##__VA_ARGS__)
#define NBLogDebug(fmt, ...)    if (LogLevel >= NBLogLevelDebug)    NBLog(@"DEBUG: " fmt, ##__VA_ARGS__)

#pragma mark - Protocols

@protocol NBDictionarySerializing <NSObject>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (BOOL)isEqualToDictionary:(NSDictionary *)dictionary;

@end