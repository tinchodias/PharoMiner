Class {
	#name : #PharoVersionsMiner,
	#superclass : #Object,
	#instVars : [
		'updateByTag',
		'tags',
		'repository',
		'scriptByTag',
		'versionNamesByTag'
	],
	#category : #PharoMiner
}

{ #category : #'as yet unclassified' }
PharoVersionsMiner class >> forPharo30 [
	"
	self forPharo30
	"

	| repository tags tags30 |
	repository := (LGitRepository on: '/Users/tinchodias/dev/pharo-core/pharo-core' asFileReference) open; yourself.

	tags := '/Users/tinchodias/dev/pharo-core/pharo-core/tags.txt' asFileReference contents lines.
	tags30 := tags select: [ :each | each beginsWith: '30' ].

	^ self new
		repository: repository;
		tags: tags30;
		run;
		yourself.
]

{ #category : #private }
PharoVersionsMiner >> contentAt: aPath from: rootObject ifPresent: presentBlock ifAbsent: absentBlock [

	| blob |
	blob := LGitObject of: repository.

	^ (blob 
		object_lookup_bypath: blob 
		treeish: rootObject
		path: aPath
		type: (LG2GitOtypeE at: #GIT_OBJ_BLOB)) = 0 
		ifTrue: [ presentBlock value: blob concreteObject contents ]
		ifFalse: absentBlock
]

{ #category : #private }
PharoVersionsMiner >> contentAtAnyOf: paths from: rootObject ifPresent: presentBlock ifAbsent: absentBlock [

	paths do: [ :aPath |
		self 
			contentAt: aPath 
			from: rootObject 
			ifPresent: [ :contents | ^ presentBlock value: contents ] 
			ifAbsent: [  ] ].
		
	^ absentBlock value
]

{ #category : #private }
PharoVersionsMiner >> prepareScriptByTag [

	scriptByTag := Dictionary new.

	updateByTag keysAndValuesDo: [ :aTag :update |
		| commit possiblePathsForScript scriptSelector |
		commit := (repository lookup: 'refs/tags/', aTag) object.

		scriptSelector := (RBParser parseMethod: update onError: [ self error ]) sentMessages detect: [ :each | each beginsWith: #script ].

		possiblePathsForScript := { 
			'ScriptLoader30/ScriptLoader.cls/instance/pharo - scripts/', scriptSelector, '.st'.
			'ScriptLoader30.package/ScriptLoader.class/instance/pharo - scripts/', scriptSelector, '.st' }.

		self 
			contentAtAnyOf: possiblePathsForScript
			from: commit tree 
			ifPresent: [ :contents | scriptByTag at: aTag put: contents ] 
			ifAbsent: [ ].
		]
]

{ #category : #private }
PharoVersionsMiner >> prepareUpdateByTag [

	updateByTag := Dictionary new.

	tags do: [ :aTag |
		| commit possiblePathsForUpdate |
		commit := (repository lookup: 'refs/tags/', aTag) object.

		possiblePathsForUpdate := { 
			'ScriptLoader30/ScriptLoader.cls/instance/pharo - updates/update', aTag, '.st'.
			'ScriptLoader30.package/ScriptLoader.class/instance/pharo - updates/update', aTag, '.st' }.

		self 
			contentAtAnyOf: possiblePathsForUpdate
			from: commit tree 
			ifPresent: [ :contents | updateByTag at: aTag put: contents ] 
			ifAbsent: [ ].
		]
]

{ #category : #private }
PharoVersionsMiner >> prepareVersionNamesByTag [

	versionNamesByTag := Dictionary new.

	scriptByTag keysAndValuesDo: [ :aTag :script |
		| scriptAST |
		scriptAST := RBParser parseMethod: script onError: [ self error ].
		
		versionNamesByTag 
			at: aTag 
			put: (scriptAST body statements first value receiver token value findTokens: String lf, String cr). 
		]
]

{ #category : #accessing }
PharoVersionsMiner >> repository [
	
	^ repository
]

{ #category : #accessing }
PharoVersionsMiner >> repository: anObject [
	
	repository := anObject
]

{ #category : #running }
PharoVersionsMiner >> run [

	self prepareUpdateByTag.
	self prepareScriptByTag.
	self prepareVersionNamesByTag.
]

{ #category : #accessing }
PharoVersionsMiner >> scriptByTag [
	
	^ scriptByTag
]

{ #category : #querying }
PharoVersionsMiner >> selectTagsWithAll: queriedVersionNames [

	^ (versionNamesByTag select: [ :versionNames |
		versionNames includesAll: queriedVersionNames ]) keys
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
PharoVersionsMiner >> updateByTag [
	
	^ updateByTag
]
