// Diagnostic tool, NOT part of the shipped tweak. It is how the CoreText paths
// used by SwiftUI / Liquid Glass were found, and it is the fastest way to find
// them again when a new iOS version moves them.
//
// To use it:
//   1. add AFontTrace.xm to AFont_FILES in the Makefile
//   2. call AFontStartTrace() from %ctor (guard it on a pref so it stays off by
//      default, e.g. plistDict[@"traceCoreText"])
//   3. open the app whose text is not being replaced, then on the device:
//        find /private/var/mobile/Containers/Data/Application -name ".afont_ct.log"
//
// Each line is a unique (function, input name, resolved name) triple, so the
// output stays small no matter how long the app runs.
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

static NSMutableSet *seen;
static NSString *tracePath;
static NSLock *traceLock;

static void traceFlush(void) {
	NSArray *sorted = [[seen allObjects] sortedArrayUsingSelector:@selector(compare:)];
	[[sorted componentsJoinedByString:@"\n"] writeToFile:tracePath
											  atomically:YES
												encoding:NSUTF8StringEncoding
												   error:nil];
}

static void traceAdd(NSString *line) {
	if (!seen) return;
	[traceLock lock];
	if (![seen containsObject:line]) {
		[seen addObject:line];
		traceFlush();
	}
	[traceLock unlock];
}

static NSString *psName(CTFontRef f) {
	if (!f) return @"(null)";
	NSString *n = (NSString *)CFBridgingRelease(CTFontCopyPostScriptName(f));
	return n ?: @"(noname)";
}

static NSString *descName(CTFontDescriptorRef d) {
	if (!d) return @"(null)";
	NSString *n = (NSString *)CFBridgingRelease(CTFontDescriptorCopyAttribute(d, kCTFontNameAttribute));
	if (n) return n;
	n = (NSString *)CFBridgingRelease(CTFontDescriptorCopyAttribute(d, kCTFontFamilyNameAttribute));
	if (n) return [@"family:" stringByAppendingString:n];
	NSNumber *ui = (NSNumber *)CFBridgingRelease(CTFontDescriptorCopyAttribute(d, CFSTR("NSCTFontUIUsageAttribute")));
	if (ui) return [@"uiusage:" stringByAppendingString:[ui description]];
	return @"(nodesc)";
}

%group Trace
%hookf(CTFontRef, CTFontCreateWithName, CFStringRef name, CGFloat size, const CGAffineTransform *m) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateWithName        in=%@ out=%@", (__bridge NSString *)name, psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateWithNameAndOptions, CFStringRef name, CGFloat size, const CGAffineTransform *m, CTFontOptions o) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateWithNameAndOpts in=%@ out=%@", (__bridge NSString *)name, psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateWithFontDescriptor, CTFontDescriptorRef d, CGFloat size, const CGAffineTransform *m) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateWithDescriptor  in=%@ out=%@", descName(d), psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateWithFontDescriptorAndOptions, CTFontDescriptorRef d, CGFloat size, const CGAffineTransform *m, CTFontOptions o) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateWithDescAndOpts in=%@ out=%@", descName(d), psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateUIFontForLanguage, CTFontUIFontType t, CGFloat size, CFStringRef lang) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateUIFont          uiType=%u out=%@", (unsigned)t, psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateCopyWithAttributes, CTFontRef f, CGFloat size, const CGAffineTransform *m, CTFontDescriptorRef d) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCopyWithAttributes    in=%@ desc=%@ out=%@", psName(f), descName(d), psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateCopyWithSymbolicTraits, CTFontRef f, CGFloat size, const CGAffineTransform *m, CTFontSymbolicTraits v, CTFontSymbolicTraits mask) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCopyWithTraits        in=%@ out=%@", psName(f), psName(r)]);
	return r;
}
%hookf(CTFontRef, CTFontCreateForString, CTFontRef f, CFStringRef s, CFRange range) {
	CTFontRef r = %orig;
	traceAdd([NSString stringWithFormat:@"CTFontCreateForString       in=%@ out=%@", psName(f), psName(r)]);
	return r;
}
%end

void AFontStartTrace(void) {
	traceLock = [NSLock new];
	seen = [NSMutableSet new];
	tracePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@".afont_ct.log"];
	[@"(trace started)" writeToFile:tracePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	%init(Trace);
}
