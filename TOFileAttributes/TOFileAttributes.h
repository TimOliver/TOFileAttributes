//
//  TOFileAttributes.h
//  TOFileAttributesExample
//
//  Created by Tim Oliver on 20/5/21.
//

#import <UIKit/UIKit.h>
#import "TOPropertyAccessor.h"

NS_ASSUME_NONNULL_BEGIN

/// An abstract class that when subclassed, will map
/// its properties to the APFS extended file attributes
/// of the file specified with the provided URL.
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
/// Instances are cached in memory and calling this method multiple times
/// will return the same instance.
/// @param fileURL A URL to a file in the local file system.
+ (instancetype)attributesWithFileURL:(NSURL *)fileURL;

/// Creates a new attributes object linked to the provided file.
/// Properties are cached in memory after the first time they're loaded from disk.
/// @param fileURL A URL to a file in the local file system.
- (instancetype)initWithFileURL:(NSURL *)fileURL;

/// Creates a new attributes object linked to the provided file.
/// Caching can be disabled to directly access the disk every time.
/// @param fileURL A URL to a file in the local file system.
/// @param cached Whether to cache the properties in memory.
- (instancetype)initWithFileURL:(NSURL *)fileURL cached:(BOOL)cached;

/// Directly creating instances isn't allowed. Please use
/// `attributesWithFileURL:` instead
/// :nodoc:
- (instancetype)init __attribute__((unavailable("Use `attributesWithFileURL:` instead")));

@end

NS_ASSUME_NONNULL_END
