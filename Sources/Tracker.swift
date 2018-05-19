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

internal final class Tracker {

    static let queue: DispatchQueue = .init(label: "com.wigglydog.MemoryGraph", attributes: .concurrent)

    private var associatedOnDeallocKey: UInt8 = 0

    private var retainedSelf: Any?

    private let lock: NSLock = .init()

    private var parentIsAlive = true

    private var hasReportedErrors = false

    private var children: Set<String> = .init()

    private let errorCallback: (Set<String>) -> Void

    init(errorCallback: @escaping (Set<String>) -> Void) {
        self.errorCallback = errorCallback
        self.retainedSelf = self
    }

    func parentHasBeenDeinitialized() {
        type(of: self).queue.asyncAfter(deadline: .now() + 2) {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.parentIsAlive = false
            self.handleErrorsIfNecessary()
        }
    }

    func startTrackingChild(_ child: AnyObject) {
        let id = type(of: self).identifier(from: child)
        lock.lock()
        defer { lock.unlock() }
        children.insert(id)
        let deallocCallback = DeallocCallback {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.children.remove(id)
            if !self.parentIsAlive {
                self.handleErrorsIfNecessary()
            }
        }
        objc_setAssociatedObject(child, &associatedOnDeallocKey, deallocCallback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func handleErrorsIfNecessary() {
        if children.isEmpty {
            retainedSelf = nil
            if hasReportedErrors {
                errorCallback(children)
            }
        } else {
            hasReportedErrors = true
            errorCallback(children)
        }
    }

    internal static func identifier(from object: AnyObject) -> String {
        return "<\(type(of: object)): \(String(format: "0x%0lx", ObjectIdentifier(object).hashValue))>"
    }
}
