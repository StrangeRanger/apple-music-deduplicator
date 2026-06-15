/*
 * Music.m
 */

#include "Music.h"




/*
 * Music Suite
 */

@implementation MusicApplication

typedef struct { NSString *name; FourCharCode code; } classForCode_t;
static const classForCode_t classForCodeData__[] = {
	{ @"MusicAirPlayDevice", 'cAPD' },
	{ @"MusicApplication", 'capp' },
	{ @"MusicArtwork", 'cArt' },
	{ @"MusicAudioCDPlaylist", 'cCDP' },
	{ @"MusicAudioCDTrack", 'cCDT' },
	{ @"MusicBrowserWindow", 'cBrW' },
	{ @"MusicEncoder", 'cEnc' },
	{ @"MusicEQPreset", 'cEQP' },
	{ @"MusicEQWindow", 'cEQW' },
	{ @"MusicFileTrack", 'cFlT' },
	{ @"MusicFolderPlaylist", 'cFoP' },
	{ @"MusicItem", 'cobj' },
	{ @"MusicLibraryPlaylist", 'cLiP' },
	{ @"MusicMiniplayerWindow", 'cMPW' },
	{ @"MusicPlaylist", 'cPly' },
	{ @"MusicPlaylistWindow", 'cPlW' },
	{ @"MusicRadioTunerPlaylist", 'cRTP' },
	{ @"MusicSharedTrack", 'cShT' },
	{ @"MusicSource", 'cSrc' },
	{ @"MusicSubscriptionPlaylist", 'cSuP' },
	{ @"MusicTrack", 'cTrk' },
	{ @"MusicURLTrack", 'cURT' },
	{ @"MusicUserPlaylist", 'cUsP' },
	{ @"MusicVideoWindow", 'cNPW' },
	{ @"MusicVisual", 'cVis' },
	{ @"MusicWindow", 'cwin' },
	{ nil, 0 } 
};

- (NSDictionary *) classNamesForCodes
{
	static NSMutableDictionary *dict__;

	if (!dict__) @synchronized([self class]) {
	if (!dict__) {
		dict__ = [[NSMutableDictionary alloc] init];
		const classForCode_t *p;
		for (p = classForCodeData__; p->name != nil; ++p)
			[dict__ setObject:p->name forKey:[NSNumber numberWithUnsignedInt:p->code]];
	} }
	return dict__;
}

typedef struct { FourCharCode code; NSString *name; } codeForPropertyName_t;
static const codeForPropertyName_t codeForPropertyNameData__[] = {
	{ 'lwcp', @"copies" },
	{ 'lwcl', @"collating" },
	{ 'lwfp', @"startingPage" },
	{ 'lwlp', @"endingPage" },
	{ 'lwla', @"pagesAcross" },
	{ 'lwld', @"pagesDown" },
	{ 'lweh', @"errorHandling" },
	{ 'lwqt', @"requestedPrintTime" },
	{ 'lwpf', @"printerFeatures" },
	{ 'faxn', @"faxNumber" },
	{ 'trpr', @"targetPrinter" },
	{ 'pAct', @"active" },
	{ 'pAva', @"available" },
	{ 'pKnd', @"kind" },
	{ 'pMAC', @"networkAddress" },
	{ 'pPro', @"protected" },
	{ 'selc', @"selected" },
	{ 'pAud', @"supportsAudio" },
	{ 'pVid', @"supportsVideo" },
	{ 'pVol', @"soundVolume" },
	{ 'pAPE', @"AirPlayEnabled" },
	{ 'pCnv', @"converting" },
	{ 'pAPD', @"currentAirPlayDevices" },
	{ 'pEnc', @"currentEncoder" },
	{ 'pEQP', @"currentEQPreset" },
	{ 'pPla', @"currentPlaylist" },
	{ 'pStT', @"currentStreamTitle" },
	{ 'pStU', @"currentStreamURL" },
	{ 'pTrk', @"currentTrack" },
	{ 'pVis', @"currentVisual" },
	{ 'pEQ ', @"EQEnabled" },
	{ 'pFix', @"fixedIndexing" },
	{ 'pisf', @"frontmost" },
	{ 'pFSc', @"fullScreen" },
	{ 'pnam', @"name" },
	{ 'pMut', @"mute" },
	{ 'pPos', @"playerPosition" },
	{ 'pPlS', @"playerState" },
	{ 'sele', @"selection" },
	{ 'pShE', @"shuffleEnabled" },
	{ 'pShM', @"shuffleMode" },
	{ 'pRpt', @"songRepeat" },
	{ 'pVol', @"soundVolume" },
	{ 'vers', @"version" },
	{ 'pVsE', @"visualsEnabled" },
	{ 'pPCT', @"data" },
	{ 'pDes', @"objectDescription" },
	{ 'pDlA', @"downloaded" },
	{ 'pFmt', @"format" },
	{ 'pKnd', @"kind" },
	{ 'pRaw', @"rawData" },
	{ 'pArt', @"artist" },
	{ 'pAnt', @"compilation" },
	{ 'pCmp', @"composer" },
	{ 'pDsC', @"discCount" },
	{ 'pDsN', @"discNumber" },
	{ 'pGen', @"genre" },
	{ 'pYr ', @"year" },
	{ 'pLoc', @"location" },
	{ 'sele', @"selection" },
	{ 'pPly', @"view" },
	{ 'pFmt', @"format" },
	{ 'pEQ1', @"band1" },
	{ 'pEQ2', @"band2" },
	{ 'pEQ3', @"band3" },
	{ 'pEQ4', @"band4" },
	{ 'pEQ5', @"band5" },
	{ 'pEQ6', @"band6" },
	{ 'pEQ7', @"band7" },
	{ 'pEQ8', @"band8" },
	{ 'pEQ9', @"band9" },
	{ 'pEQ0', @"band10" },
	{ 'pMod', @"modifiable" },
	{ 'pEQA', @"preamp" },
	{ 'pUTC', @"updateTracks" },
	{ 'pLoc', @"location" },
	{ 'pcls', @"objectClass" },
	{ 'ctnr', @"container" },
	{ 'ID  ', @"id" },
	{ 'pidx', @"index" },
	{ 'pnam', @"name" },
	{ 'pPIS', @"persistentID" },
	{ 'pALL', @"properties" },
	{ 'pDes', @"objectDescription" },
	{ 'pHat', @"disliked" },
	{ 'pDur', @"duration" },
	{ 'pnam', @"name" },
	{ 'pLov', @"favorited" },
	{ 'pPlP', @"parent" },
	{ 'pSiz', @"size" },
	{ 'pSpK', @"specialKind" },
	{ 'pTim', @"time" },
	{ 'pvis', @"visible" },
	{ 'sele', @"selection" },
	{ 'pPly', @"view" },
	{ 'capa', @"capacity" },
	{ 'frsp', @"freeSpace" },
	{ 'pKnd', @"kind" },
	{ 'pAlb', @"album" },
	{ 'pAlA', @"albumArtist" },
	{ 'pAHt', @"albumDisliked" },
	{ 'pALv', @"albumFavorited" },
	{ 'pAlR', @"albumRating" },
	{ 'pARk', @"albumRatingKind" },
	{ 'pArt', @"artist" },
	{ 'pBRt', @"bitRate" },
	{ 'pBkt', @"bookmark" },
	{ 'pBkm', @"bookmarkable" },
	{ 'pBPM', @"bpm" },
	{ 'pCat', @"category" },
	{ 'pClS', @"cloudStatus" },
	{ 'pCmt', @"comment" },
	{ 'pAnt', @"compilation" },
	{ 'pCmp', @"composer" },
	{ 'pDID', @"databaseID" },
	{ 'pAdd', @"dateAdded" },
	{ 'pDes', @"objectDescription" },
	{ 'pDsC', @"discCount" },
	{ 'pDsN', @"discNumber" },
	{ 'pHat', @"disliked" },
	{ 'pDAI', @"downloaderAccount" },
	{ 'pDNm', @"downloaderName" },
	{ 'pDur', @"duration" },
	{ 'enbl', @"enabled" },
	{ 'pEpD', @"episodeID" },
	{ 'pEpN', @"episodeNumber" },
	{ 'pEQp', @"EQ" },
	{ 'pStp', @"finish" },
	{ 'pGpl', @"gapless" },
	{ 'pGen', @"genre" },
	{ 'pGrp', @"grouping" },
	{ 'pKnd', @"kind" },
	{ 'pLds', @"longDescription" },
	{ 'pLov', @"favorited" },
	{ 'pLyr', @"lyrics" },
	{ 'pMdK', @"mediaKind" },
	{ 'asmo', @"modificationDate" },
	{ 'pMNm', @"movement" },
	{ 'pMvC', @"movementCount" },
	{ 'pMvN', @"movementNumber" },
	{ 'pPlC', @"playedCount" },
	{ 'pPlD', @"playedDate" },
	{ 'pPAI', @"purchaserAccount" },
	{ 'pPNm', @"purchaserName" },
	{ 'pRte', @"rating" },
	{ 'pRtk', @"ratingKind" },
	{ 'pRlD', @"releaseDate" },
	{ 'pSRt', @"sampleRate" },
	{ 'pSeN', @"seasonNumber" },
	{ 'pSfa', @"shufflable" },
	{ 'pSkC', @"skippedCount" },
	{ 'pSkD', @"skippedDate" },
	{ 'pShw', @"show" },
	{ 'pSAl', @"sortAlbum" },
	{ 'pSAr', @"sortArtist" },
	{ 'pSAA', @"sortAlbumArtist" },
	{ 'pSNm', @"sortName" },
	{ 'pSCm', @"sortComposer" },
	{ 'pSSN', @"sortShow" },
	{ 'pSiz', @"size" },
	{ 'pStr', @"start" },
	{ 'pTim', @"time" },
	{ 'pTrC', @"trackCount" },
	{ 'pTrN', @"trackNumber" },
	{ 'pUnp', @"unplayed" },
	{ 'pAdj', @"volumeAdjustment" },
	{ 'pWrk', @"work" },
	{ 'pYr ', @"year" },
	{ 'pURL', @"address" },
	{ 'pShr', @"shared" },
	{ 'pSmt', @"smart" },
	{ 'pGns', @"genius" },
	{ 'pbnd', @"bounds" },
	{ 'hclb', @"closeable" },
	{ 'pWSh', @"collapseable" },
	{ 'wshd', @"collapsed" },
	{ 'pFSc', @"fullScreen" },
	{ 'ppos', @"position" },
	{ 'prsz', @"resizable" },
	{ 'pvis', @"visible" },
	{ 'iszm', @"zoomable" },
	{ 'pzum', @"zoomed" },
	{ 0, nil } 
};

