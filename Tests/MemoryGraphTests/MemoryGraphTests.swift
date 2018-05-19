//
// The MIT License (MIT)
//
// Copyright (c) 2018 Cameron Pulsford
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import XCTest
@testable import MemoryGraph

class Test {

    var children: [Test] = []
}

class MemoryGraphTests: XCTestCase {
    var sut: MemoryGraph?

    override func setUp() {
        super.setUp()
        sut = MemoryGraph()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testBasicLeakAndClear() {
        guard let sut = sut else { return XCTFail("no sut") }
        var parent: Test! = Test()
        var child: Test! = Test()
        parent.children = [child]
        let childIdentifier = Tracker.identifier(from: child)
        let childLeaks = expectation(description: "the child should leak")
        let childIsReleased = expectation(description: "the child is eventually released")
        sut.errorCallback = { leakedIdentifiers in
            print(leakedIdentifiers)
            if leakedIdentifiers == [childIdentifier] {
                childLeaks.fulfill()
            } else if leakedIdentifiers.isEmpty {
                childIsReleased.fulfill()
            }
        }

        sut.track(child, retainedBy: parent)
        parent = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            child = nil
        }

        waitForExpectations(timeout: 5)
    }
    
    static var allTests = [
        ("testBasicLeakAndClear", testBasicLeakAndClear),
    ]
}
