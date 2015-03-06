# Using Everything

On this page you'll find resources and summaries to further clarify the SDK on a
larger scale.

## NationBuilder API Coverage

|            API Endpoint            |                                                                NBClient Method                                                                |
|------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| GET `/people`                      | `-fetchPeopleWithPaginationInfo:completionHandler:`                                                                                           |
| GET `/people/:id`                  | `-fetchPersonByIdentifier:completionHandler:`                                                                                                 |
| GET `/people/search`               | `-fetchPeopleByParameters:withPaginationInfo:completionHandler:`                                                                              |
| GET `/people/nearby`               | `-fetchPeopleNearbyByLocationInfo:withPaginationInfo:completionHandler:`                                                                      |
| GET `/people/me`                   | `-fetchPersonForClientUserWithCompletionHandler:`                                                                                             |
| GET `/people/:id/register`         | `-registerPersonByIdentifier:withCompletionHandler:`                                                                                          |
| GET `/people/match`                | `-fetchPersonByParameters:completionHandler:`                                                                                                 |
| GET `/people/:id/taggings`         | `-fetchPersonTaggingsByIdentifier:withCompletionHandler:`                                                                                     |
| PUT `/people/:id/taggings`         | `-createPersonTaggingByIdentifier:withTaggingInfo:completionHandler:`, `-createPersonTaggingsByIdentifier:withTaggingInfo:completionHandler:` |
| DELETE `/people/:id/taggings/:tag` | `-deletePersonTaggingsByIdentifier:tagNames:withCompletionHandler:`                                                                           |
| GET `/people/:id/capitals`         | `-fetchPersonCapitalsByIdentifier:withPaginationInfo:completionHandler:`                                                                      |
| POST `/people/:id/capitals`        | `-createPersonCapitalByIdentifier:withCapitalInfo:completionHandler:`                                                                         |
| DELETE `/people/:id/capitals/:id`  | `-deletePersonCapitalByPersonIdentifier:capitalIdentifier:withCompletionHandler:`                                                             |
| POST `/people`                     | `-createPersonWithParameters:completionHandler:`                                                                                              |
| PUT `/people/:id`                  | `-savePersonByIdentifier:withParameters:completionHandler:`                                                                                   |
| DELETE `/people/:id`               | `-deletePersonByIdentifier:withCompletionHandler:`                                                                                            |

__Note:__ Many more methods are coming soon. Feel free to [contribute][] some yourself.

## Implementation Checklist

This is the standard checklist for getting your app integrated with the current
SDK.

Follow the [installation guide][]:

- [ ] Install the desired NationBuilder app for your nation, ex: `NBClientExample`

- [ ] Add the SDK to your Podfile
  - [ ] Fetch and import the SDK (`NBClient/Main.h`, `NBClient/UI.h`)

- [ ] Update your app's info plist
  - [ ] Add the `Fonts provided by application` item if using the UI component

Follow the [accounts usage guide][]:

- [ ] Update your app's info plist
  - [ ] Add the `URL types`/0/`URL identifier` as `com.nationbuilder.oauth`
  - [ ] Add the `URL types`/0/`URL Schemes`/0 as the path for the NationBuilder 
        app's redirect URI

- [ ] Create and populate `NationBuilder-Info.plist`

- [ ] Create an `NBAccountButton`
  - [ ] Link it to the accounts manager
  - [ ] Add it to your view controller

- [ ] Create an `NBAccountsManager`
  - [ ] Implement `NBAccountsManagerDelegate`

- [ ] Create an `NBAccountsViewController`
  - [ ] Link it to the accounts manager

__[Next: Contact & Contributing Info ➔][contribute]__

[contribute]: ../../CONTRIBUTING.md
[installation guide]: Installing.md
[accounts usage guide]: Using-Accounts.md