- (NSDictionary *) codesForPropertyNames
{
	static NSMutableDictionary *dict__;

	if (!dict__) @synchronized([self class]) {
	if (!dict__) {
		dict__ = [[NSMutableDictionary alloc] init];
		const codeForPropertyName_t *p;
		for (p = codeForPropertyNameData__; p->name != nil; ++p)
			[dict__ setObject:[NSNumber numberWithUnsignedInt:p->code] forKey:p->name];
	} }
	return dict__;
}


- (SBElementArray *) AirPlayDevices
{
	return [self elementArrayWithCode:'cAPD'];
}

- (SBElementArray *) browserWindows
{
	return [self elementArrayWithCode:'cBrW'];
}

- (SBElementArray *) encoders
{
	return [self elementArrayWithCode:'cEnc'];
}

- (SBElementArray *) EQPresets
{
	return [self elementArrayWithCode:'cEQP'];
}

- (SBElementArray *) EQWindows
{
	return [self elementArrayWithCode:'cEQW'];
}

- (SBElementArray *) miniplayerWindows
{
	return [self elementArrayWithCode:'cMPW'];
}

- (SBElementArray *) playlists
{
	return [self elementArrayWithCode:'cPly'];
}

- (SBElementArray *) playlistWindows
{
	return [self elementArrayWithCode:'cPlW'];
}

- (SBElementArray *) sources
{
	return [self elementArrayWithCode:'cSrc'];
}

- (SBElementArray *) tracks
{
	return [self elementArrayWithCode:'cTrk'];
}

- (SBElementArray *) videoWindows
{
	return [self elementArrayWithCode:'cNPW'];
}

- (SBElementArray *) visuals
{
	return [self elementArrayWithCode:'cVis'];
}

- (SBElementArray *) windows
{
	return [self elementArrayWithCode:'cwin'];
}


- (BOOL) AirPlayEnabled
{
	id v = [[self propertyWithCode:'pAPE'] get];
	return [v boolValue];
}

- (BOOL) converting
{
	id v = [[self propertyWithCode:'pCnv'] get];
	return [v boolValue];
}

- (NSArray<MusicAirPlayDevice *> *) currentAirPlayDevices
{
	return [[self propertyWithCode:'pAPD'] get];
}

- (void) setCurrentAirPlayDevices: (NSArray<MusicAirPlayDevice *> *) currentAirPlayDevices
{
	[[self propertyWithCode:'pAPD'] setTo:currentAirPlayDevices];
}

- (MusicEncoder *) currentEncoder
{
	return (MusicEncoder *) [self propertyWithClass:[MusicEncoder class] code:'pEnc'];
}

- (void) setCurrentEncoder: (MusicEncoder *) currentEncoder
{
	[[self propertyWithClass:[MusicEncoder class] code:'pEnc'] setTo:currentEncoder];
}

- (MusicEQPreset *) currentEQPreset
{
	return (MusicEQPreset *) [self propertyWithClass:[MusicEQPreset class] code:'pEQP'];
}

- (void) setCurrentEQPreset: (MusicEQPreset *) currentEQPreset
{
	[[self propertyWithClass:[MusicEQPreset class] code:'pEQP'] setTo:currentEQPreset];
}

- (MusicPlaylist *) currentPlaylist
{
	return (MusicPlaylist *) [self propertyWithClass:[MusicPlaylist class] code:'pPla'];
}

- (NSString *) currentStreamTitle
{
	return [[self propertyWithCode:'pStT'] get];
}

- (NSString *) currentStreamURL
{
	return [[self propertyWithCode:'pStU'] get];
}

