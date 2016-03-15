//
//  NBClientSurveysTests.m
//  NBClient
//
//  Copyright (MIT) 2014-present NationBuilder
//

#import "NBTestCase.h"

#import "FoundationAdditions.h"

#import "NBClient.h"
#import "NBClient+Surveys.h"
#import "NBPaginationInfo.h"

@interface NBClientSurveysTests : NBTestCase

@property (nonatomic) NSUInteger surveyIdentifier;
@property (nonatomic) NSUInteger surveyWithResponsesIdentifier;
@property (nonatomic) NSDictionary *paginationParameters;

- (void)assertSurveysArray:(NSArray *)array;
- (void)assertSurveyDictionary:(NSDictionary *)dictionary;

- (void)assertSurveyResponsesArray:(NSArray *)array;
- (void)assertSurveyResponseDictionary:(NSDictionary *)dictionary;

@end

@implementation NBClientSurveysTests

- (void)setUp
{
    [super setUp];
    [self setUpSharedClient];
    self.surveyIdentifier = 5;
    self.surveyWithResponsesIdentifier = 1;
    self.paginationParameters = @{ NBClientPaginationLimitKey: @5, NBClientPaginationTokenOptInKey: @1 };
}

#pragma mark - (Site) Surveys

#pragma mark Helpers

- (void)assertSurveysArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of surveys.");
    for (NSDictionary *dictionary in array) { [self assertSurveyDictionary:dictionary]; }
}

- (void)assertSurveyDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"tags", @"slug", @"path", @"status", @"name", @"site_slug", @"questions" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Survey has correct attributes.");
}

#pragma mark Tests

- (void)testFetchSurveysBySiteSlug
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"GET" pathFormat:@"sites/:slug/pages/surveys" pathVariables:@{ @"slug": self.nationSlug } queryParameters:self.paginationParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchSurveysBySiteSlug:self.nationSlug
     withPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertSurveysArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreateSurveyBySiteSlug
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"POST" pathFormat:@"sites/:slug/pages/surveys" pathVariables:@{ @"slug": self.nationSlug } queryParameters:nil];
    // NOTE: This is more for documentation. The stored response won't check parameters.
    NSDictionary *parameters = @{ @"slug": @"survey_temp", @"name": @"Survey (temp)", @"status": @"unlisted", @"questions": @[ @{ @"prompt": @"Important issue?", @"slug": @"important_issue_temp", @"type": @"multiple", @"status": @"unlisted", @"choices": @[ @{ @"name": @"foo" }, @{ @"name": @"bar" } ] } ] };
    NSURLSessionDataTask *task =
    [self.client createSurveyBySiteSlug:self.nationSlug withParameters:parameters completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertSurveyDictionary:item];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testSaveSurveyBySiteSlug
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"PUT" pathFormat:@"sites/:slug/pages/surveys/:id" pathVariables:@{ @"slug": self.nationSlug, @"id": @(self.surveyIdentifier) } queryParameters:nil];
    // NOTE: This is more for documentation. The stored response won't check parameters.
    NSDictionary *parameters = @{ @"slug": @"survey_temp", @"name": @"Survey (temp)", @"status": @"unlisted", @"questions": @[] };
    NSURLSessionDataTask *task =
    [self.client saveSurveyBySiteSlug:self.nationSlug identifier:self.surveyIdentifier withParameters:parameters completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertSurveyDictionary:item];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testDeleteSurveyBySiteSlug
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"DELETE" pathFormat:@"sites/:slug/pages/surveys/:id" pathVariables:@{ @"slug": self.nationSlug, @"id": @(self.surveyIdentifier) } queryParameters:nil];
    NSURLSessionDataTask *task =
    [self.client deleteSurveyBySiteSlug:self.nationSlug identifier:self.surveyIdentifier completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        XCTAssertNil(item, @"Survey dictionary should not exist.");
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

#pragma mark - Survey Responses

#pragma mark Helpers

- (void)assertSurveyResponsesArray:(NSArray *)array
{
    XCTAssertNotNil(array, @"Client should have received list of survey responses.");
    for (NSDictionary *dictionary in array) { [self assertSurveyResponseDictionary:dictionary]; }
}

- (void)assertSurveyResponseDictionary:(NSDictionary *)dictionary
{
    static NSArray *keys; static dispatch_once_t onceToken; dispatch_once(&onceToken, ^{
        keys = @[ @"id", @"survey_id", @"person_id", @"is_private", @"question_responses", @"created_at" ];
    });
    return XCTAssertTrue([dictionary nb_hasKeys:keys], "Survey response has correct attributes.");
}

#pragma mark Tests

- (void)testFetchSurveyResponses
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    NSMutableDictionary *mutableParameters = self.paginationParameters.mutableCopy;
    mutableParameters[@"survey_id"] = @(self.surveyWithResponsesIdentifier);
    [self stubRequestUsingFileDataWithMethod:@"GET" path:@"survey_responses" queryParameters:mutableParameters];
    NSURLSessionDataTask *task =
    [self.client
     fetchSurveyResponseByIdentifier:self.surveyWithResponsesIdentifier parameters:nil
     withPaginationInfo:[[NBPaginationInfo alloc] initWithDictionary:self.paginationParameters legacy:NO]
     completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
         [self assertServiceError:error];
         [self assertSurveyResponsesArray:items];
         [self assertPaginationInfo:paginationInfo withPaginationParameters:self.paginationParameters];
         [self completeAsync];
     }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

- (void)testCreateSurveyResponse
{
    if (!self.shouldUseHTTPStubbing) { return NBLog(@"SKIPPING"); }
    [self setUpAsync];
    [self stubRequestUsingFileDataWithMethod:@"POST" path:@"survey_responses" queryParameters:nil];
    // NOTE: This is more for documentation. The stored response won't check parameters.
    NSDictionary *parameters = @{ NBClientSurveyResponderIdentifierKey: @(self.supporterIdentifier),
                                  NBClientSurveyResponsesKey: @[ @{
                                    NBClientSurveyQuestionIdentifierKey: @1,
                                    NBClientSurveyQuestionResponseIdentifierKey: @1 } ] };
    NSURLSessionDataTask *task =
    [self.client createSurveyResponseByIdentifier:self.surveyWithResponsesIdentifier withParameters:parameters completionHandler:^(NSDictionary *item, NSError *error) {
        [self assertServiceError:error];
        [self assertSurveyResponseDictionary:item];
        [self completeAsync];
    }];
    [self assertSessionDataTask:task];
    [self tearDownAsync];
}

@end
