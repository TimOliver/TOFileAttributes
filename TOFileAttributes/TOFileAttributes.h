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

/// Create a new instance with the provided file URL
/// @param fileURL A URL to a file in the local file system.
- (instancetype)initWithFileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