- (MusicTrack *) currentTrack
{
	return (MusicTrack *) [self propertyWithClass:[MusicTrack class] code:'pTrk'];
}

- (MusicVisual *) currentVisual
{
	return (MusicVisual *) [self propertyWithClass:[MusicVisual class] code:'pVis'];
}

- (void) setCurrentVisual: (MusicVisual *) currentVisual
{
	[[self propertyWithClass:[MusicVisual class] code:'pVis'] setTo:currentVisual];
}

- (BOOL) EQEnabled
{
	id v = [[self propertyWithCode:'pEQ '] get];
	return [v boolValue];
}

- (void) setEQEnabled: (BOOL) EQEnabled
{
	id v = [NSNumber numberWithBool:EQEnabled];
	[[self propertyWithCode:'pEQ '] setTo:v];
}

- (BOOL) fixedIndexing
{
	id v = [[self propertyWithCode:'pFix'] get];
	return [v boolValue];
}

- (void) setFixedIndexing: (BOOL) fixedIndexing
{
	id v = [NSNumber numberWithBool:fixedIndexing];
	[[self propertyWithCode:'pFix'] setTo:v];
}

- (BOOL) frontmost
{
	id v = [[self propertyWithCode:'pisf'] get];
	return [v boolValue];
}

- (void) setFrontmost: (BOOL) frontmost
{
	id v = [NSNumber numberWithBool:frontmost];
	[[self propertyWithCode:'pisf'] setTo:v];
}

- (BOOL) fullScreen
{
	id v = [[self propertyWithCode:'pFSc'] get];
	return [v boolValue];
}

- (void) setFullScreen: (BOOL) fullScreen
{
	id v = [NSNumber numberWithBool:fullScreen];
	[[self propertyWithCode:'pFSc'] setTo:v];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (BOOL) mute
{
	id v = [[self propertyWithCode:'pMut'] get];
	return [v boolValue];
}

- (void) setMute: (BOOL) mute
{
	id v = [NSNumber numberWithBool:mute];
	[[self propertyWithCode:'pMut'] setTo:v];
}

- (double) playerPosition
{
	id v = [[self propertyWithCode:'pPos'] get];
	return [v doubleValue];
}

- (void) setPlayerPosition: (double) playerPosition
{
	id v = [NSNumber numberWithDouble:playerPosition];
	[[self propertyWithCode:'pPos'] setTo:v];
}

- (MusicEPlS) playerState
{
	id v = [[self propertyWithCode:'pPlS'] get];
	return [v enumCodeValue];
}

- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (BOOL) shuffleEnabled
{
	id v = [[self propertyWithCode:'pShE'] get];
	return [v boolValue];
}

- (void) setShuffleEnabled: (BOOL) shuffleEnabled
{
	id v = [NSNumber numberWithBool:shuffleEnabled];
	[[self propertyWithCode:'pShE'] setTo:v];
}

- (MusicEShM) shuffleMode
{
	id v = [[self propertyWithCode:'pShM'] get];
	return [v enumCodeValue];
}

- (void) setShuffleMode: (MusicEShM) shuffleMode
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:shuffleMode];
	[[self propertyWithCode:'pShM'] setTo:v];
}

- (MusicERpt) songRepeat
{
	id v = [[self propertyWithCode:'pRpt'] get];
	return [v enumCodeValue];
}

- (void) setSongRepeat: (MusicERpt) songRepeat
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:songRepeat];
	[[self propertyWithCode:'pRpt'] setTo:v];
}

- (NSInteger) soundVolume
{
	id v = [[self propertyWithCode:'pVol'] get];
	return [v integerValue];
}

- (void) setSoundVolume: (NSInteger) soundVolume
{
	id v = [NSNumber numberWithInteger:soundVolume];
	[[self propertyWithCode:'pVol'] setTo:v];
}

- (NSString *) version
{
	return [[self propertyWithCode:'vers'] get];
}

- (BOOL) visualsEnabled
{
	id v = [[self propertyWithCode:'pVsE'] get];
	return [v boolValue];
}

- (void) setVisualsEnabled: (BOOL) visualsEnabled
{
	id v = [NSNumber numberWithBool:visualsEnabled];
	[[self propertyWithCode:'pVsE'] setTo:v];
}


- (void) printPrintDialog:(BOOL)printDialog withProperties:(NSDictionary *)withProperties kind:(MusicEKnd)kind theme:(NSString *)theme
{
	[self sendEvent:'aevt' id:'pdoc' parameters:'pdlg', [NSNumber numberWithBool:printDialog], 'prdt', withProperties, 'pKnd', [NSAppleEventDescriptor descriptorWithEnumCode:kind], 'pThm', theme, 0];
}

- (void) run
{
	[self sendEvent:'aevt' id:'oapp' parameters:0];
}

- (void) quit
{
	[self sendEvent:'aevt' id:'quit' parameters:0];
}

- (MusicTrack *) add:(NSArray<NSURL *> *)x to:(SBObject *)to
{
	id result__ = [self sendEvent:'hook' id:'Add ' parameters:'----', x, 'insh', to, 0];
	return result__;
}

- (void) backTrack
{
	[self sendEvent:'hook' id:'Back' parameters:0];
}

- (MusicTrack *) convert:(NSArray<SBObject *> *)x
{
	id result__ = [self sendEvent:'hook' id:'Conv' parameters:'----', x, 0];
	return result__;
}

- (void) fastForward
{
	[self sendEvent:'hook' id:'Fast' parameters:0];
}

- (void) nextTrack
{
	[self sendEvent:'hook' id:'Next' parameters:0];
}

- (void) pause
{
	[self sendEvent:'hook' id:'Paus' parameters:0];
}

- (void) playOnce:(BOOL)once
{
	[self sendEvent:'hook' id:'Play' parameters:'POne', [NSNumber numberWithBool:once], 0];
}

- (void) playpause
{
	[self sendEvent:'hook' id:'PlPs' parameters:0];
}

- (void) previousTrack
{
	[self sendEvent:'hook' id:'Prev' parameters:0];
}

- (void) resume
{
	[self sendEvent:'hook' id:'Resu' parameters:0];
}

- (void) rewind
{
	[self sendEvent:'hook' id:'Rwnd' parameters:0];
}

- (void) stop
{
	[self sendEvent:'hook' id:'Stop' parameters:0];
}

- (void) openLocation:(NSString *)x
{
	[self sendEvent:'GURL' id:'GURL' parameters:'----', x, 0];
}

@end


@implementation MusicItem

- (SBObject *) container
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'ctnr'];
}

- (NSInteger) id
{
	id v = [[self propertyWithCode:'ID  '] get];
	return [v integerValue];
}

