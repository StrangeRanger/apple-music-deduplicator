#import "Music.h"

NS_INLINE MusicTrack *AMDFindTrack(MusicApplication *music, NSInteger databaseID) {
    NSArray *matches = [[music tracks] filteredArrayUsingPredicate:
        [NSPredicate predicateWithFormat:@"databaseID == %@", @(databaseID)]];
    // Resolve the filtered collection before Swift bridges it to an Array.
    // Indexing an unresolved filter produces an item-of-filter reference that
    // Music rejects when used as a playback command's direct parameter.
    if ([matches isKindOfClass:[SBElementArray class]]) {
        matches = [(SBElementArray *)matches get];
    }
    return [matches firstObject];
}

// The generated MusicItem.playOnce: omits the event's direct parameter.
// Pass the selected track explicitly; sending that method to a track proxy
// does not make Music play the receiver.
NS_INLINE void AMDPlayTrackOnce(MusicApplication *music, MusicTrack *track) {
    [music sendEvent:'hook' id:'Play' parameters:keyDirectObject, track, 'POne', @YES, 0];
}
