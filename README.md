# A-Font

Change the system font on jailbroken iOS.

This is a fork of [Baw-Appie/A-Font](https://gitlab.com/Baw-Appie/A-Font) (upstream
1.10.1) with the full upstream history preserved. Licensed under MPL 2.0, same as
upstream.

## Changes in this fork (2.0.0)

**iOS 26 / SwiftUI / Liquid Glass coverage.**

Upstream hooks the Objective-C font APIs only (`+[UIFont systemFontOfSize:]`,
`+[UIFont fontWithDescriptor:size:]`, and friends). SwiftUI and the iOS 26
"Liquid Glass" chrome never call those — they ask CoreText for the system face
directly:

```
CTFontCreateWithFontDescriptor(desc(.AppleSystemUIFaceBody), 0, NULL) -> .SFUI-Regular
```

so those labels kept the stock face: the Settings root cells, the Photos toolbar
("Library", "Select"), Clock's "When Timer Ends", alert and edit-menu buttons,
home screen widgets, and the Apple News+ copy.

`Tweak.xm` now also hooks four CoreText entry points —
`CTFontCreateWithFontDescriptor`, `CTFontCreateWithFontDescriptorAndOptions`,
`CTFontCreateWithName`, `CTFontCreateWithNameAndOptions` — and substitutes the
chosen font when the requested face is the system UI family. Two name shapes are
matched, because callers use both:

| shape | examples |
|---|---|
| abstract face request | `.AppleSystemUIFaceBody`, `.AppleSystemUIFontBold` |
| already-resolved face | `.SFUI-Regular`, `.SFUI-Semibold`, `.SFUI-BoldG3` |

Anything outside those two prefixes is left alone, so the lock screen clock faces
(`.SFSoftNumeric`, `.SFRoundedNumeric`, `.NewYorkSoftNumeric`, ...), SF Symbols
and app-supplied fonts keep working. Weight comes from the face CoreText
resolved, point size from the original font, and the Font Size multiplier is
skipped in SpringBoard exactly as the existing `UIFont` hooks do.

Verified on iOS 26.0.1 (23A355), rootless, ElleKit 1.2.

## Diagnostics

`AFontTrace.xm` is a diagnostic file, not part of the build. It logs every unique
CoreText font-creation call so the paths above can be found again when a new iOS
version moves them. Instructions are at the top of the file.

## Building

```sh
THEOS_PACKAGE_SCHEME=rootless make package
```

Pass `TARGET=iphone:<sdk>:15.6` if the SDK named in the Makefile is not installed.