- (NSInteger) index
{
	id v = [[self propertyWithCode:'pidx'] get];
	return [v integerValue];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (void) setName: (NSString *) name
{
	[[self propertyWithCode:'pnam'] setTo:name];
}

- (NSString *) persistentID
{
	return [[self propertyWithCode:'pPIS'] get];
}

- (NSDictionary *) properties
{
	return [[self propertyWithCode:'pALL'] get];
}

- (void) setProperties: (NSDictionary *) properties
{
	[[self propertyWithCode:'pALL'] setTo:properties];
}


- (void) download
{
	[self sendEvent:'hook' id:'Dwnl' parameters:0];
}

- (NSString *) exportAs:(MusicEExF)as to:(NSURL *)to
{
	id result__ = [self sendEvent:'hook' id:'Expt' parameters:'pExF', [NSAppleEventDescriptor descriptorWithEnumCode:as], 'insh', to, 0];
	return result__;
}

- (void) reveal
{
	[self sendEvent:'hook' id:'Revl' parameters:0];
}


- (void) printPrintDialog:(BOOL)printDialog withProperties:(NSDictionary *)withProperties kind:(MusicEKnd)kind theme:(NSString *)theme
{
	[self sendEvent:'aevt' id:'pdoc' parameters:'pdlg', [NSNumber numberWithBool:printDialog], 'prdt', withProperties, 'pKnd', [NSAppleEventDescriptor descriptorWithEnumCode:kind], 'pThm', theme, 0];
}

- (void) close
{
	[self sendEvent:'core' id:'clos' parameters:0];
}

- (void) delete
{
	[self sendEvent:'core' id:'delo' parameters:0];
}

- (SBObject *) duplicateTo:(SBObject *)to
{
	id result__ = [self sendEvent:'core' id:'clon' parameters:'insh', to, 0];
	return result__;
}

- (BOOL) exists
{
	id result__ = [self sendEvent:'core' id:'doex' parameters:0];
	return [result__ boolValue];
}

- (void) open
{
	[self sendEvent:'aevt' id:'odoc' parameters:0];
}

- (void) save
{
	[self sendEvent:'core' id:'save' parameters:0];
}

- (void) playOnce:(BOOL)once
{
	[self sendEvent:'hook' id:'Play' parameters:'POne', [NSNumber numberWithBool:once], 0];
}

- (void) select
{
	[self sendEvent:'misc' id:'slct' parameters:0];
}

@end


@implementation MusicAirPlayDevice

- (BOOL) active
{
	id v = [[self propertyWithCode:'pAct'] get];
	return [v boolValue];
}

- (BOOL) available
{
	id v = [[self propertyWithCode:'pAva'] get];
	return [v boolValue];
}

- (MusicEAPD) kind
{
	id v = [[self propertyWithCode:'pKnd'] get];
	return [v enumCodeValue];
}

- (NSString *) networkAddress
{
	return [[self propertyWithCode:'pMAC'] get];
}

- (BOOL) protected
{
	id v = [[self propertyWithCode:'pPro'] get];
	return [v boolValue];
}

- (BOOL) selected
{
	id v = [[self propertyWithCode:'selc'] get];
	return [v boolValue];
}

- (void) setSelected: (BOOL) selected
{
	id v = [NSNumber numberWithBool:selected];
	[[self propertyWithCode:'selc'] setTo:v];
}

- (BOOL) supportsAudio
{
	id v = [[self propertyWithCode:'pAud'] get];
	return [v boolValue];
}

- (BOOL) supportsVideo
{
	id v = [[self propertyWithCode:'pVid'] get];
	return [v boolValue];
}

- (NSInteger) soundVolume
{
	id v = [[self propertyWithCode:'pVol'] get];
	return [v integerValue];
}

- (void) setSoundVolume: (NSInteger) soundVolume
{
	id v = [NSNumber numberWithInteger:soundVolume];
	[[self propertyWithCode:'pVol'] setTo:v];
}


@end


@implementation MusicArtwork

- (NSImage *) data
{
	return [[self propertyWithCode:'pPCT'] get];
}

- (void) setData: (NSImage *) data
{
	[[self propertyWithCode:'pPCT'] setTo:data];
}

- (NSString *) objectDescription
{
	return [[self propertyWithCode:'pDes'] get];
}

- (void) setObjectDescription: (NSString *) objectDescription
{
	[[self propertyWithCode:'pDes'] setTo:objectDescription];
}

- (BOOL) downloaded
{
	id v = [[self propertyWithCode:'pDlA'] get];
	return [v boolValue];
}

- (NSNumber *) format
{
	return [[self propertyWithCode:'pFmt'] get];
}

- (NSInteger) kind
{
	id v = [[self propertyWithCode:'pKnd'] get];
	return [v integerValue];
}

- (void) setKind: (NSInteger) kind
{
	id v = [NSNumber numberWithInteger:kind];
	[[self propertyWithCode:'pKnd'] setTo:v];
}

- (id) rawData
{
	return (id) [self propertyWithCode:'pRaw'];
}

- (void) setRawData: (id) rawData
{
	[[self propertyWithCode:'pRaw'] setTo:rawData];
}


@end


@implementation MusicEncoder

- (NSString *) format
{
	return [[self propertyWithCode:'pFmt'] get];
}


@end


@implementation MusicEQPreset

- (double) band1
{
	id v = [[self propertyWithCode:'pEQ1'] get];
	return [v doubleValue];
}

- (void) setBand1: (double) band1
{
	id v = [NSNumber numberWithDouble:band1];
	[[self propertyWithCode:'pEQ1'] setTo:v];
}

- (double) band2
{
	id v = [[self propertyWithCode:'pEQ2'] get];
	return [v doubleValue];
}

- (void) setBand2: (double) band2
{
	id v = [NSNumber numberWithDouble:band2];
	[[self propertyWithCode:'pEQ2'] setTo:v];
}

- (double) band3
{
	id v = [[self propertyWithCode:'pEQ3'] get];
	return [v doubleValue];
}

- (void) setBand3: (double) band3
{
	id v = [NSNumber numberWithDouble:band3];
	[[self propertyWithCode:'pEQ3'] setTo:v];
}

- (double) band4
{
	id v = [[self propertyWithCode:'pEQ4'] get];
	return [v doubleValue];
}

- (void) setBand4: (double) band4
{
	id v = [NSNumber numberWithDouble:band4];
	[[self propertyWithCode:'pEQ4'] setTo:v];
}

- (double) band5
{
	id v = [[self propertyWithCode:'pEQ5'] get];
	return [v doubleValue];
}

- (void) setBand5: (double) band5
{
	id v = [NSNumber numberWithDouble:band5];
	[[self propertyWithCode:'pEQ5'] setTo:v];
}

- (double) band6
{
	id v = [[self propertyWithCode:'pEQ6'] get];
	return [v doubleValue];
}

- (void) setBand6: (double) band6
{
	id v = [NSNumber numberWithDouble:band6];
	[[self propertyWithCode:'pEQ6'] setTo:v];
}

- (double) band7
{
	id v = [[self propertyWithCode:'pEQ7'] get];
	return [v doubleValue];
}

- (void) setBand7: (double) band7
{
	id v = [NSNumber numberWithDouble:band7];
	[[self propertyWithCode:'pEQ7'] setTo:v];
}

- (double) band8
{
	id v = [[self propertyWithCode:'pEQ8'] get];
	return [v doubleValue];
}

- (void) setBand8: (double) band8
{
	id v = [NSNumber numberWithDouble:band8];
	[[self propertyWithCode:'pEQ8'] setTo:v];
}

- (double) band9
{
	id v = [[self propertyWithCode:'pEQ9'] get];
	return [v doubleValue];
}

- (void) setBand9: (double) band9
{
	id v = [NSNumber numberWithDouble:band9];
	[[self propertyWithCode:'pEQ9'] setTo:v];
}

- (double) band10
{
	id v = [[self propertyWithCode:'pEQ0'] get];
	return [v doubleValue];
}

- (void) setBand10: (double) band10
{
	id v = [NSNumber numberWithDouble:band10];
	[[self propertyWithCode:'pEQ0'] setTo:v];
}

- (BOOL) modifiable
{
	id v = [[self propertyWithCode:'pMod'] get];
	return [v boolValue];
}

- (double) preamp
{
	id v = [[self propertyWithCode:'pEQA'] get];
	return [v doubleValue];
}

- (void) setPreamp: (double) preamp
{
	id v = [NSNumber numberWithDouble:preamp];
	[[self propertyWithCode:'pEQA'] setTo:v];
}

- (BOOL) updateTracks
{
	id v = [[self propertyWithCode:'pUTC'] get];
	return [v boolValue];
}

- (void) setUpdateTracks: (BOOL) updateTracks
{
	id v = [NSNumber numberWithBool:updateTracks];
	[[self propertyWithCode:'pUTC'] setTo:v];
}


@end


@implementation MusicPlaylist

- (SBElementArray *) tracks
{
	return [self elementArrayWithCode:'cTrk'];
}

- (SBElementArray *) artworks
{
	return [self elementArrayWithCode:'cArt'];
}


- (NSString *) objectDescription
{
	return [[self propertyWithCode:'pDes'] get];
}

- (void) setObjectDescription: (NSString *) objectDescription
{
	[[self propertyWithCode:'pDes'] setTo:objectDescription];
}

- (BOOL) disliked
{
	id v = [[self propertyWithCode:'pHat'] get];
	return [v boolValue];
}

- (void) setDisliked: (BOOL) disliked
{
	id v = [NSNumber numberWithBool:disliked];
	[[self propertyWithCode:'pHat'] setTo:v];
}

- (NSInteger) duration
{
	id v = [[self propertyWithCode:'pDur'] get];
	return [v integerValue];
}

- (NSString *) name
{
	return [[self propertyWithCode:'pnam'] get];
}

- (void) setName: (NSString *) name
{
	[[self propertyWithCode:'pnam'] setTo:name];
}

- (BOOL) favorited
{
	id v = [[self propertyWithCode:'pLov'] get];
	return [v boolValue];
}

- (void) setFavorited: (BOOL) favorited
{
	id v = [NSNumber numberWithBool:favorited];
	[[self propertyWithCode:'pLov'] setTo:v];
}

- (MusicPlaylist *) parent
{
	return (MusicPlaylist *) [self propertyWithClass:[MusicPlaylist class] code:'pPlP'];
}

- (NSInteger) size
{
	id v = [[self propertyWithCode:'pSiz'] get];
	return [v integerValue];
}

- (MusicESpK) specialKind
{
	id v = [[self propertyWithCode:'pSpK'] get];
	return [v enumCodeValue];
}

- (NSString *) time
{
	return [[self propertyWithCode:'pTim'] get];
}

- (BOOL) visible
{
	id v = [[self propertyWithCode:'pvis'] get];
	return [v boolValue];
}


- (void) moveTo:(SBObject *)to
{
	[self sendEvent:'core' id:'move' parameters:'insh', to, 0];
}

- (MusicTrack *) searchFor:(NSString *)for_ only:(MusicESrA)only
{
	id result__ = [self sendEvent:'hook' id:'Srch' parameters:'pTrm', for_, 'pAre', [NSAppleEventDescriptor descriptorWithEnumCode:only], 0];
	return result__;
}

@end


@implementation MusicAudioCDPlaylist

- (SBElementArray *) audioCDTracks
{
	return [self elementArrayWithCode:'cCDT'];
}


- (NSString *) artist
{
	return [[self propertyWithCode:'pArt'] get];
}

- (void) setArtist: (NSString *) artist
{
	[[self propertyWithCode:'pArt'] setTo:artist];
}

- (BOOL) compilation
{
	id v = [[self propertyWithCode:'pAnt'] get];
	return [v boolValue];
}

- (void) setCompilation: (BOOL) compilation
{
	id v = [NSNumber numberWithBool:compilation];
	[[self propertyWithCode:'pAnt'] setTo:v];
}

- (NSString *) composer
{
	return [[self propertyWithCode:'pCmp'] get];
}

- (void) setComposer: (NSString *) composer
{
	[[self propertyWithCode:'pCmp'] setTo:composer];
}

- (NSInteger) discCount
{
	id v = [[self propertyWithCode:'pDsC'] get];
	return [v integerValue];
}

- (void) setDiscCount: (NSInteger) discCount
{
	id v = [NSNumber numberWithInteger:discCount];
	[[self propertyWithCode:'pDsC'] setTo:v];
}

- (NSInteger) discNumber
{
	id v = [[self propertyWithCode:'pDsN'] get];
	return [v integerValue];
}

- (void) setDiscNumber: (NSInteger) discNumber
{
	id v = [NSNumber numberWithInteger:discNumber];
	[[self propertyWithCode:'pDsN'] setTo:v];
}

- (NSString *) genre
{
	return [[self propertyWithCode:'pGen'] get];
}

- (void) setGenre: (NSString *) genre
{
	[[self propertyWithCode:'pGen'] setTo:genre];
}

- (NSInteger) year
{
	id v = [[self propertyWithCode:'pYr '] get];
	return [v integerValue];
}

- (void) setYear: (NSInteger) year
{
	id v = [NSNumber numberWithInteger:year];
	[[self propertyWithCode:'pYr '] setTo:v];
}


@end


@implementation MusicLibraryPlaylist

- (SBElementArray *) fileTracks
{
	return [self elementArrayWithCode:'cFlT'];
}

- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}

