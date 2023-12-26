//
//  SNKThrottle.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/26.
//

import Foundation

public class SNKThrottle {
    
    public struct WorkItem {
        public var wrappedValue: MachThread
        public var backTrace: SNKBackTrace
        public var timeInterval: TimeInterval
    }
    
    var interval: TimeInterval
    var max: Int
    var callback: ([WorkItem])->Void
    @Protected
    var items: [WorkItem] = [WorkItem]()
    
    init(interval: TimeInterval, max: Int, callback: @escaping ([WorkItem]) -> Void) {
        self.interval = interval
        self.max = max
        self.callback = callback
    }
    
    func excuteWork(_ thread: MachThread) {
        guard thread > 0 else { return }
        let work = WorkItem(wrappedValue: thread, backTrace: SNKBackTrace(thread), timeInterval: Date().timeIntervalSince1970)
        $items.wrappedValue.append(work)
        callbackIfNeeded()
    }
    
    func callbackIfNeeded() {
        if max != ThreadMonitor.ThrottleAllThreadCreated {
            let now = Date().timeIntervalSince1970
            $items.wrappedValue.removeAll { now - $0.timeInterval > interval }
            if $items.wrappedValue.count >= max {
                callback($items.wrappedValue)
                $items.wrappedValue.removeAll()
            }
        }
    }
    func callbackForced() {
        callback($items.wrappedValue)
        $items.wrappedValue.removeAll()
    }
}
