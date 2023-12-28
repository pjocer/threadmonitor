//
//  WPZombieDynamicLinker.c
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/18.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#include "WPZombieDynamicLinker.h"

#include <limits.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/nlist.h>
#include <string.h>

/** Get the address of the first command following a header (which will be of
 * type struct load_command).
 *
 * @param header The header to get commands for.
 *
 * @return The address of the first command, or NULL if none was found (which
 *         should not happen unless the header or image is corrupt).
 */
static uintptr_t
wpzombie_firstCmdAfterHeader(const struct mach_header *const header)
{
    switch (header->magic) {
    case MH_MAGIC:
    case MH_CIGAM:
        return (uintptr_t)(header + 1);
    case MH_MAGIC_64:
    case MH_CIGAM_64:
        return (uintptr_t)(((struct mach_header_64 *)header) + 1);
    default:
        // Header is corrupt
        return 0;
    }
}

int wpzombie_sentrycrashdl_imageCount()
{
    return (int)_dyld_image_count();
}

bool wpzombie_sentrycrashdl_getBinaryImage(int index, WPZombieSentryCrashBinaryImage *buffer)
{
    const struct mach_header *header = _dyld_get_image_header((unsigned)index);
    if (header == NULL) {
        return false;
    }

    return wpzombie_sentrycrashdl_getBinaryImageForHeader(
        (const void *)header, _dyld_get_image_name((unsigned)index), buffer);
}

bool wpzombie_sentrycrashdl_getBinaryImageForHeader(
    const void *const header_ptr, const char *const image_name, WPZombieSentryCrashBinaryImage *buffer)
{
    const struct mach_header *header = (const struct mach_header *)header_ptr;
    uintptr_t cmdPtr = wpzombie_firstCmdAfterHeader(header);
    if (cmdPtr == 0) {
        return false;
    }

    // Look for the TEXT segment to get the image size.
    // Also look for a UUID command.
    uint64_t imageSize = 0;
    uint64_t imageVmAddr = 0;
    uint64_t version = 0;
    uint8_t *uuid = NULL;

    for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        struct load_command *loadCmd = (struct load_command *)cmdPtr;
        switch (loadCmd->cmd) {
        case LC_SEGMENT: {
            struct segment_command *segCmd = (struct segment_command *)cmdPtr;
            if (strcmp(segCmd->segname, SEG_TEXT) == 0) {
                imageSize = segCmd->vmsize;
                imageVmAddr = segCmd->vmaddr;
            }
            break;
        }
        case LC_SEGMENT_64: {
            struct segment_command_64 *segCmd = (struct segment_command_64 *)cmdPtr;
            if (strcmp(segCmd->segname, SEG_TEXT) == 0) {
                imageSize = segCmd->vmsize;
                imageVmAddr = segCmd->vmaddr;
            }
            break;
        }
        case LC_UUID: {
            struct uuid_command *uuidCmd = (struct uuid_command *)cmdPtr;
            uuid = uuidCmd->uuid;
            break;
        }
        case LC_ID_DYLIB: {

            struct dylib_command *dc = (struct dylib_command *)cmdPtr;
            version = dc->dylib.current_version;
            break;
        }
        }
        cmdPtr += loadCmd->cmdsize;
    }

    buffer->address = (uintptr_t)header;
    buffer->vmAddress = imageVmAddr;
    buffer->size = imageSize;
    buffer->name = image_name;
    buffer->uuid = uuid;
    buffer->cpuType = header->cputype;
    buffer->cpuSubType = header->cpusubtype;
    buffer->majorVersion = version >> 16;
    buffer->minorVersion = (version >> 8) & 0xff;
    buffer->revisionVersion = version & 0xff;

    return true;
}

void wpzombie_sentrycrashdl_getBinaryImageOfAddress(const uintptr_t address, WPZombieSentryCrashBinaryImage *binaryImageList, int binaryImageCount, WPZombieSentryCrashBinaryImage **buffer) {
    
    for (int index = 0; index < binaryImageCount; index++) {
        WPZombieSentryCrashBinaryImage *image = &binaryImageList[index];
        uintptr_t imageStart = image->address;
        uintptr_t imageEnd = image->address + image->size;
        if (address >= imageStart && address < imageEnd) {
            *buffer = image;
            break;
        }
    }
}

#  define KSPACStrippingMask_ARM64e 0x0000000fffffffff
// 指令地址标准化
uintptr_t wpzombie_sentrycrashcpu_normaliseInstructionPointer(uintptr_t ip)
{
    // 参考 sentry 源码
    return ip & KSPACStrippingMask_ARM64e;
}
