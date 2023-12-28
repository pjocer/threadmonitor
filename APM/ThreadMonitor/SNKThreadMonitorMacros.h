//
//  SNKThreadMonitorMacros.h
//  SnakeGameSingle
//
//  Created by Jocer on 2023/12/26.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#ifndef SNKThreadMonitorMacros_h
#define SNKThreadMonitorMacros_h

#define THREAD_MONITOR_TRANS_START(transactionName) \
    if (BUILD_VERSION == 2) { \
        [SNKThreadMonitorHandler.shared pauseMonitor]; \
    } else { \
        [SNKThreadMonitorHandler.shared beginThreadTransactionCheck:@#transactionName]; \
    }

#define THREAD_MONITOR_TRANS_END(transactionName) \
    if (BUILD_VERSION == 2) { \
        [SNKThreadMonitorHandler.shared resumeMonitor]; \
    } else { \
        [SNKThreadMonitorHandler.shared endThreadTransactionCheck:@#transactionName]; \
    }

#endif /* SNKThreadMonitorMacros_h */
