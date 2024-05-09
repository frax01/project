---
title: Design Document
subtitle: Tiber App - Design and Implementation of Mobile Applications 2023/2024
author:
  - Juan Pedro Gálvez López
  - Francesco Martignoni
toc: true
date: 2024-06-10
---
# Introduction

## Purpose

The main purpose of this document is the correct and complete requirement and design specification for the Tiber App for its future implementation, as well as the description of the testing plan to verify its correct functioning.

The Tiber App is designed as a companion app for the Tiber Club, a Rome-based soccer school and family association. Its main purpose is informing children and parents about the different activities organized by the association, as well as providing a leaderboard for children to compete, based on their performance in the soccer matches played by the club.

## Goals of the project

|             |                                                                                                                         |
| ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| **[PG-01]** | Provide an easy to use and informative channel to inform parents and children of the activities organized in Tiber Club |
| **[PG-02]** | Provide a leaderboard in which children participating in the soccer school can compete based on their performance       |
| **[PG-03]** | Provide a easy way of sharing the activities organized with people that might be interested in participating            |
| **[PG-04]** | Send timely and relevant notifications to inform of the activities organized in Tiber Club                              |

## Scope

The scope of the Tiber App project encompasses the specification, development, implementation and testing of a mobile app tailored for the Tiber Club to accomplish the goals described in the previous section.

To this end, the project's core functionalities will include extensive user management and fine-grained permissions, an event system to manage activities, a leaderboard system and integration with APIs services for location and weather information.

## Definitions, acronyms and abbreviations

- *Activity*:
- 
- *API*: Application Programming Interface, a set of functions and procedures that allow the creation of applications that access the features or data of an operating system, application, or other service.

## Document structure

1. ***Introduction***: it aims to describe the environment of this project and its application domains. In particular, it focuses on the system characteristics and the goals that are going to be achieved with its development.
2. ***Overall description***: a high-level description of the system by focusing on the different scenarios that a user may go through during their interaction with the application, the functions the application must perform, the characteristics of the users, and the assumptions, dependencies and constraints that the application must respect.
3. ***Requirement specification***: a complete and formal specification of all requirements the application must comply with, as well as the design constraints and software system attributes.
4. ***Design specification***: a formal description of the architectural elements and patterns that will be used in the implementation of the application
5. ***Implementation and test plan***: a description of the technology and software choices selected to develop the application, as well as a comprehensive plan for its implementation and testing
6. ***References***: a list of reference documents used in the redaction of this document

## Revision history

| Ver. | Rev. | Date | Comment         |
| ---- | ---- | ---- | --------------- |
| 1    | 0    |      | Initial version |

# Overall description

This section contains a high-level description of the application, based on the needs of the stakeholders. It describes the application as a series of scenarios that capture the functionality the users expect of the app, captures the functions the application will need to perform, analyzes the different types of users of the application and lists the assumptions, dependencies and constraints that need to be respected by the system.

## User characteristics

The system has four types of users, that correspond to the different roles within the Tiber Club:

- **Member (Ragazzo)**: a kid participating in activities organized by Tiber Club. They are associated with an specific "level" which corresponds to their class level in school (1º to 3º Media and 1º to 5º Liceo). They should only be able to read the information and activities of their level.
- **Parent (Genitore)**: a parent of one or more kids participating in activities organized by Tiber Club. They can be associated with more than one level to be able to see activities for all their kids, if they have more than one. They should still only be able to read the information.
- **Tutor**: an organizer of activities in Tiber Club. The can be associated with more than one level if they manage activities for those levels. They can add, edit and delete content in the app.
- **Administrator**: the administrator of the application. Can approve or deny new accounts. It is independent from the other three types, meaning any of the other three types may also be administrator.

## Scenarios

### [SC-01] A member wants to be updated on all activities organized

Francesco is a kid currently attending 1º Liceo and a member of Tiber Club. He can open the app and see all the activities programmed for his level. For each activity, he can see the title of the activity, a picture, the type (a weekend plan, a trip, or an extra activity), the date or dates, the location, the levels that can participate in that activity and a description detailing the activity.

### [SC-02] A parent wants to be updated on all activities organized

Alice is a mother of two kids, both members of Tiber Club. None of them have a phone yet. She can open the app and see the activities organized for both her kids, with the same details as a kid. She can share this information with her kids, or lend them the phone so they can see the plans themselves. With this information she can also plan the week and the trips she has to make so the kids can attend the activities.

