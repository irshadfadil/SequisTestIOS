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
        let app = XCUIApplication()
        app.launchEnvironment["IMAGE_BROWSER_STUB_MODE"] = "success"
        app.launch()

        XCTAssertTrue(app.staticTexts["image-list-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["author-label-0"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchShowsRetryStateWhenStubbedToFail() throws {
        let app = XCUIApplication()
        app.launchEnvironment["IMAGE_BROWSER_STUB_MODE"] = "failure"
        app.launch()

        XCTAssertTrue(app.buttons["retry-button"].waitForExistence(timeout: 5))
    }
}
