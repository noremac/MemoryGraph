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

public final class MemoryGraph {

    private enum Constants {
        static var associatedTrackerKey: UInt8 = 0
        static var associatedOnDeallocKey: UInt8 = 0
    }

    static var instance: MemoryGraph {
        return _instance
    }

    var errorCallback: ((Set<String>) -> Void)?

    public func track(_ child: AnyObject, retainedBy parent: AnyObject) {
        objc_sync_enter(parent)
        let tracker: Tracker
        if let t = objc_getAssociatedObject(parent, &Constants.associatedTrackerKey) as? Tracker {
            tracker = t
        } else {
            tracker = Tracker(errorCallback: errorCallback ?? { print($0) })
            let deallocCallback = DeallocCallback {
                tracker.parentHasBeenDeinitialized()
            }

            objc_setAssociatedObject(
                parent,
                &Constants.associatedTrackerKey,
                tracker,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            objc_setAssociatedObject(
                parent,
                &Constants.associatedOnDeallocKey,
                deallocCallback,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        objc_sync_exit(parent)
        tracker.startTrackingChild(child)
    }
}

private let _instance: MemoryGraph = .init()
