# Pharo Miner

The purpose of this project is gathering evolution information of [Pharo](https://pharo.org/). This is all intermediate versions between releases, and associated issue discussions of each evolution step.

This code is quite outdated (2015), but it seemed to work well on Pharo 11 in 2024.

Install on Pharo 11:
```smalltalk
Metacello new
        baseline: 'PharoMiner';
        repository: 'github://tinchodias/PharoMiner';
        load.
```

Download all Pharo 3 mcz to your disk (drink some mate meanwhile):
```smalltalk
PharoSlicesMiner downloadSlicesToCacheFrom: PharoSlicesMiner pharo30InboxRepository.
```

Clone pharo-core git repo (drink more mate now):
```smalltalk
PharoVersionsMiner pharoCoreRepository
```

## Do some queries

```smalltalk
slicesMiner := PharoSlicesMiner forPharo30.

fogbugzMiner :=
        PharoFogBugzMiner new
                tracker:
                        (FogBugzTracker pharo
                                logOnWithEmail: '???'
                                password: '???');
                issueNumbers: slicesMiner versionsByNumber keys
                yourself.
4 timesRepeat: [ fogbugzMiner run ].

versionsMiner := PharoVersionsMiner forPharo30.
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
                | bestSlice possiblePharoTagsForSlice currentPharoTagForEvent |
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
                | bestSlice possiblePharoTagsForSlice currentPharoTagForEvent |
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


"---"

"github/pharo-core has wrong timestamps before this tag: 30457"
startTime := versionsMiner timestampByTag at: '30457'.

endTime := versionsMiner timestampByTag at: '30858'.
versionsMiner timestampByTag at: '30362'.
```


## History

This codebase was recovered from SmalltalkHub.
* Source repository: http://smalltalkhub.com/MartinDias/PharoMiner
* Migration tool: https://github.com/pharo-contributions/git-migration

Script:
```smalltalk
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