- (SBElementArray *) sharedTracks
{
	return [self elementArrayWithCode:'cShT'];
}


@end


@implementation MusicRadioTunerPlaylist

- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}


@end


@implementation MusicSource

- (SBElementArray *) audioCDPlaylists
{
	return [self elementArrayWithCode:'cCDP'];
}

- (SBElementArray *) libraryPlaylists
{
	return [self elementArrayWithCode:'cLiP'];
}

- (SBElementArray *) playlists
{
	return [self elementArrayWithCode:'cPly'];
}

- (SBElementArray *) radioTunerPlaylists
{
	return [self elementArrayWithCode:'cRTP'];
}

- (SBElementArray *) subscriptionPlaylists
{
	return [self elementArrayWithCode:'cSuP'];
}

- (SBElementArray *) userPlaylists
{
	return [self elementArrayWithCode:'cUsP'];
}


- (long long) capacity
{
	id v = [[self propertyWithCode:'capa'] get];
	return [v longLongValue];
}

- (long long) freeSpace
{
	id v = [[self propertyWithCode:'frsp'] get];
	return [v longLongValue];
}

- (MusicESrc) kind
{
	id v = [[self propertyWithCode:'pKnd'] get];
	return [v enumCodeValue];
}


@end


@implementation MusicSubscriptionPlaylist

- (SBElementArray *) fileTracks
{
	return [self elementArrayWithCode:'cFlT'];
}

- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}


@end


@implementation MusicTrack

