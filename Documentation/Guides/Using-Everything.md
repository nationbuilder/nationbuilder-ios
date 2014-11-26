# Using Everything

On this page you'll find resources and summaries to further clarify the SDK on a
larger scale.

## NationBuilder API Coverage

|     API Endpoint     |                         NBClient Method                          |
|----------------------|------------------------------------------------------------------|
| GET `/people`        | `-fetchPeopleWithPaginationInfo:completionHandler:`              |
| GET `/people/search` | `-fetchPeopleByParameters:withPaginationInfo:completionHandler:` |
| GET `/people/:id`    | `-fetchPersonByIdentifier:completionHandler:`                    |
| GET `/people/match`  | `-fetchPersonByParameters:completionHandler:`                    |
| GET `/people/me`     | `-fetchPersonForClientUserWithCompletionHandler:`                |
| POST `/people`       | `-createPersonWithParameters:completionHandler:`                 |
| PUT `/people/:id`    | `-savePersonByIdentifier:withParameters:completionHandler:`      |
| DELETE `/people/:id` | `-deletePersonByIdentifier:withCompletionHandler:`               |

__Note:__ Many more methods are coming soon. Feel free to [contribute][] some yourself.

## Implementation Checklist

This is the standard checklist for getting your app integrated with the current
SDK.

- [ ] Install the desired NationBuilder app for your nation, ex: `NBClientExample`

- [ ] Add the SDK to your Podfile
  - [ ] Fetch and import the SDK (`NBClient/Main.h`, `NBClient/UI.h`)

- [ ] Update your app's info plist
  - [ ] Add the `Fonts provided by application` item if using the UI component
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
