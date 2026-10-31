import XCTest
final class WrestleCutUITests: XCTestCase { func testLaunch() { let app = XCUIApplication(); app.launch(); XCTAssertTrue(app.exists) } }
