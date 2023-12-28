//
//  WPZombieDynamicLinker.h
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/18.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#ifndef WPZombieDynamicLinker_h
#define WPZombieDynamicLinker_h
#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct {
    uint64_t address;
    uint64_t vmAddress;
    uint64_t size;
    const char *name;
    const uint8_t *uuid;
    int cpuType;
    int cpuSubType;
    uint64_t majorVersion;
    uint64_t minorVersion;
    uint64_t revisionVersion;
    const char *crashInfoMessage;
    const char *crashInfoMessage2;
} WPZombieSentryCrashBinaryImage;

/** Get the number of loaded binary images.
 */
int wpzombie_sentrycrashdl_imageCount(void);

/** Get information about a binary image.
 *
 * @param index The binary index.
 *
 * @param buffer A structure to hold the information.
 *
 * @return True if the image was successfully queried.
 */
bool wpzombie_sentrycrashdl_getBinaryImage(int index, WPZombieSentryCrashBinaryImage *buffer);

/** Get information about a binary image based on mach_header.
 *
 * @param header_ptr The pointer to mach_header of the image.
 *
 * @param image_name The name of the image.
 *
 * @param buffer A structure to hold the information.
 *
 * @return True if the image was successfully queried.
 */
bool wpzombie_sentrycrashdl_getBinaryImageForHeader(
    const void *const header_ptr, const char *const image_name, WPZombieSentryCrashBinaryImage *buffer);

// 根据地址和镜像列表获取一个在镜像
void wpzombie_sentrycrashdl_getBinaryImageOfAddress(const uintptr_t address, WPZombieSentryCrashBinaryImage *binaryImageList, int binaryImageCount, WPZombieSentryCrashBinaryImage **buffer);

// 指令地址标准化
uintptr_t wpzombie_sentrycrashcpu_normaliseInstructionPointer(uintptr_t ip);

#ifdef __cplusplus
}
#endif
#endif /* WPZombieDynamicLinker_h */
