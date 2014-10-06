Class {
	#name : #PharoFogBugzMiner,
	#superclass : #Object,
	#instVars : [
		'tracker',
		'issueNumbers',
		'caseByNumber'
	],
	#category : #PharoMiner
}

{ #category : #example }
PharoFogBugzMiner class >> example [
	"
	self example
	"
	
	| slicesMiner |
	slicesMiner := PharoSlicesMiner forPharo30.
	
	^ self new
		tracker: 
			(FogBugzTracker pharo 
				logOnWithEmail: 'tinchodias@gmail.com' 
				password: '147147');
		issueNumbers: slicesMiner versionsByNumber keys
		yourself
]

{ #category : #querying }
PharoFogBugzMiner >> anyFailReportOf: aCase [

	| reportUrl |
	reportUrl := (aCase events 
		detect: [ :e | e comment beginsWith: 'Issue Validation Failed: ' ])
		comment allButFirst: 'Issue Validation Failed: ' size.

	^ (ZnEasy get: reportUrl) contents

]

{ #category : #querying }
PharoFogBugzMiner >> caseByNumber [
	
	^ caseByNumber
]

{ #category : #querying }
PharoFogBugzMiner >> failedCaseByNumber [ 

	^ self caseByNumber reject: [ :case |
		case events noneSatisfy: [ :e | 
			e comment beginsWith: 'Issue Validation Failed' ] ].

]

{ #category : #initialization }
PharoFogBugzMiner >> initialize [

	super initialize.
	
	caseByNumber := Dictionary new.

]

{ #category : #accessing }
PharoFogBugzMiner >> issueNumbers [
	
	^ issueNumbers
]

{ #category : #accessing }
PharoFogBugzMiner >> issueNumbers: anObject [
	
	issueNumbers := anObject
]

{ #category : #private }
PharoFogBugzMiner >> resolvedFRNEventDescription [

	^ 'Resolved (Fix Review Needed)'
]

{ #category : #querying }
PharoFogBugzMiner >> resolvedFRNEvents [
	"FRN = Fix Review Needed"

	| resolvedEvents |
	resolvedEvents := OrderedCollection new.

	self caseByNumber do: [ :case |
		case events do: [ :each | 
			(each description beginsWith: self resolvedFRNEventDescription)
				ifTrue: [ resolvedEvents add: each ] ] ].

	^ resolvedEvents
]

{ #category : #querying }
PharoFogBugzMiner >> resolvedFRNEventsAfter: aDateAndTime [
	"FRN = Fix Review Needed"

	^ self resolvedFRNEvents select: [ :each | each date > aDateAndTime ]
]

{ #category : #running }
PharoFogBugzMiner >> run [
	"Retrieve information from FogBugz. It might be needed to #run mor ethan once."

	issueNumbers do: [ :key |
		(key isAllDigits and: [ "skip non-numeric issues (should be filtered before)"
			(caseByNumber includesKey: key) not ]) ifTrue: [ "skip if it was already downloaded (in a previous run)"
				[ (tracker issueWithId: key) in: [ :case | caseByNumber at: key put: case ] ] 
					on: FogBugzCaseNotFound do: [ "skip" ] ].
	].

]

{ #category : #accessing }
PharoFogBugzMiner >> tracker [
	
	^ tracker
]

{ #category : #accessing }
PharoFogBugzMiner >> tracker: anObject [
	
	tracker := anObject
]
