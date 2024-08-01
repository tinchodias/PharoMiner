# Pharo Miner

Most recent usage info is:

```smalltalk
    Gofer it
            smalltalkhubUser: 'MartinDias'
            project: 'PharoMiner';
            configuration;
            load.
    #ConfigurationOfPharoMiner asClass loadBleedingEdge.
    
    "---"
    
    "github/pharo-core has wrong timestamps before this tag: 30457"
    startTime := versionsMiner timestampByTag at: '30457'.
    
    "endTime := versionsMiner timestampByTag at: '30858'.
    versionsMiner timestampByTag at: '30362'."
    
    "---"
    
    slicesMiner := PharoSlicesMiner forPharo30.
    SlicesMiner := slicesMiner.
    
    fogbugzMiner :=
            PharoFogBugzMiner new
                    tracker:
                            (FogBugzTracker pharo
                                    logOnWithEmail: 'tinchodias@gmail.com'
                                    password: '147147');
                    issueNumbers: slicesMiner versionsByNumber keys
                    yourself.
    4 timesRepeat: [ fogbugzMiner run ].
    
    versionsMiner := PharoVersionsMiner forPharo30.
    VersionsMiner := versionsMiner.
    versionsMiner := nil.
    
    versionsMiner reliableTimeSpanInPharo30.
    
    
    "Possible Pharo Tags for Slice"
    candidateTagsByNumber := Dictionary new.
    slicesMiner versionsByNumber keysAndValuesDo: [ :number :slices |
            candidateTagsByNumber
                    at: number
                    put: (versionsMiner selectTagsForSlice: slices anyOne) ].
    
    
    "Fogbugz FRN events matches "
    outdatedContributions :=
            (fogbugzMiner resolvedFRNEventsIn: versionsMiner reliableTimeSpanInPharo30) reject: [ :each |
                    bestSlice := slicesMiner bestVersionAt: each.
                    possiblePharoTagsForSlice := versionsMiner selectTagsForSlice: bestSlice.
                    currentPharoTagForEvent := versionsMiner bestTagForTimestamp: each date.
    
                    possiblePharoTagsForSlice
                            ifNotEmpty: [ possiblePharoTagsForSlice includes: currentPharoTagForEvent ]
                            ifEmpty: [ true ]
             ].
    " % "
    total := fogbugzMiner resolvedFRNEvents size.
    (outdatedContributions size * 100 / total) asFloat. "----> 5.78 % "
    
    
    "Fogbugz FTI events matches "
    outdatedContributionsFTI :=
            (fogbugzMiner resolvedFTIEventsIn: versionsMiner reliableTimeSpanInPharo30) reject: [ :each |
                    bestSlice := slicesMiner bestVersionAt: each.
                    possiblePharoTagsForSlice := versionsMiner selectTagsForSlice: bestSlice.
                    currentPharoTagForEvent := versionsMiner bestTagForTimestamp: each date.
    
                    possiblePharoTagsForSlice
                            ifNotEmpty: [ possiblePharoTagsForSlice includes: currentPharoTagForEvent ]
                            ifEmpty: [ true ]
             ].
    " % "
    total := fogbugzMiner resolvedFTIEvents size.
    (outdatedContributionsFTI size * 100 / total) asFloat. " ---> 5 % "
    
    
    " not overlapping with FRN "
    casesIdOfFRNEvents := outdatedContributions collect: [ :each | each case id ].
    notOverlappingFTIEvents := outdatedContributionsFTI reject: [ :each |
            casesIdOfFRNEvents includes: each case id ].
    total := fogbugzMiner resolvedFRNEvents size + notOverlappingFTIEvents size.
    ((outdatedContributions size + notOverlappingFTIEvents size) * 100 / total) asFloat. "----> 6.65 % "
```

## History

This codebase was recovered from SmalltalkHub.
Original repository: http://smalltalkhub.com/MartinDias/PharoMiner
Migration tool: https://github.com/pharo-contributions/git-migration

```smalltalk
"Pharo"
migration := GitMigration on: 'MartinDias/PharoMiner'.
migration onEmptyMessage: [ :info | 'empty commit message' ].
migration downloadAllVersions.
migration populateCaches.
migration allAuthors.
migration authors: {
	'MartinDias' -> #('Martín Dias' '<tinchodias@gmail.com>').
	'SkipLentz' -> #('Balletie' '<skip_meesie@hotmail.com>') }.
migration
	fastImportCodeToDirectory: 'src'
	initialCommit: '6bf3a47'
	to: 'import.txt'
```
