import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testModelAssetLocatorReturnsNilWhenAssetMissing() {
    XCTAssertNil(ModelAssetLocator.pathInBundle(name: "definitely_missing_model", ext: "task"))
  }
}
