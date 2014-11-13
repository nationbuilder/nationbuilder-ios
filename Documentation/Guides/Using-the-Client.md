# Using the Client

The client layer of the SDK is the lowest layer, containing the bare essentials,
mainly NBClient and NBAuthenticator. You can use this layer by itself if this
fits your use case. However, it is more common to use the higher-level [accounts
layer][]. Read on to learn more about what NBClient and NBAuthenticator can do.

## NBClient

The base layer of the SDK is NBClient. In order for the client to do anything
with a nation, it needs: 1. the nation slug, and 2. a valid API key (access
token).

```objectivec
#import <NBClient/NBClient.h>
// ...
NSString *nationSlug = @"abeforprez";
NSString *testToken = @"somehash";
NBClient *client = [[NBClient alloc] initWithNationSlug:nationSlug
                                                 apiKey:testToken
                                          customBaseURL:nil
                                       customURLSession:nil
                          customURLSessionConfiguration:nil]];
```

The above will create a valid client that has its own NSURLSession. With it, you
can now fetch data from the nation through predefined methods that correspond
with API endpoints. All client methods for API endpoints accept completion
handlers that will get passed: 1. the data as one or many items (if any), 2. the
pagination info (if relevant), and 3. the error (if any).

```objectivec
// Continuing.
[client 
 fetchPeopleWithPaginationInfo:nil
 completionHandler:^(NSArray *items, NBPaginationInfo *paginationInfo, NSError *error) {
     if (error) {
         // Handle the error inside the completion block as you see fit.
         return;
     }
     NBLog(@"The first page of people: %@", items);
}];
```

However, note that you should only use a test (predefined) token when you don't
mind all of your apps users sharing one token, as in your app is private or the
token is being 'securely' stored. Even then, we advise to use the authenticator
and require your users to: 1. authenticate with NationBuilder and 2. authorize
access for your app.

## NBAuthenticator

Unless using a predefined token, you'll need to authenticate with the
NationBuilder API via OAuth 2. NBAuthenticator simplifies the process. It
supports the token and password-grant-type flows.

The token flow is the suggested approach, where the authentication requires
visiting the nation in Safari. The password-grant-type flow is discouraged and
only intended if your app is to be used by only your own nation.

The authenticator needs to know the OAuth Client ID for your NationBuilder app.
Like the client, it will also need the nation slug in the form of the base URL.

```objectivec
#import <NBAuthenticator/NBAuthenticator.h>
#import <NBClient/NBClient.h>
// ...
NSString *nationSlug = @"abeforprez";
NSString *clientIdentifier = @"somehash";
NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:NBClientDefaultBaseURLFormat, nationSlug]];
NBAuthenticator *authenticator = [[NBAuthenticator alloc] initWithBaseURL:baseURL
                                                         clientIdentifier:clientIdentifier];
// Now we can create the client.
NBClient *client = [[NBClient alloc] initWithNationSlug:nationSlug
                                          authenticator:authenticator
                                       customURLSession:nil
                          customURLSessionConfiguration:nil]];
```

You will also need to add your NationBuilder app's redirect URI to your application info plist:

1. Under `URL types` add an item with `URL identifier` as
`com.nationbuilder.oauth` (`NBAuthenticationRedirectURLIdentifier`).

2. Also under `URL types` add an array `URL Schemes` with an item that is the
protocol of your redirect URI and identifies URLs only your app should be able
to open. For example, the redirect URI `sample-app.nationbuilder://oauth/callback`
has the protocol `sample-app.nationbuilder`.

Now to authenticate you'll need to provide the authenticator with the redirect
path and a completion handler that will get passed: 1. the credential object (if
any), and 2. the error (if any):

```objectivec
// Continuing.
NSString *redirectPath = @"oauth/callback"; // See example redirect URI.
[authenticator
 authenticateWithRedirectPath:redirectPath
 priorSignout:NO // Sign out of current session in Safari. Only needed for account-switching.
 completionHandler:^(NBAuthenticationCredential *credential, NSError *error) {
     if (error) {
         // Handle the error inside the completion block as you see fit.
         return;
     }
     client.apiKey = credential.accessToken;
     // Client is now ready.
}];
```

And update your app delegate allow the authenticator to handle Safari's request
for the app to open the redirect URI.

