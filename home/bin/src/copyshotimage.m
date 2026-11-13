// Puts the newest screenshot (created in the last 15s) on the clipboard as an image.
#import <AppKit/AppKit.h>
int main(void) {
    @autoreleasepool {
        [NSThread sleepForTimeInterval:0.2];
        NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Screenshots"];
        NSArray *names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
        NSString *best = nil; NSDate *newest = nil;
        for (NSString *n in names) {
            if (![n hasPrefix:@"Screenshot"] || ![n hasSuffix:@".png"]) continue;
            NSString *p = [dir stringByAppendingPathComponent:n];
            NSDate *m = [[[NSFileManager defaultManager] attributesOfItemAtPath:p error:nil] fileModificationDate];
            if (m && (!newest || [m compare:newest] == NSOrderedDescending)) { newest = m; best = p; }
        }
        if (!best || -[newest timeIntervalSinceNow] > 15) return 0;
        NSData *png = [NSData dataWithContentsOfFile:best];
        if (!png) return 0;
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setData:png forType:NSPasteboardTypePNG];
    }
    return 0;
}
