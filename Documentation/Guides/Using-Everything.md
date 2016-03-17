# Using Everything

On this page you'll find resources and summaries to further clarify the SDK on a
larger scale.

## NationBuilder API Coverage

| NBClient Addition |               API Endpoint              |
|-------------------|-----------------------------------------|
| People            | GET `/people`                           |
|                   | GET `/people/:id`                       |
|                   | GET `/people/search`                    |
|                   | GET `/people/nearby`                    |
|                   | GET `/people/me`                        |
|                   | GET `/people/:id/register`              |
|                   | GET `/people/match`                     |
|                   | GET `/people/:id/taggings`              |
|                   | PUT `/people/:id/taggings`              |
|                   | DELETE `/people/:id/taggings/:tag`      |
|                   | GET `/people/:id/capitals`              |
|                   | POST `/people/:id/capitals`             |
|                   | DELETE `/people/:id/capitals/:id`       |
|                   | POST `/people`                          |
|                   | PUT `/people/:id`                       |
|                   | DELETE `/people/:id`                    |
| Contacts          | GET `/people/:person_id/contacts`       |
|                   | POST `/people/:person_id/contacts`      |
|                   | GET `/settings/contact_types`           |
|                   | GET `/settings/contact_methods`         |
|                   | GET `/settings/contact_statuses`        |
| Donations         | GET `/donations`                        |
|                   | POST `/donations`                       |
|                   | PUT `/donation/:id`                     |
|                   | DELETE `/donation/:id`                  |
| Lists             | GET `/lists`                            |
|                   | GET `/lists/:id/people`                 |
|                   | POST `/lists/:id/people`                |
|                   | DELETE `/lists/:id/people`              |
| Sites             | GET `/sites`                            |
| Surveys           | GET `/sites/:slug/pages/surveys`        |
|                   | POST `/sites/:slug/pages/surveys`       |
|                   | PUT `/sites/:slug/pages/surveys/:id`    |
|                   | DELETE `/sites/:slug/pages/surveys/:id` |
|                   | GET `/survey_responses`                 |
|                   | POST `/survey_responses`                |
| Tags              | GET `/tags`                             |
|                   | GET `/tags/:id/people`                  |

Feel free to [contribute][] some yourself.

## Implementation Checklist

This is the standard checklist for getting your app integrated with the current
SDK.

Follow the [installation guide][]:

- Install the desired NationBuilder app for your nation, ex: `NBClientExample`

- Add the SDK to your Podfile
  - Fetch and import the SDK (`NBClient/Main.h`, `NBClient/UI.h`)

- Update your app's info plist
  - \(Optional\) add the `Fonts provided by application` item if using the UI component

Follow the [accounts usage guide][]:

- Update your app's info plist
  - Add the `URL types/0/URL identifier` as `com.nationbuilder.oauth`
  - Add the `URL types/0/URL Schemes/0` as the path for the NationBuilder 
    app's redirect URI

- Create and populate `NationBuilder-Info.plist`

- Create an `NBAccountButton`
  - Link it to the accounts manager
  - Add it to your view controller

- Create an `NBAccountsManager`
  - Implement `NBAccountsManagerDelegate`

- Create an `NBAccountsViewController`
  - Link it to the accounts manager

__[Next: Contact & Contributing Info ➔][contribute]__

[contribute]: ../../CONTRIBUTING.md
[installation guide]: Installing.md
[accounts usage guide]: Using-Accounts.md
