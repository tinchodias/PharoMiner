Class {
	#name : #FogBugzStatus,
	#superclass : #Object,
	#instVars : [
		'id',
		'name',
		'deleted'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzStatus class >> buildStatusesFrom: aString [
	| xml | 

	xml := Soup fromString: aString.
	^ (xml findAllTags: 'status') collect: [ :node| self fromXML: node ]
]

{ #category : #'instance creation' }
FogBugzStatus class >> fromXML: xml [
	| status |
	
	status := self 
		id: (xml findTag: 'ixstatus') next text asInteger
		name: (xml findTag: 'sstatus') next text.
		
	(Boolean readFrom: (xml findTag: 'fdeleted') next text readStream)
		ifTrue: [ status beDeleted ].
		
	^ status
]

{ #category : #'instance creation' }
FogBugzStatus class >> id: anId name: aName [ 
	^ self basicNew 
		initializeId: anId name: aName;
		yourself
]

{ #category : #'instance creation' }
FogBugzStatus class >> new [ 
	self error: 'Use #id:name:'
]

{ #category : #accessing }
FogBugzStatus >> beDeleted [
	deleted := true
]

{ #category : #accessing }
FogBugzStatus >> id [
	^ id
]

{ #category : #initialization }
FogBugzStatus >> initialize [
	super initialize.
	deleted := false
]

{ #category : #initialization }
FogBugzStatus >> initializeId: anId name: aName [
	id := anId. 
	name := aName.
	self initialize
]

{ #category : #testing }
FogBugzStatus >> isActive [
	^ self isDeleted not
]

{ #category : #testing }
FogBugzStatus >> isDeleted [ 
	^ deleted
]

{ #category : #accessing }
FogBugzStatus >> name [
	^ name
]