```objectivec
// Continuing.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // At this point the user has signed in on Safari and authorized the app.
    // They may have only confirmed to open the redirect URI if they're already 
    // signed in and app has already been authorized.
    NSError *error;
    [NBAuthenticator finishAuthenticatingInWebBrowserWithURL:url error:&error];
    // At this point, if there's been no error, then the authenticator has called
    // the completion handler.
    if (error) {
        // Handle the error inside the completion block as you see fit.
    }
    // You should return NO regardless of whether or not the authentication
    // succeeded. There's a system-level bug that prevents your app from opening
    // the same URL after a previous successful opening.
    return NO;
}
```

By default NBAuthenticator will save any credentials to the device user's
keychain using its `credentialIdentifier` as identifier. You can opt out from
this behavior by turning off `shouldPersistCredential`.

## NBClientDelegate

NBClient has a delegate protocol that your classes can implement to get
additional control over default client functionality:

```objectivec
// Continuing.
@interface MYAppDelegate () <NBClientDelegate>
// ...
client.delegate = self;
```

### Custom Error Handling

NBClient by default checks for errors and generates NSError objects: 1. errors
from data task or JSON parsing failures, 2. API errors with non-successful http
status codes, 3. API errors with successful http status codes. 

The delegate protocol's `-client:shouldHandleResponse:forRequest:*` methods
allow you to halt default response handling at most errors. By default, these
methods, if implemented, should return `YES`. For example, the accounts layer
uses the `withHTTPError` variant to automatically sign out of the account that
has the client:

```objectivec
// Continuing.
- (BOOL)client:(NBClient *)client shouldHandleResponse:(NSHTTPURLResponse *)response
                                            forRequest:(NSURLRequest *)request
                                         withHTTPError:(NSError *)error
{
    // Check the request if needed. Here, we want this to apply to all requests.
    if (response.statusCode == 401 && client.apiKey) {
        NBLogInfo(@"Account reported as unauthorized, access token: %@", client.apiKey);
        // Tear down the account and prevent the default response handling of calling
        // the original completion handler (ie. one that displays the error)...
        return NO;
    }
    return YES;
}
```

### Custom Data Handling

NBClient will look for predefined keys in the JSON data and return the value as
either `item` or `items`. The key varies with the client method. For example,
person methods use the `person` key, while people methods use the `results` key.
If the key is not found, or if the error `code` and `message` are found, an
error is returned instead. Consult the specific [API documentation][] section
for details.

For instance, in the event the API has changed to return additional data, and
the SDK hasn't updated the client to look for these fields, you can get this
additional data via the delegate protocol's
`-client:didParseJSON:fromResponse:forRequest:`.

### Custom Request Handling

NBClient will build NSMutableURLRequests with a timeout of 10s and the protocol
cache policy (except fetch requests that use
`NSURLRequestReloadRevalidatingCacheData`). It will also set the request headers
per API requirements.

The NSURLSessionDataTasks created from these requests are subsequently started.
If you don't want the tasks to start automatically, instead of suspending the
task when the client method returns it, just implement
`-client:shouldAutomaticallyStartDataTask:` to return `NO`.

Also, for instance, in the event the API has changed to accept additional headers, and
the SDK hasn't updated the client to include these headers when needed, you can
add these headers via the delegate protocol's
`-client:willCreateDataTaskForRequest:`

## Notes

### Pagination

(TODO: Overview of pagination info.)

### NSURLSession

NBClient's NSURLSession defaults to using `+defaultSessionConfiguration`, but
with a custom NSURLCache with 4mb memory and 20mb disk capacities, stored at the
`<nationSlug>.nationbuilder.com` application subdirectory. You can override the
session or the configuration by passing during initialization either a
`customURLSession` or `customURLSessionConfiguration`, respectively.

### NBLogging

Both NBClient and NBAuthenticator implement `NBLogging` (see `NBDefines.h`),
which means they support the log levels defined in `NBLogLevel`. For example,
the default debug-build-configuration log level is `NBLogLevelInfo`, but for
NBClient you might want to set the class log level to `NBLogLevelWarning`
(`[NBClient updateLoggingToLevel:NBLogLevelWarning]`), so it doesn't log each
request and response.

### NSError

Both NBClient and NBAuthenticator have their own error codes for many of the
errors passed into their methods' completion handlers. All errors originating
from SDK code is under the `NBErrorDomain` domain.

### More

For more details on how to integrate with your existing application, check the
source for the NBClientExample sample application.

__[Next: Using Accounts ➔](Using-Accounts.md)__

[accounts layer]: Using-Accounts.md
[API Documentation]: http://nationbuilder.com/api_documentation
