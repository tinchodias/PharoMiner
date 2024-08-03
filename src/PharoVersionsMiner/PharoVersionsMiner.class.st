Class {
	#name : #PharoVersionsMiner,
	#superclass : #Object,
	#instVars : [
		'updateByTag',
		'tags',
		'scriptByTag',
		'versionNamesByTag',
		'timestampByTag',
		'pharoCoreGitRepositoryPath',
		'issuesByTag',
		'tagByHexId'
	],
	#category : #PharoVersionsMiner
}

{ #category : #'instance creation' }
PharoVersionsMiner class >> forAllPharos [

	^ self forPharoTagRegex: '30\d\d\d|40\d\d\d|50\d\d\d' asRegex
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> forPharo30 [
	"
	self forPharo30
	"

	^ self forPharoTagRegex: '30\d\d\d' asRegex
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> forPharo40 [
	"
	self forPharo40.
	"

	^ self forPharoTagRegex: '40\d\d\d' asRegex
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> forPharo50 [

	^ self forPharoTagRegex: '50\d\d\d' asRegex
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> forPharoTagRegex: pharoTagRegex [

	^ self forPharoTagsSatisfying: [ :each | pharoTagRegex matches: each ]
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> forPharoTagsSatisfying: aBlock [

	| pharoGitRepoPath repository tags |
	pharoGitRepoPath := 'pharo-core'.
	repository := self pharoCoreRepository.
						
	tags := repository tags select: aBlock.

	^ self new
		pharoCoreGitRepositoryPath: pharoGitRepoPath;
		tags: tags;
		run;
		yourself
]

{ #category : #'instance creation' }
PharoVersionsMiner class >> pharoCoreRepository [

	| pharoGitRepoPath repository |
	pharoGitRepoPath := 'pharo-core' asFileReference.

	repository := LGitRepository on: pharoGitRepoPath.
	(pharoGitRepoPath exists and: [ repository isProperRepository ])
		ifTrue: [ 'Reusing cloned Pharo-Core.' traceCr ]
		ifFalse: [
			'Cloning Pharo-Core repository...' traceCr.
			repository
				cloneHttps: 'https://github.com/pharo-project/pharo-core.git'.
			'Clone done.' traceCr ].
					
	^ repository
]

{ #category : #private }
PharoVersionsMiner >> bestTagForTimestamp: aDateAndTime [

	^ ((self selectTimestampByTagPreviousTo: aDateAndTime) associations detectMin: [ :each | 
		aDateAndTime - each value ]) key
]

{ #category : #private }
PharoVersionsMiner >> commitForTag: aTag [
	
	^ (self repository lookup: 'refs/tags/', aTag) object
]

{ #category : #private }
PharoVersionsMiner >> contentAt: aPath from: aLGitCommit ifPresent: presentBlock ifAbsent: absentBlock [

	| entry |
	entry := aLGitCommit
		entryByPath: aPath
		ifAbsent: [ ^ absentBlock value ].

	^ presentBlock cull: entry object contents
]

{ #category : #private }
PharoVersionsMiner >> contentAtAnyOf: paths from: aLGitCommit ifPresent: presentBlock ifAbsent: absentBlock [

	paths do: [ :aPath |
		self 
			contentAt: aPath 
			from: aLGitCommit 
			ifPresent: [ :contents | ^ presentBlock value: contents ] 
			ifAbsent: [  ] ].
		
	^ absentBlock value
]

{ #category : #convenience }
PharoVersionsMiner >> fileOutVersionNamesByTag [

	'versionNamesByTag.ston' asFileReference writeStreamDo: [ :stream |
		STON
			put: self versionNamesByTag
			onStreamPretty: stream ]
]

{ #category : #private }
PharoVersionsMiner >> firstTaggedCommitStartingAt: aLGitCommit [ 

	| currentCommit |
	currentCommit := aLGitCommit.
	
	[ self isTaggedCommit: currentCommit ] whileFalse: [ 
		self assert: currentCommit parents size = 1. "not yet implemented"
		
		currentCommit := currentCommit parents anyOne ].
	
	^ currentCommit 
]

{ #category : #private }
PharoVersionsMiner >> isTaggedCommit: aLGitCommit [ 
	
	^ self tagByHexId includesKey: aLGitCommit id hexString
]

{ #category : #accessing }
PharoVersionsMiner >> parentTagsByTag [

	| parentTagsByTag |
	parentTagsByTag := SmallDictionary new.

	tags do: [ :aTag |
		| parentTags |
		parentTags := self parentTagsForTag: aTag.
		
		parentTagsByTag at: aTag put: parentTags. 
		].
	
	^ parentTagsByTag
]

{ #category : #private }
PharoVersionsMiner >> parentTagsForTag: aTag [

	^ (self commitForTag: aTag) parents collect: [ :parentCommit | 
		self tagByHexId at: (self firstTaggedCommitStartingAt: parentCommit) id hexString ]
]

{ #category : #accessing }
PharoVersionsMiner >> pharoCoreGitRepositoryPath: aString [ 

	pharoCoreGitRepositoryPath := aString
]

{ #category : #private }
PharoVersionsMiner >> prepareIssuesByTag [

	issuesByTag := Dictionary new.

	updateByTag keysAndValuesDo: [ :aTag :update |
		| urls issues |
		urls := update allRegexMatches: 'pharo\.fogbugz\.com/f/cases/\d\d\d\d\d'.
		issues := urls collect: [ :each | each last: 5 ].
		
		issuesByTag at: aTag put: issues ]
]

{ #category : #private }
PharoVersionsMiner >> prepareScriptByTag [

	scriptByTag := Dictionary new.

	updateByTag keysAndValuesDo: [ :aTag :update |
		| commit possiblePathsForScript scriptSelector |
		commit := (self repository lookup: 'refs/tags/', aTag) object.

		scriptSelector := (RBParser parseMethod: update onError: [ self error ]) sentMessages detect: [ :each | each beginsWith: #script ].

		possiblePathsForScript := { 
			'ScriptLoader30/ScriptLoader.cls/instance/pharo - scripts/', scriptSelector, '.st'.
			'ScriptLoader30.package/ScriptLoader.class/instance/pharo - scripts/', scriptSelector, '.st'.
			'ScriptLoader40.package/ScriptLoader.class/instance/pharo - scripts/', scriptSelector, '.st'.
			'ScriptLoader50.package/ScriptLoader.class/instance/pharo - scripts/', scriptSelector, '.st' }.

		self 
			contentAtAnyOf: possiblePathsForScript
			from: commit
			ifPresent: [ :contents | scriptByTag at: aTag put: contents ] 
			ifAbsent: [ ].
		]
]

{ #category : #private }
PharoVersionsMiner >> prepareTimestampByTag [

	timestampByTag := Dictionary new.

	updateByTag keysAndValuesDo: [ :aTag :update |
		| commit |
		commit := self commitForTag: aTag.
		
		timestampByTag at: aTag put: commit time asDateAndTime ]
]

{ #category : #private }
PharoVersionsMiner >> prepareUpdateByTag [

	updateByTag := Dictionary new.

	tags do: [ :aTag |
		| commit possiblePathsForUpdate |
		commit := (self repository lookup: 'refs/tags/', aTag) object.

		possiblePathsForUpdate := { 
			'ScriptLoader30/ScriptLoader.cls/instance/pharo - updates/update', aTag, '.st'.
			'ScriptLoader30.package/ScriptLoader.class/instance/pharo - updates/update', aTag, '.st'.
			'ScriptLoader40.package/ScriptLoader.class/instance/pharo - updates/update', aTag, '.st'.
			'ScriptLoader50.package/ScriptLoader.class/instance/pharo - updates/update', aTag, '.st' }.

		self 
			contentAtAnyOf: possiblePathsForUpdate
			from: commit
			ifPresent: [ :contents | updateByTag at: aTag put: contents ] 
			ifAbsent: [ ].
		]
]

{ #category : #private }
PharoVersionsMiner >> prepareVersionNamesByTag [

	versionNamesByTag := Dictionary new.

	scriptByTag keysAndValuesDo: [ :aTag :script |
		| scriptAST fileNames versionNames |
		scriptAST := RBParser parseMethod: script.
		
		fileNames := scriptAST body statements first value receiver value findTokens: String lf, String cr.
		versionNames := fileNames collect: [ :each | 
			self assert: (each endsWith: '.mcz').
			each allButLast: 4 "Remove the file extension" ].
		
		versionNamesByTag at: aTag put: versionNames. 
		]
]

{ #category : #accessing }
PharoVersionsMiner >> reliableTimeSpanInPharo30 [
	"Explanation:
	- github/pharo-core has wrong timestamps before this tag: 30457.
	- (current) last version is 30858
	"

	^ (self timestampByTag at: '30457') to: (self timestampByTag at: '30858').
]

{ #category : #accessing }
PharoVersionsMiner >> repository [
	
	^ (LGitRepository on: pharoCoreGitRepositoryPath asFileReference) open; yourself
]

{ #category : #running }
PharoVersionsMiner >> run [

	self prepareUpdateByTag.
	self prepareScriptByTag.
	self prepareVersionNamesByTag.
	self prepareTimestampByTag.
	self prepareIssuesByTag.
]

{ #category : #accessing }
PharoVersionsMiner >> scriptByTag [
	
	^ scriptByTag
]

{ #category : #querying }
PharoVersionsMiner >> selectTagsForSlice: aMCVersion [ 

	"Explanation: Each MCDependency represents a version proposed by the slice, so the ancestors hold the Pharo versions changed."
	| originalVersionInfos originalVersionNames |
	originalVersionInfos := aMCVersion dependencies flatCollect: [ :aMCDependency | aMCDependency versionInfo ancestors ].
	originalVersionNames := originalVersionInfos collect: [ :each | each name ].
	
	^ self selectTagsWithAll: originalVersionNames
]

{ #category : #querying }
PharoVersionsMiner >> selectTagsWithAll: queriedVersionNames [

	^ (versionNamesByTag select: [ :versionNames |
		versionNames includesAll: queriedVersionNames ]) keys
]

{ #category : #private }
PharoVersionsMiner >> selectTimestampByTagPreviousTo: aDateAndTime [
	
	^ timestampByTag select: [ :each | each <= aDateAndTime ]
]

{ #category : #accessing }
PharoVersionsMiner >> tagByHexId [
	"Note: I collect id for ALL tags in the repository, not only the ones in the inst var 'tags'."
	
	tagByHexId ifNotNil: [ ^ tagByHexId ].
	
	tagByHexId := Dictionary new.

	self repository tags do: [ :aTag |
		[| hexId |
		hexId := (self commitForTag: aTag) id hexString.
		
		tagByHexId at: hexId put: aTag. ] 
			on: NotFound 
			do: [ :error | self inform: aTag asString, ' not found in #tagByHexId' ]
		].
	
	^ tagByHexId
]

{ #category : #accessing }
PharoVersionsMiner >> tags [
	
	^ tags
]

{ #category : #accessing }
PharoVersionsMiner >> tags: anObject [
	
	tags := anObject
]

{ #category : #accessing }
PharoVersionsMiner >> timestampByTag [
	
	^ timestampByTag
]

{ #category : #accessing }
PharoVersionsMiner >> updateByTag [
	
	^ updateByTag
]

{ #category : #accessing }
PharoVersionsMiner >> versionNamesByTag [
	
	^ versionNamesByTag
]
