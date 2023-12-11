//
//  Internal_Consts.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/21.
//

enum ThreadMonitorDelegateFunction {
    enum Notify {
        case willExit(_ thread: Thread?, _ info: (any ThreadInfoProviding)?)
        case willBecomeMulti
        case didBecomeSingle
    }
    enum Infos {
        case updateAll(_ infos: [MachInfoProvider])
    }
    enum State {
        case changed(_ info: POSIXInfoProvider)
        case create(_ info: POSIXInfoProvider)
        case start(_ info: POSIXInfoProvider)
        case finish(_ info: POSIXInfoProvider)
        case destory(_ info: POSIXInfoProvider)
    }
    case notify(_ type: Notify)
    case infos(_ type: Infos)
    case state(_ type: State)
    case indicator(_ type: IndicatorType)
}