### [SC-03] An user of the app wants to invite a friend to an activity in Tiber Club

Francesco wants to invite one of his school friends to a soccer match organized in Tiber Club. He can easily share the details of the activity through Whatsapp or other messaging platforms by using the share button in the activity details screen, which will compose a small text with everything important and present the system share sheet so it can be shared.

### [SC-04] A tutor wants to create a new activity

Mario is a tutor at Tiber Club. He wants to create a new activity for the level he manages. He can go into the app and press the "Create activity" button. He will choose between the three different types of activities (a weekend plan, a trip, or an extra activity), and add a title, a description, a picture, a location (optional) and a date or dates (depending on the type of activity he chooses), as well as the levels that can participate in this activity.

### [SC-05] A tutor wants to modify an activity

Mario created an activity at an specific venue, but the venue was not available for that day and time, so he finds a new venue and makes a reservation there instead. He can then go into the app and edit the details of the activity, specifically the location, to reflect the changes.

### [SC-06] A tutor wants to cancel an activity

Michele is a tutor at Tiber Club. He organized a trekking activity, but due to the weather he needs to cancel it. He can to to the app, select that activity and easily cancel it. It will disappear from the members and parents apps.

### [SC-07] A member or a parent wants to be notified of new activities

Vittorio is a kid currently attending 2º Liceo. He wants to be notified of the activities that happen in Tiber Club so he can be informed. He can activate notifications, accepting them through the system dialog when he opens the app for the first time, and he will be notified when a new activity for his level is created. 

### [SC-08] A member or a parent wants to be notified when an activity is modified or cancelled

Enrico is a father of three kids, all members of Tiber Club. He has a difficult schedule and needs to be notified when activities his kids want to attend to get modified or cancelled. He can activate notifications, accepting them through the system dialog when he opens the app for the first time, and he will be notified instantly when an activity in the levels of his kids is modified or cancelled so he can modify his schedule accordingly.

### [SC-09] An user of the app wants to know the weather for a particular activity

Vittorio wants to go to a trip to Milano organized by Tiber Club. When packing for the trip, he does not know whether he should bring an umbrella. He can open the app and go to the trip activity screen, and see the weather in Milano for the days of the trip, and so he can see that he should definitely bring the umbrella because in Milano it is always rainy.

### [SC-10] A member wants to see their position in the rankings

Francesco has been participating in all soccer matches organized by Tiber Club. The tutors have been counting his goals and points and entering them in the app. He can go into the ranking screen of the app and see his position in relation to all the other members of Tiber Club.

### [SC-11] A tutor wants to add a person to the rankings

Michele has organized a soccer match and three new kids have come. He can add them to the rankings with the goals they scored, independently of whether they have an account in the app or not, since not all of them have a phone.

### [SC-12] A tutor wants to add goals and points to a person in the rankings

Francesco has scored three goals in the soccer match, and Michele wants to add them to Francesco's count in the app. He can open the app, go to the ranking screen, and add goals to Francesco's score.

### [SC-13] A new member wants to join the app

Giovanni is a member of Tiber Club, and has just received his first phone for his birthday. He wants to join the app, so he downloads it and creates a new account with his personal details. He is greeted with a waiting screen until his account is approved by an administrator. Once he is approved, he can use the app normally.

### [SC-14] An administrator wants to screen new users

Gabriele is the director of Tiber Club. He wants to let into the app only the members and parents of Tiber Club, and to stop external people from joining the app without being members. He can open the user screening page in the app and see new accounts created. He will also receive a notification when a new account is created. He can check the details of the account, give them the necessary roles, add them to the levels the pertain to, and accept them. He can also reject users, impeding them from accessing the information in the app.

### [SC-15] An user of the app wants to eliminate their account

Paolo has finished 5º Liceo and will not be a member of Tiber Club next year. He can delete his account from the profile page of the app, and uninstall it. A tutor can also delete Paolo from the ranking.

## Functions

From the set of scenarios described above, a set of functions the app must perform can be distilled:

| Code        | Function                                                  | Comments                                                                      |
| ----------- | --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **[FN-01]** | Creating account                                          | Account will not be usable until approved                                     |
| **[FN-02]** | Deleting account                                          | -                                                                             |
| **[FN-03]** | Screening created accounts                                | In the approval process the role and levels are added                         |
| **[FN-04]** | Notifying of account creation                             | Only to administrators                                                        |
| **[FN-05]** | Displaying activities                                     | -                                                                             |
| **[FN-05]** | Adding activities                                         | Only by tutors                                                                |
| **[FN-06]** | Modifying activities                                      | Only by tutors                                                                |
| **[FN-07]** | Deleting activities                                       | Only by tutors                                                                |
| **[FN-08]** | Displaying weather in activities                          | If the activity is more than one day long, display the average weather        |
| **[FN-09]** | Sharing activities                                        | Using system dialog for greater compatibility                                 |
| **[FN-10]** | Notifying of activity creation, modification and deletion | Only to the people of the level of the activity                               |
| **[FN-11]** | Displaying ranking                                        | -                                                                             |
| **[FN-12]** | Adding people to ranking                                  | Only by tutors, independent of whether the person added has an account or not |
| **[FN-13]** | Modifying goals and points of people in rankings          | Only by tutors                                                                |
| **[FN-14]** | Deleting people from rakings                              | Only by tutors                                                                |

## Assumptions, dependencies and constraints

### Assumptions

In this section, we outline the foundational beliefs upon which the design and functionality of the Tiber App are based. These assumptions serve as guiding principles for understanding user behavior, technological capabilities, and organizational dynamics that shape the app's development and usage.

|             |                                                                                                          |
| ----------- | -------------------------------------------------------------------------------------------------------- |
| **[AS-01]** | The user has access to the Internet                                                                      |
| **[AS-02]** | The user has a device capable of running the app                                                         |
| **[AS-03]** | Users are interested in staying updated about the activities of the Tiber Club                           |
| **[AS-04]** | Parents are actively involved in managing their children's participation in the soccer school            |
| **[AS-05]** | Members are motivated to compete and improve their soccer skills through the app's leaderboard           |
| **[AS-06]** | The Tiber Club has a sufficient number of soccer matches and activities to keep the app content relevant |
| **[AS-07]** | The app will be primarily used by families associated with the Tiber Club                                |

### Dependencies

This section identifies the external factors and systems upon which the successful operation of the Tiber App relies. By understanding these dependencies, we can prioritize integration efforts and ensure seamless communication between the app and other essential components of the Tiber Club's ecosystem.

|             |                                                                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **[DP-01]** | Access to a database or API to retrieve and update activities and leaderboard data                                                         |
| **[DP-02]** | Collaboration with the Tiber Club's administration to ensure accurate and timely communication of club-related information through the app |
| **[DP-03]** | Compatibility with various mobile operating systems (iOS, Android) to reach a wide audience of users                                       |
| **[DP-04]** | Availability of resources (time, budget, personnel) for app development, maintenance, and support                                          |

### Constraints

In this section we acknowledge the limitations and boundaries that influence the design, implementation, and operation of the Tiber App. These constraints encompass technical, regulatory, and practical considerations that must be navigated to deliver a functional and compliant mobile solution aligned with the goals of the Tiber Club and its community.

|             |                                                                                                                                                                        |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[CN-01]** | Limited screen space on mobile devices may constrain the design and layout of the app's user interface                                                                 |
| **[CN-02]** | Privacy and security concerns regarding the collection and storage of personal information, especially for children using the app                                      |
| **[CN-03]** | Adherence to regulatory requirements, such as GDPR                                                                                                                     |
| **[CN-04]** | The need for regular updates and maintenance to ensure the app remains functional and relevant amidst evolving technology and user expectations                        |
| **[CN-05]** | The app's performance may be affected by factors such as network latency or device hardware limitations, particularly in areas with poor connectivity or older devices |

# Requirement specification

## Functional requirements


## Interface requirements


### Hardware interfaces


### Software interfaces


### Communication interfaces


## Performance requirements


## Design constraints


## Software system attributes


### Reliability


### Availability


### Security


### Maintainability


### Portability


# Design specification


## Overview


## Component view


## Deployment view


## Data model


## Selected architectural styles and patterns


## Interface design


# Implementation and test plan

## Platforms, languages, libraries and frameworks

### Database


### Languages and frameworks


### Authentication



## Implementation plan


## Test plan


# References

- 