- (SBElementArray *) artworks
{
	return [self elementArrayWithCode:'cArt'];
}


- (NSString *) album
{
	return [[self propertyWithCode:'pAlb'] get];
}

- (void) setAlbum: (NSString *) album
{
	[[self propertyWithCode:'pAlb'] setTo:album];
}

- (NSString *) albumArtist
{
	return [[self propertyWithCode:'pAlA'] get];
}

- (void) setAlbumArtist: (NSString *) albumArtist
{
	[[self propertyWithCode:'pAlA'] setTo:albumArtist];
}

- (BOOL) albumDisliked
{
	id v = [[self propertyWithCode:'pAHt'] get];
	return [v boolValue];
}

- (void) setAlbumDisliked: (BOOL) albumDisliked
{
	id v = [NSNumber numberWithBool:albumDisliked];
	[[self propertyWithCode:'pAHt'] setTo:v];
}

- (BOOL) albumFavorited
{
	id v = [[self propertyWithCode:'pALv'] get];
	return [v boolValue];
}

- (void) setAlbumFavorited: (BOOL) albumFavorited
{
	id v = [NSNumber numberWithBool:albumFavorited];
	[[self propertyWithCode:'pALv'] setTo:v];
}

- (NSInteger) albumRating
{
	id v = [[self propertyWithCode:'pAlR'] get];
	return [v integerValue];
}

- (void) setAlbumRating: (NSInteger) albumRating
{
	id v = [NSNumber numberWithInteger:albumRating];
	[[self propertyWithCode:'pAlR'] setTo:v];
}

- (MusicERtK) albumRatingKind
{
	id v = [[self propertyWithCode:'pARk'] get];
	return [v enumCodeValue];
}

- (NSString *) artist
{
	return [[self propertyWithCode:'pArt'] get];
}

- (void) setArtist: (NSString *) artist
{
	[[self propertyWithCode:'pArt'] setTo:artist];
}

- (NSInteger) bitRate
{
	id v = [[self propertyWithCode:'pBRt'] get];
	return [v integerValue];
}

- (double) bookmark
{
	id v = [[self propertyWithCode:'pBkt'] get];
	return [v doubleValue];
}

- (void) setBookmark: (double) bookmark
{
	id v = [NSNumber numberWithDouble:bookmark];
	[[self propertyWithCode:'pBkt'] setTo:v];
}

- (BOOL) bookmarkable
{
	id v = [[self propertyWithCode:'pBkm'] get];
	return [v boolValue];
}

- (void) setBookmarkable: (BOOL) bookmarkable
{
	id v = [NSNumber numberWithBool:bookmarkable];
	[[self propertyWithCode:'pBkm'] setTo:v];
}

- (NSInteger) bpm
{
	id v = [[self propertyWithCode:'pBPM'] get];
	return [v integerValue];
}

- (void) setBpm: (NSInteger) bpm
{
	id v = [NSNumber numberWithInteger:bpm];
	[[self propertyWithCode:'pBPM'] setTo:v];
}

- (NSString *) category
{
	return [[self propertyWithCode:'pCat'] get];
}

- (void) setCategory: (NSString *) category
{
	[[self propertyWithCode:'pCat'] setTo:category];
}

- (MusicEClS) cloudStatus
{
	id v = [[self propertyWithCode:'pClS'] get];
	return [v enumCodeValue];
}

- (NSString *) comment
{
	return [[self propertyWithCode:'pCmt'] get];
}

- (void) setComment: (NSString *) comment
{
	[[self propertyWithCode:'pCmt'] setTo:comment];
}

- (BOOL) compilation
{
	id v = [[self propertyWithCode:'pAnt'] get];
	return [v boolValue];
}

- (void) setCompilation: (BOOL) compilation
{
	id v = [NSNumber numberWithBool:compilation];
	[[self propertyWithCode:'pAnt'] setTo:v];
}

- (NSString *) composer
{
	return [[self propertyWithCode:'pCmp'] get];
}

- (void) setComposer: (NSString *) composer
{
	[[self propertyWithCode:'pCmp'] setTo:composer];
}

- (NSInteger) databaseID
{
	id v = [[self propertyWithCode:'pDID'] get];
	return [v integerValue];
}

- (NSDate *) dateAdded
{
	return [[self propertyWithCode:'pAdd'] get];
}

- (NSString *) objectDescription
{
	return [[self propertyWithCode:'pDes'] get];
}

- (void) setObjectDescription: (NSString *) objectDescription
{
	[[self propertyWithCode:'pDes'] setTo:objectDescription];
}

- (NSInteger) discCount
{
	id v = [[self propertyWithCode:'pDsC'] get];
	return [v integerValue];
}

- (void) setDiscCount: (NSInteger) discCount
{
	id v = [NSNumber numberWithInteger:discCount];
	[[self propertyWithCode:'pDsC'] setTo:v];
}

- (NSInteger) discNumber
{
	id v = [[self propertyWithCode:'pDsN'] get];
	return [v integerValue];
}

- (void) setDiscNumber: (NSInteger) discNumber
{
	id v = [NSNumber numberWithInteger:discNumber];
	[[self propertyWithCode:'pDsN'] setTo:v];
}

- (BOOL) disliked
{
	id v = [[self propertyWithCode:'pHat'] get];
	return [v boolValue];
}

- (void) setDisliked: (BOOL) disliked
{
	id v = [NSNumber numberWithBool:disliked];
	[[self propertyWithCode:'pHat'] setTo:v];
}

- (NSString *) downloaderAccount
{
	return [[self propertyWithCode:'pDAI'] get];
}

- (NSString *) downloaderName
{
	return [[self propertyWithCode:'pDNm'] get];
}

- (double) duration
{
	id v = [[self propertyWithCode:'pDur'] get];
	return [v doubleValue];
}

- (BOOL) enabled
{
	id v = [[self propertyWithCode:'enbl'] get];
	return [v boolValue];
}

- (void) setEnabled: (BOOL) enabled
{
	id v = [NSNumber numberWithBool:enabled];
	[[self propertyWithCode:'enbl'] setTo:v];
}

- (NSString *) episodeID
{
	return [[self propertyWithCode:'pEpD'] get];
}

- (void) setEpisodeID: (NSString *) episodeID
{
	[[self propertyWithCode:'pEpD'] setTo:episodeID];
}

- (NSInteger) episodeNumber
{
	id v = [[self propertyWithCode:'pEpN'] get];
	return [v integerValue];
}

- (void) setEpisodeNumber: (NSInteger) episodeNumber
{
	id v = [NSNumber numberWithInteger:episodeNumber];
	[[self propertyWithCode:'pEpN'] setTo:v];
}

- (NSString *) EQ
{
	return [[self propertyWithCode:'pEQp'] get];
}

- (void) setEQ: (NSString *) EQ
{
	[[self propertyWithCode:'pEQp'] setTo:EQ];
}

- (double) finish
{
	id v = [[self propertyWithCode:'pStp'] get];
	return [v doubleValue];
}

- (void) setFinish: (double) finish
{
	id v = [NSNumber numberWithDouble:finish];
	[[self propertyWithCode:'pStp'] setTo:v];
}

