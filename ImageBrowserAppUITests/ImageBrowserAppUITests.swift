//
//  ImageBrowserAppUITests.swift
//  ImageBrowserAppUITests
//
//  Created by Fadil on 30/04/26.
//

import XCTest

final class ImageBrowserAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchShowsImageListWithStubbedContent() throws {
        let app = launchApp(stubMode: "success")

        XCTAssertTrue(app.staticTexts["image-list-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["author-label-0"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchShowsRetryStateWhenStubbedToFail() throws {
        let app = launchApp(stubMode: "failure")

        XCTAssertTrue(app.buttons["retry-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSlowLaunchKeepsSplashVisibleBeforeShowingList() throws {
        let app = launchApp(stubMode: "slow-success")

        XCTAssertTrue(app.otherElements["splash-screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["image-list-title"].waitForExistence(timeout: 6))
    }

    @MainActor
    func testScrollingToTheBottomLoadsTheNextPage() throws {
        let app = launchApp(stubMode: "success")

        XCTAssertTrue(app.staticTexts["author-label-0"].waitForExistence(timeout: 5))

        let nextPageAuthor = app.staticTexts["author-label-20"]
        for _ in 0 ..< 8 where !nextPageAuthor.exists {
            app.swipeUp()
        }

        XCTAssertTrue(nextPageAuthor.exists)
    }

    @MainActor
    func testLoadMoreFailureKeepsVisibleItemsAndShowsFooterRetry() throws {
        let app = launchApp(stubMode: "load-more-failure")

        XCTAssertTrue(app.staticTexts["author-label-0"].waitForExistence(timeout: 5))

        let retryButton = app.buttons["load-more-retry-button"]
        for _ in 0 ..< 8 where !retryButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(app.staticTexts["author-label-0"].exists)
        XCTAssertTrue(retryButton.exists)
    }

    @MainActor
    func testRetryingLoadMoreAppendsNextPageItems() throws {
        let app = launchApp(stubMode: "load-more-retry-success")

        XCTAssertTrue(app.staticTexts["author-label-0"].waitForExistence(timeout: 5))

        let retryButton = app.buttons["load-more-retry-button"]
        for _ in 0 ..< 8 where !retryButton.exists {
            app.swipeUp()
        }

        retryButton.tap()

        let nextPageAuthor = app.staticTexts["author-label-20"]
        for _ in 0 ..< 8 where !nextPageAuthor.exists {
            app.swipeUp()
        }

        XCTAssertTrue(nextPageAuthor.exists)
    }

    @MainActor
    func testTappingACardOpensImageDetail() throws {
        let app = launchApp(stubMode: "success")

        let firstCard = app.otherElements["image-card-0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))

        firstCard.tap()

        XCTAssertTrue(app.otherElements["detail-image"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["add-comment-button"].exists)
    }

    @MainActor
    func testTappingPlusAddsTheFirstComment() throws {
        let app = launchApp(stubMode: "success")

        let firstCard = app.otherElements["image-card-0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        firstCard.tap()

        let addCommentButton = app.buttons["add-comment-button"]
        XCTAssertTrue(addCommentButton.waitForExistence(timeout: 5))
        addCommentButton.tap()

        XCTAssertTrue(app.staticTexts["comment-author-0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["comment-date-0"].exists)
    }

    @MainActor
    func testTappingPlusTwiceKeepsNewestCommentAtTheTop() throws {
        let app = launchApp(stubMode: "success")

        let firstCard = app.otherElements["image-card-0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        firstCard.tap()

        let addCommentButton = app.buttons["add-comment-button"]
        XCTAssertTrue(addCommentButton.waitForExistence(timeout: 5))

        addCommentButton.tap()
        addCommentButton.tap()

        XCTAssertTrue(app.otherElements["comment-row-0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["comment-row-1"].exists)
    }

    @MainActor
    func testSwipeDeleteRemovesAComment() throws {
        let app = launchApp(stubMode: "success")

        let firstCard = app.otherElements["image-card-0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        firstCard.tap()

        let addCommentButton = app.buttons["add-comment-button"]
        XCTAssertTrue(addCommentButton.waitForExistence(timeout: 5))
        addCommentButton.tap()

        let firstComment = app.otherElements["comment-row-0"]
        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))
        firstComment.swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(firstComment.exists)
    }

    @MainActor
    private func launchApp(stubMode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["IMAGE_BROWSER_STUB_MODE"] = stubMode
        app.launch()
        return app
    }
}
