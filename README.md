# SequisTestIOS

Simple Image Browser application assignment built with SwiftUI using MVVM and Clean Architecture.

## Objective

The goal of this assignment is to create an iOS application that allows users to browse a list of images in a simple, clean, and responsive interface.

## Tech Stack

- SwiftUI for the user interface
- MVVM for presentation logic
- Clean Architecture for separation of concerns
- Swift Concurrency with `async/await`
- Unit Testing for business logic and presentation logic

## Architecture

The app is intended to follow these layers:

- Presentation: SwiftUI views and view models
- Domain: entities, use cases, and repository contracts
- Data: repository implementations, remote data sources, and DTO mapping

This structure keeps the UI independent from data fetching details and makes the app easier to test and maintain.

## MVVM Flow

- `View` displays UI state and forwards user actions
- `ViewModel` handles screen state, loading, error handling, and presentation mapping
- `UseCase` contains application-specific business rules
- `Repository` abstracts data access from API or local cache

## Concurrency

The project should use modern Swift concurrency patterns:

- `async/await` for network calls
- `Task` for user-triggered async work
- `@MainActor` for UI state updates
- structured concurrency to keep async flows predictable and safe

## Unit Test Scope

Unit tests should focus on:

- use case behavior
- view model state changes
- repository contract behavior with mocked data sources
- mapping and error handling

UI tests can be added separately for critical user flows such as app launch, loading images, and opening image details.

## Suggested Project Structure

```text
ImageBrowserApp/
|- App/
|- Presentation/
|  |- Screens/
|  |- Components/
|  |- ViewModels/
|- Domain/
|  |- Entities/
|  |- UseCases/
|  |- Repositories/
|- Data/
|  |- DTOs/
|  |- DataSources/
|  |- Repositories/
|  |- Mappers/
|- Resources/
```

## Assignment Scope

Build a simple image browser application with the following expectations:

- display a list or grid of images
- load image data from a remote source
- support loading and error states
- keep the code modular and testable
- write unit tests for core logic

## Current Status

The repository currently contains the initial SwiftUI Xcode project scaffold. The README defines the intended direction for implementing the assignment with SwiftUI, MVVM, Clean Architecture, concurrency, and unit testing.