- (BOOL) gapless
{
	id v = [[self propertyWithCode:'pGpl'] get];
	return [v boolValue];
}

- (void) setGapless: (BOOL) gapless
{
	id v = [NSNumber numberWithBool:gapless];
	[[self propertyWithCode:'pGpl'] setTo:v];
}

- (NSString *) genre
{
	return [[self propertyWithCode:'pGen'] get];
}

- (void) setGenre: (NSString *) genre
{
	[[self propertyWithCode:'pGen'] setTo:genre];
}

- (NSString *) grouping
{
	return [[self propertyWithCode:'pGrp'] get];
}

- (void) setGrouping: (NSString *) grouping
{
	[[self propertyWithCode:'pGrp'] setTo:grouping];
}

- (NSString *) kind
{
	return [[self propertyWithCode:'pKnd'] get];
}

- (NSString *) longDescription
{
	return [[self propertyWithCode:'pLds'] get];
}

- (void) setLongDescription: (NSString *) longDescription
{
	[[self propertyWithCode:'pLds'] setTo:longDescription];
}

- (BOOL) favorited
{
	id v = [[self propertyWithCode:'pLov'] get];
	return [v boolValue];
}

- (void) setFavorited: (BOOL) favorited
{
	id v = [NSNumber numberWithBool:favorited];
	[[self propertyWithCode:'pLov'] setTo:v];
}

- (NSString *) lyrics
{
	return [[self propertyWithCode:'pLyr'] get];
}

- (void) setLyrics: (NSString *) lyrics
{
	[[self propertyWithCode:'pLyr'] setTo:lyrics];
}

- (MusicEMdK) mediaKind
{
	id v = [[self propertyWithCode:'pMdK'] get];
	return [v enumCodeValue];
}

- (void) setMediaKind: (MusicEMdK) mediaKind
{
	id v = [NSAppleEventDescriptor descriptorWithEnumCode:mediaKind];
	[[self propertyWithCode:'pMdK'] setTo:v];
}

- (NSDate *) modificationDate
{
	return [[self propertyWithCode:'asmo'] get];
}

- (NSString *) movement
{
	return [[self propertyWithCode:'pMNm'] get];
}

- (void) setMovement: (NSString *) movement
{
	[[self propertyWithCode:'pMNm'] setTo:movement];
}

- (NSInteger) movementCount
{
	id v = [[self propertyWithCode:'pMvC'] get];
	return [v integerValue];
}

- (void) setMovementCount: (NSInteger) movementCount
{
	id v = [NSNumber numberWithInteger:movementCount];
	[[self propertyWithCode:'pMvC'] setTo:v];
}

- (NSInteger) movementNumber
{
	id v = [[self propertyWithCode:'pMvN'] get];
	return [v integerValue];
}

- (void) setMovementNumber: (NSInteger) movementNumber
{
	id v = [NSNumber numberWithInteger:movementNumber];
	[[self propertyWithCode:'pMvN'] setTo:v];
}

- (NSInteger) playedCount
{
	id v = [[self propertyWithCode:'pPlC'] get];
	return [v integerValue];
}

- (void) setPlayedCount: (NSInteger) playedCount
{
	id v = [NSNumber numberWithInteger:playedCount];
	[[self propertyWithCode:'pPlC'] setTo:v];
}

- (NSDate *) playedDate
{
	return [[self propertyWithCode:'pPlD'] get];
}

- (void) setPlayedDate: (NSDate *) playedDate
{
	[[self propertyWithCode:'pPlD'] setTo:playedDate];
}

- (NSString *) purchaserAccount
{
	return [[self propertyWithCode:'pPAI'] get];
}

- (NSString *) purchaserName
{
	return [[self propertyWithCode:'pPNm'] get];
}

- (NSInteger) rating
{
	id v = [[self propertyWithCode:'pRte'] get];
	return [v integerValue];
}

- (void) setRating: (NSInteger) rating
{
	id v = [NSNumber numberWithInteger:rating];
	[[self propertyWithCode:'pRte'] setTo:v];
}

- (MusicERtK) ratingKind
{
	id v = [[self propertyWithCode:'pRtk'] get];
	return [v enumCodeValue];
}

- (NSDate *) releaseDate
{
	return [[self propertyWithCode:'pRlD'] get];
}

- (NSInteger) sampleRate
{
	id v = [[self propertyWithCode:'pSRt'] get];
	return [v integerValue];
}

- (NSInteger) seasonNumber
{
	id v = [[self propertyWithCode:'pSeN'] get];
	return [v integerValue];
}

- (void) setSeasonNumber: (NSInteger) seasonNumber
{
	id v = [NSNumber numberWithInteger:seasonNumber];
	[[self propertyWithCode:'pSeN'] setTo:v];
}

- (BOOL) shufflable
{
	id v = [[self propertyWithCode:'pSfa'] get];
	return [v boolValue];
}

- (void) setShufflable: (BOOL) shufflable
{
	id v = [NSNumber numberWithBool:shufflable];
	[[self propertyWithCode:'pSfa'] setTo:v];
}

- (NSInteger) skippedCount
{
	id v = [[self propertyWithCode:'pSkC'] get];
	return [v integerValue];
}

- (void) setSkippedCount: (NSInteger) skippedCount
{
	id v = [NSNumber numberWithInteger:skippedCount];
	[[self propertyWithCode:'pSkC'] setTo:v];
}

- (NSDate *) skippedDate
{
	return [[self propertyWithCode:'pSkD'] get];
}

- (void) setSkippedDate: (NSDate *) skippedDate
{
	[[self propertyWithCode:'pSkD'] setTo:skippedDate];
}

- (NSString *) show
{
	return [[self propertyWithCode:'pShw'] get];
}

- (void) setShow: (NSString *) show
{
	[[self propertyWithCode:'pShw'] setTo:show];
}

- (NSString *) sortAlbum
{
	return [[self propertyWithCode:'pSAl'] get];
}

- (void) setSortAlbum: (NSString *) sortAlbum
{
	[[self propertyWithCode:'pSAl'] setTo:sortAlbum];
}

- (NSString *) sortArtist
{
	return [[self propertyWithCode:'pSAr'] get];
}

- (void) setSortArtist: (NSString *) sortArtist
{
	[[self propertyWithCode:'pSAr'] setTo:sortArtist];
}

- (NSString *) sortAlbumArtist
{
	return [[self propertyWithCode:'pSAA'] get];
}

- (void) setSortAlbumArtist: (NSString *) sortAlbumArtist
{
	[[self propertyWithCode:'pSAA'] setTo:sortAlbumArtist];
}

- (NSString *) sortName
{
	return [[self propertyWithCode:'pSNm'] get];
}

- (void) setSortName: (NSString *) sortName
{
	[[self propertyWithCode:'pSNm'] setTo:sortName];
}

- (NSString *) sortComposer
{
	return [[self propertyWithCode:'pSCm'] get];
}

- (void) setSortComposer: (NSString *) sortComposer
{
	[[self propertyWithCode:'pSCm'] setTo:sortComposer];
}

- (NSString *) sortShow
{
	return [[self propertyWithCode:'pSSN'] get];
}

- (void) setSortShow: (NSString *) sortShow
{
	[[self propertyWithCode:'pSSN'] setTo:sortShow];
}

