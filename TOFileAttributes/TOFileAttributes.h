//
//  TOFileAttributes.h
//
//  Copyright 2021 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>
#import "TOPropertyAccessor.h"

NS_ASSUME_NONNULL_BEGIN

/// An abstract class that when subclassed, will map
/// its properties to the APFS extended file attributes
/// of the file located at the provided URL.
///
/// The extended file attributes are a fantastic place to
/// store transitive metadata about the file that might be useful
/// between sessions, such as the previous cursor position of a text file.
///
/// The attributes will persist with the file even if it is moved or cloned,
/// but will be deleted if the file is moved to a different file system.
/// For more information, see https://nshipster.com/extended-file-attributes/

NS_SWIFT_NAME(FileAttributes)
@interface TOFileAttributes : TOPropertyAccessor

/// The file URL of the file with which these attributes are associated
@property (nonatomic, readonly) NSURL *fileURL;

/// A prefix that is added at the front of each attribute so as to not
/// cause any conflicts. Default is the app's bundle identifier (eg 'com.company.app')
@property (nonatomic, copy, null_resettable) NSString *identifierPrefix;

/// If the very last read/write operation failed, the error from that failure
/// will be exposed through this property. This can be used to guarantee mission
/// critical operations successfully went through.
@property (nonatomic, strong, nullable, readonly) NSError *latestError;

/// Returns an attributes object linked to the provided file.
/// Instances of this object are cached in memory and calling this
/// method multiple times on the same file will return the same instance.
/// @param fileURL A URL to a file in the local file system.
/// @returns The shared instance, or nil if the file could not be found
+ (nullable instancetype)attributesWithFileURL:(NSURL *)fileURL;

/// Creates a new attributes object linked to the provided file.
/// Properties are cached in memory after the first time they're loaded from disk,
/// but the instance itself isn't cached.
/// @param fileURL A URL to a file in the local file system.
/// @returns The instance, or nil if the file could not be found
- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;

/// Creates a new attributes object linked to the provided file.
/// Caching can be disabled to directly access the disk every time.
/// Keep in mind if you have a cached copy, and an uncached copy,
/// updating the uncached copy will not update the cached one.
/// @param fileURL A URL to a file in the local file system.
/// @param cached Whether to cache the properties in memory.
/// @returns The instance, or nil if the file could not be found
- (nullable instancetype)initWithFileURL:(NSURL *)fileURL cached:(BOOL)cached;

/// Directly creating instances isn't allowed. Please use
/// `attributesWithFileURL:` instead
/// :nodoc:
- (instancetype)init __attribute__((unavailable("Use `attributesWithFileURL:` instead")));

@end

NS_ASSUME_NONNULL_END
