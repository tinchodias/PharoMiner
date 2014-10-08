Class {
	#name : #PharoContributionsMiner,
	#superclass : #Object,
	#instVars : [
		'fogbugzMiner',
		'versionsMiner',
		'slicesMiner',
		'reliableTimeSpan'
	],
	#category : #PharoMiner
}

{ #category : #'instance creation' }
PharoContributionsMiner class >> forPharo30 [

	| slicesMiner fogbugzMiner versionsMiner |
	slicesMiner := PharoSlicesMiner forPharo30.

	fogbugzMiner := PharoFogBugzMiner forPharo30.
	4 timesRepeat: [ fogbugzMiner run ].

	versionsMiner := PharoVersionsMiner forPharo30.

	^ self new 
		slicesMiner: slicesMiner;
		fogbugzMiner: fogbugzMiner;
		versionsMiner: versionsMiner;
		reliableTimeSpan: versionsMiner reliableTimeSpanInPharo30;
		yourself

		

]

{ #category : #accessing }
PharoContributionsMiner >> fogbugzMiner [
	^ fogbugzMiner
]

{ #category : #accessing }
PharoContributionsMiner >> fogbugzMiner: anObject [
	fogbugzMiner := anObject
]

{ #category : #querying }
PharoContributionsMiner >> outdatedContributionsFRN [

	^ self outdatedContributionsForAll: (self fogbugzMiner resolvedFRNEventsIn: self reliableTimeSpan)
]

{ #category : #querying }
PharoContributionsMiner >> outdatedContributionsFTI [

	^ self outdatedContributionsForAll: (self fogbugzMiner resolvedFTIEventsIn: self reliableTimeSpan)
]

{ #category : #querying }
PharoContributionsMiner >> outdatedContributionsForAll: events [

	^ events reject: [ :each | 
		| bestSlice possiblePharoTagsForSlice currentPharoTagForEvent |

		bestSlice := self slicesMiner bestVersionAt: each.
		possiblePharoTagsForSlice := self versionsMiner selectTagsForSlice: bestSlice.
		currentPharoTagForEvent := self versionsMiner bestTagForTimestamp: each date.
		
		possiblePharoTagsForSlice 
			ifNotEmpty: [ possiblePharoTagsForSlice includes: currentPharoTagForEvent ]
			ifEmpty: [ true ] ]
]

{ #category : #accessing }
PharoContributionsMiner >> reliableTimeSpan [

	^ reliableTimeSpan
]

{ #category : #accessing }
PharoContributionsMiner >> reliableTimeSpan: aTimeSpan [

	reliableTimeSpan := aTimeSpan
]

{ #category : #accessing }
PharoContributionsMiner >> slicesMiner [
	^ slicesMiner
]

{ #category : #accessing }
PharoContributionsMiner >> slicesMiner: anObject [
	slicesMiner := anObject
]

{ #category : #accessing }
PharoContributionsMiner >> versionsMiner [
	^ versionsMiner
]

{ #category : #accessing }
PharoContributionsMiner >> versionsMiner: anObject [
	versionsMiner := anObject
]