- (long long) size
{
	id v = [[self propertyWithCode:'pSiz'] get];
	return [v longLongValue];
}

- (double) start
{
	id v = [[self propertyWithCode:'pStr'] get];
	return [v doubleValue];
}

- (void) setStart: (double) start
{
	id v = [NSNumber numberWithDouble:start];
	[[self propertyWithCode:'pStr'] setTo:v];
}

- (NSString *) time
{
	return [[self propertyWithCode:'pTim'] get];
}

- (NSInteger) trackCount
{
	id v = [[self propertyWithCode:'pTrC'] get];
	return [v integerValue];
}

- (void) setTrackCount: (NSInteger) trackCount
{
	id v = [NSNumber numberWithInteger:trackCount];
	[[self propertyWithCode:'pTrC'] setTo:v];
}

- (NSInteger) trackNumber
{
	id v = [[self propertyWithCode:'pTrN'] get];
	return [v integerValue];
}

- (void) setTrackNumber: (NSInteger) trackNumber
{
	id v = [NSNumber numberWithInteger:trackNumber];
	[[self propertyWithCode:'pTrN'] setTo:v];
}

- (BOOL) unplayed
{
	id v = [[self propertyWithCode:'pUnp'] get];
	return [v boolValue];
}

- (void) setUnplayed: (BOOL) unplayed
{
	id v = [NSNumber numberWithBool:unplayed];
	[[self propertyWithCode:'pUnp'] setTo:v];
}

- (NSInteger) volumeAdjustment
{
	id v = [[self propertyWithCode:'pAdj'] get];
	return [v integerValue];
}

- (void) setVolumeAdjustment: (NSInteger) volumeAdjustment
{
	id v = [NSNumber numberWithInteger:volumeAdjustment];
	[[self propertyWithCode:'pAdj'] setTo:v];
}

- (NSString *) work
{
	return [[self propertyWithCode:'pWrk'] get];
}

- (void) setWork: (NSString *) work
{
	[[self propertyWithCode:'pWrk'] setTo:work];
}

- (NSInteger) year
{
	id v = [[self propertyWithCode:'pYr '] get];
	return [v integerValue];
}

- (void) setYear: (NSInteger) year
{
	id v = [NSNumber numberWithInteger:year];
	[[self propertyWithCode:'pYr '] setTo:v];
}


@end


@implementation MusicAudioCDTrack

- (NSURL *) location
{
	return [[self propertyWithCode:'pLoc'] get];
}


@end


@implementation MusicFileTrack

- (NSURL *) location
{
	return [[self propertyWithCode:'pLoc'] get];
}

- (void) setLocation: (NSURL *) location
{
	[[self propertyWithCode:'pLoc'] setTo:location];
}


- (void) refresh
{
	[self sendEvent:'hook' id:'Rfrs' parameters:0];
}

@end


@implementation MusicSharedTrack

@end


@implementation MusicURLTrack

- (NSString *) address
{
	return [[self propertyWithCode:'pURL'] get];
}

- (void) setAddress: (NSString *) address
{
	[[self propertyWithCode:'pURL'] setTo:address];
}


@end


@implementation MusicUserPlaylist

- (SBElementArray *) fileTracks
{
	return [self elementArrayWithCode:'cFlT'];
}

- (SBElementArray *) URLTracks
{
	return [self elementArrayWithCode:'cURT'];
}

- (SBElementArray *) sharedTracks
{
	return [self elementArrayWithCode:'cShT'];
}


- (BOOL) shared
{
	id v = [[self propertyWithCode:'pShr'] get];
	return [v boolValue];
}

- (void) setShared: (BOOL) shared
{
	id v = [NSNumber numberWithBool:shared];
	[[self propertyWithCode:'pShr'] setTo:v];
}

- (BOOL) smart
{
	id v = [[self propertyWithCode:'pSmt'] get];
	return [v boolValue];
}

- (BOOL) genius
{
	id v = [[self propertyWithCode:'pGns'] get];
	return [v boolValue];
}


@end


@implementation MusicFolderPlaylist

@end


@implementation MusicVisual

@end


@implementation MusicWindow

- (NSRect) bounds
{
	id v = [[self propertyWithCode:'pbnd'] get];
	return [v rectValue];
}

- (void) setBounds: (NSRect) bounds
{
	id v = [NSValue valueWithRect:bounds];
	[[self propertyWithCode:'pbnd'] setTo:v];
}

- (BOOL) closeable
{
	id v = [[self propertyWithCode:'hclb'] get];
	return [v boolValue];
}

- (BOOL) collapseable
{
	id v = [[self propertyWithCode:'pWSh'] get];
	return [v boolValue];
}

- (BOOL) collapsed
{
	id v = [[self propertyWithCode:'wshd'] get];
	return [v boolValue];
}

- (void) setCollapsed: (BOOL) collapsed
{
	id v = [NSNumber numberWithBool:collapsed];
	[[self propertyWithCode:'wshd'] setTo:v];
}

- (BOOL) fullScreen
{
	id v = [[self propertyWithCode:'pFSc'] get];
	return [v boolValue];
}

- (void) setFullScreen: (BOOL) fullScreen
{
	id v = [NSNumber numberWithBool:fullScreen];
	[[self propertyWithCode:'pFSc'] setTo:v];
}

- (NSPoint) position
{
	id v = [[self propertyWithCode:'ppos'] get];
	return [v pointValue];
}

- (void) setPosition: (NSPoint) position
{
	id v = [NSValue valueWithPoint:position];
	[[self propertyWithCode:'ppos'] setTo:v];
}

- (BOOL) resizable
{
	id v = [[self propertyWithCode:'prsz'] get];
	return [v boolValue];
}

- (BOOL) visible
{
	id v = [[self propertyWithCode:'pvis'] get];
	return [v boolValue];
}

- (void) setVisible: (BOOL) visible
{
	id v = [NSNumber numberWithBool:visible];
	[[self propertyWithCode:'pvis'] setTo:v];
}

- (BOOL) zoomable
{
	id v = [[self propertyWithCode:'iszm'] get];
	return [v boolValue];
}

- (BOOL) zoomed
{
	id v = [[self propertyWithCode:'pzum'] get];
	return [v boolValue];
}

- (void) setZoomed: (BOOL) zoomed
{
	id v = [NSNumber numberWithBool:zoomed];
	[[self propertyWithCode:'pzum'] setTo:v];
}


@end


@implementation MusicBrowserWindow

- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (MusicPlaylist *) view
{
	return (MusicPlaylist *) [self propertyWithClass:[MusicPlaylist class] code:'pPly'];
}

- (void) setView: (MusicPlaylist *) view
{
	[[self propertyWithClass:[MusicPlaylist class] code:'pPly'] setTo:view];
}


@end


@implementation MusicEQWindow

@end


@implementation MusicMiniplayerWindow

@end


@implementation MusicPlaylistWindow

- (SBObject *) selection
{
	return (SBObject *) [self propertyWithClass:[SBObject class] code:'sele'];
}

- (MusicPlaylist *) view
{
	return (MusicPlaylist *) [self propertyWithClass:[MusicPlaylist class] code:'pPly'];
}


@end


@implementation MusicVideoWindow

@end


