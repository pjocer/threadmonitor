//
//  SNKProtectCache.m
//  SnakeGameSingle
//
//  Created by karos li on 2022/3/30.
//  Copyright © 2022 WepieSnakeGame. All rights reserved.
//

#import "SNKProtectCache.h"
#import "SNKFileDownloader.h"

static NSString *const kSNKProtectIssueCachePatchVersions = @"kSNKProtectIssueCachePatchVersions";
static NSString *const kSNKProtectIssuePatchFolderName = @"protect_issue_patch";

@interface SNKProtectCache ()
@property(nonatomic, strong) NSString *basePath;
@end
@implementation SNKProtectCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _basePath = SNKLibiaryFilePathName(kSNKProtectIssuePatchFolderName);
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static SNKProtectCache *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[SNKProtectCache alloc] init];
    });
    return instance;
}

- (void)downloadPatchWithLink:(NSString *)patchLink version:(NSString *)patchVersion completeBlock:(void(^)(NSString *filepath, NSError *error))completeBlock {
    
    WEAKSELF
    [[SNKFileDownloader sharedDownloader] downloadFileIfNeededWithUrl:patchLink targetFolder:self.basePath complete:^(NSString *filePath, NSError *error) {
        if (error) {
            SNKLogError(@"protect issue patch download failed. patchVersion:%@，error:%@", patchVersion, error);
        } else {
            // 删除历史缓存
            [weakSelf deleteCachePatchFile:[filePath lastPathComponent] patchVersion:patchVersion];
        }
        !completeBlock? :completeBlock(error ? nil : filePath, error);
    }];
}

- (void)deleteCachePatchFile:(NSString *)currentSource patchVersion:(NSString *)patchVersion{
    if (SNKStringIsEmpty(patchVersion)) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableDictionary *diskCacheM = [[PrefUtils prefForKey:kSNKProtectIssueCachePatchVersions] mutableCopy];
        if (diskCacheM == nil) {
            diskCacheM = [NSMutableDictionary dictionary];
            [diskCacheM setValue:currentSource forKey:patchVersion];
            [PrefUtils setPrefWithKey:kSNKProtectIssueCachePatchVersions value:diskCacheM];
            return;
        }
        
        NSString *oldPath = [diskCacheM valueForKey:patchVersion];
        if (SNKStringIsEmpty(oldPath)) {
            [diskCacheM setValue:currentSource forKey:patchVersion];
            [PrefUtils setPrefWithKey:kSNKProtectIssueCachePatchVersions value:diskCacheM];
            return;
        }
        
        if ([oldPath isEqualToString:currentSource]) {
            SNKLogInfo(@"本次启动没有检测到 patch 更新");
            return;
        }
        
        SNKLogInfo(@"本次启动有检测到 patch 更新,需要清除历史缓存版本 patchVersion:%@", patchVersion);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSString *removePath = [NSString stringWithFormat:@"%@/%@",SNKLibiaryFilePathName(kSNKProtectIssuePatchFolderName),oldPath];
        [fileManager removeItemAtPath:removePath error:&error];
        if (error) {
            SNKLogError(@"delete patch source file in cache error:%@", error);
            return;
        }
        
        [diskCacheM setValue:currentSource forKey:patchVersion];
        [PrefUtils setPrefWithKey:kSNKProtectIssueCachePatchVersions value:diskCacheM];
    });
}

@end
