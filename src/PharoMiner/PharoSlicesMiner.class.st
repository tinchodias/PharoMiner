Class {
	#name : #PharoSlicesMiner,
	#superclass : #Object,
	#instVars : [
		'repository',
		'versionsByNumber',
		'versions',
		'versionWithBigGapByNumber',
		'sortedArrayOfSamples',
		'sliceNames',
		'multipleVersionsByNumber',
		'arrayOfSamples'
	],
	#category : #PharoMiner
}

{ #category : #utils }
PharoSlicesMiner class >> downloadSlicesToCacheFrom: anMCHttpRepository [
	"
	self downloadSlicesToCacheFrom: self pharo30InboxRepository.
	"

	| fileNames |
	fileNames := 
		anMCHttpRepository allVersionNames 
			select: [ :each | each beginsWith: 'SLICE' ] 
			thenCollect: [ :each | each, '.mcz' ].
	
	fileNames 
		do: [ :aFileName | 
			(MCCacheRepository uniqueInstance includesFileNamed: aFileName)
				ifFalse: [ anMCHttpRepository readStreamForFileNamed: aFileName do: [ :e | ] ] ]
		displayingProgress: [ 'Downloading Slices (total: ', fileNames size asString, ')' ]
]

{ #category : #'instance creation' }
PharoSlicesMiner class >> forPharo30 [
	"
	self forPharo30
	"

	^ self new 
		repository: MCCacheRepository uniqueInstance "self pharo30InboxRepository";
		yourself.
]

{ #category : #utils }
PharoSlicesMiner class >> pharo30InboxRepository [
		
	^ MCSmalltalkhubRepository owner: 'Pharo' project: 'Pharo30Inbox'
]

{ #category : #querying }
PharoSlicesMiner >> arrayOfSamples [

	^ arrayOfSamples ifNil: [ arrayOfSamples := 
		self multipleVersionsByNumber values
			collect: [ :someVersions |
				| answer | 
				answer := nil.
				someVersions withIndexDo: [ :version :index | 
					index > 1 ifTrue: [
						|gap|
						gap := version info timeStamp - ((someVersions at: index - 1) info timeStamp).
						gap > self bigGap
							ifTrue: [ answer := { version. someVersions at: index-1. gap asDays } ] ] ].
				answer  ]
			thenSelect: #isNotNil. ]
]

{ #category : #querying }
PharoSlicesMiner >> bestVersionAt: anEvent [

	^ (self versionsAtEvent: anEvent) detectMin: [ :each | 
		(anEvent date - each info timeStamp ) abs ]
]

{ #category : #accessing }
PharoSlicesMiner >> bigGap [

	^ 10 days
]

{ #category : #querying }
PharoSlicesMiner >> multipleVersionsByNumber [ 

	^ multipleVersionsByNumber ifNil: [ multipleVersionsByNumber := 
		self versionsByNumber select: [ :e | e size >= 2 ] ]
]

{ #category : #accessing }
PharoSlicesMiner >> repository [
	
	^ repository
]

{ #category : #accessing }
PharoSlicesMiner >> repository: anObject [
	
	repository := anObject
]

{ #category : #querying }
PharoSlicesMiner >> sliceNames [ 

	^ sliceNames ifNil: [ sliceNames := 
		repository allVersionNames select: [ :each | each beginsWith: 'SLICE' ] ]
]

{ #category : #querying }
PharoSlicesMiner >> sortedArrayOfSamples [ 

	^ sortedArrayOfSamples ifNil: [ sortedArrayOfSamples  := 
		self arrayOfSamples sorted: [ :a :b | a third > b third ] ]
]

{ #category : #querying }
PharoSlicesMiner >> versionWithBigGapByNumber [ 

	^ versionWithBigGapByNumber ifNil: [ versionWithBigGapByNumber := 
		self multipleVersionsByNumber 
			select: [ :someVersions |
				| answer | 
				answer := false.
				someVersions withIndexDo: [ :version :index | 
					index > 1 ifTrue: [
						(version info timeStamp - ((someVersions at: index - 1) info timeStamp)) > self bigGap
							ifTrue: [ answer := true ] ] ].
				answer. ] ]
]

{ #category : #querying }
PharoSlicesMiner >> versions [

	^ versions ifNil: [ versions :=
		self sliceNames collect: [ :name | repository versionFromFileNamed: name, '.mcz' ] ]
]

{ #category : #querying }
PharoSlicesMiner >> versionsAtEvent: anEvent [

	^ self versionsByNumber at: anEvent case id asString
]

{ #category : #querying }
PharoSlicesMiner >> versionsByNumber [

	^ versionsByNumber ifNil: [ versionsByNumber := 
		self versions
			inject: Dictionary new
			into: [ :acum :each | 
				(acum 
					at: (each name splitOn: '-') third 
					ifAbsentPut: [ SortedCollection sortBlock: [ :a :b | a info timeStamp < b info timeStamp ] ]) 
					add: each.
				acum ] ]
]
