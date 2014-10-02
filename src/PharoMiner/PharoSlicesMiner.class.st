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

{ #category : #'instance creation' }
PharoSlicesMiner class >> forPharo30 [
	"
	self forPharo30
	"

	^ self new 
		repository:
			(MCHttpRepository
				location: 'http://smalltalkhub.com/mc/Pharo/Pharo30Inbox/main'
				user: ''
				password: '');
		yourself.
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
