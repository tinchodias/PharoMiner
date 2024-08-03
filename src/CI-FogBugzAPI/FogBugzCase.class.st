"
I am a FogBugz case representation. I cache some of my info for speed purpose.

I implement a flyweight to ensure cases are unique per id
"
Class {
	#name : #FogBugzCase,
	#superclass : #Object,
	#instVars : [
		'id',
		'tags',
		'project',
		'title',
		'events',
		'milestone',
		'lastModification',
		'dateOpened',
		'dateResolved',
		'dateClosed',
		'status',
		'subcases',
		'parentCase',
		'user',
		'configuration',
		'configurationVersion',
		'preload',
		'postload'
	],
	#classInstVars : [
		'issues'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzCase class >> buildIssuesFrom: string [
	| xml | 

	xml := Soup fromString: string.
	^ (xml findAllTags: 'case') collect: [ :node| self fromXML: node ]
]

{ #category : #'instance creation' }
FogBugzCase class >> buildIssuesFrom: string tracker: anIssueTracker [
	| newIssues |
	newIssues := self buildIssuesFrom: string.
	newIssues do: [ :issue|
		issue tracker: anIssueTracker ].
	^ newIssues
]

{ #category : #'instance creation' }
FogBugzCase class >> detect: aBlockClosure ifNone: aBlockClosure2 [ 
	self shouldBeImplemented.
]

{ #category : #'instance creation' }
FogBugzCase class >> forId: id [

	^ self issues 
		detect: [ :e | e id = id ] 
		ifNone: [ FogBugzTracker penelope getIssueWithID: id ]
]

{ #category : #'instance creation' }
FogBugzCase class >> fromXML: xml [
	| instance |

	instance := self new 
					fromXML: xml;
					yourself.
	self issues add: instance.

	^ instance
]

{ #category : #'instance creation' }
FogBugzCase class >> id: id [

	^ self issues 
		detect: [ :e | e id = id ] 
		ifNone: [ | instance |
			instance := super new
							id: id;
							yourself.
			self issues add: instance.
			instance ]
]

{ #category : #accessing }
FogBugzCase class >> issues [
	 ^ issues ifNil: [ issues := Set new ]
]

{ #category : #updating }
FogBugzCase >> close [ 
	self tracker closeIssue: self id
]

{ #category : #accessing }
FogBugzCase >> configuration [
	^ configuration
]

{ #category : #accessing }
FogBugzCase >> configurationName [
	^ self configuration
]

{ #category : #accessing }
FogBugzCase >> configurationVersion [
	^ configurationVersion
]

{ #category : #accessing }
FogBugzCase >> configurationVersionOrDefault [
	^ self configurationVersion isEmptyOrNil
		ifTrue: [ #stable ]
		ifFalse: [ self configurationVersion ]
]

{ #category : #accessing }
FogBugzCase >> dateClosed [
	^ dateClosed
]

{ #category : #accessing }
FogBugzCase >> dateClosed: anObject [
	dateClosed := anObject
]

{ #category : #accessing }
FogBugzCase >> dateOpened [
	^ dateOpened
]

{ #category : #accessing }
FogBugzCase >> dateOpened: anObject [
	dateOpened := anObject
]

{ #category : #accessing }
FogBugzCase >> dateResolved [
	^ dateResolved
]

{ #category : #accessing }
FogBugzCase >> dateResolved: anObject [
	dateResolved := anObject
]

{ #category : #accessing }
FogBugzCase >> events [
	^ events ifNil: [ events := OrderedCollection new ]
]

{ #category : #accessing }
FogBugzCase >> events: anObject [
	^ events := anObject
]

{ #category : #initialization }
FogBugzCase >> fromXML: xml [
	| projectId |
	
	title     := (xml findTag: 'stitle') children first text.
	
	projectId := (xml findTag: 'ixproject') children first text asInteger.
	project := FogBugzProject id: projectId.
	project title: (xml findTag: 'sproject') children first text.
	
	id     := (xml attributeAt: 'ixBug') asInteger.
	events := (xml findTag: 'events') children collect: [:node | FogBugzEvent fromXML: node ].
	tags   := (xml findTag: 'tags') children collect: [:e | e text ].
	
	(xml findTag: 'sfixfor')
		ifNotNil: [ :tag | milestone := tag next text ].
	(xml findTag: 'ixbugchildren')
		ifNotNil: [ :tag |
			tag text isEmpty
				ifTrue: [ subcases := { } ]
				ifFalse: [ subcases := (tag text splitOn: $,) collect: [ :each | each asInteger ]]].
	(xml findTag: 'ixBugParent')
		ifNotNil: [ :tag | parentCase := tag text asInteger ].

	configuration := xml findTagText: 'configurationof' default: ''.
	configurationVersion := xml findTagText: 'configurationversion' default: ''.
	preload := xml findTagText: 'preload' default: ''.
	postload := xml findTagText: 'postload' default: ''.
		
	status := xml sstatus next text.
	
	lastModification := xml dtlastupdated text asDateAndTime.

	dateOpened := xml dtopened next text asDateAndTime.
	
	self hasBeenResolved
		ifTrue: [	dateResolved := xml dtresolved next text asDateAndTime ].
	self hasBeenClosed
		ifTrue: [dateClosed := xml dtclosed next text asDateAndTime ].
	
	user := FogBugzUser
		id: (xml findTag: 'ixperson') next text asInteger
		username: (xml findTag: 'sperson') next text
		mail: nil.
]

{ #category : #testing }
FogBugzCase >> hasBeenClosed [
	
	^ (self status ifNil: [ ^ false ]) beginsWith: 'Closed'
]

{ #category : #testing }
FogBugzCase >> hasBeenResolved [
	
	^ ((self status ifNil: [ ^ false ]) beginsWith: 'Resolved') or: [ self status beginsWith: 'Closed' ]
]

{ #category : #testing }
FogBugzCase >> hasConfiguration [
	^ self configuration isEmptyOrNil not
]

{ #category : #testing }
FogBugzCase >> hasPostload [
	^ self postload isEmptyOrNil not
]

{ #category : #testing }
FogBugzCase >> hasPreload [
	^ self preload isEmptyOrNil not
]

{ #category : #accessing }
FogBugzCase >> id [
	
	^ id
]

{ #category : #'instance creation' }
FogBugzCase >> id: aSmallInteger [ 
	
	id := aSmallInteger
]

{ #category : #initialization }
FogBugzCase >> initialize [
	super initialize.
	subcases := #()
]

{ #category : #testing }
FogBugzCase >> isHangingOnMonkeyCheck [
	
	^self status = 'Resolved (Monkey is checking)' and: [ 
		DateAndTime now - self lastModification > 2 hours]
]

{ #category : #accessing }
FogBugzCase >> lastModification [
	^ lastModification
]

{ #category : #accessing }
FogBugzCase >> lastModification: anObject [
	lastModification := anObject
]

{ #category : #updating }
FogBugzCase >> loadParentCase [
	"For performance reasons, the parentCase is only loaded on demand"
	parentCase := self tracker getIssueWithID: parentCase
]

{ #category : #updating }
FogBugzCase >> loadSubcases [
	"For performance reasons, the subcases are only loaded on demand"
	subcases := self tracker getIssuesWithIDs: subcases
]

{ #category : #accessing }
FogBugzCase >> milestone [
	^ milestone
]

{ #category : #accessing }
FogBugzCase >> milestone: anObject [
	^ milestone := anObject
]

{ #category : #accessing }
FogBugzCase >> parentCase [
	
	^ parentCase isInteger 
		ifTrue: [ parentCase := self loadParentCase ]
		ifFalse: [ parentCase ]
]

{ #category : #accessing }
FogBugzCase >> parentCase: anObject [
	
	parentCase := anObject
]

{ #category : #accessing }
FogBugzCase >> postload [
	^ postload
]

{ #category : #accessing }
FogBugzCase >> preload [
	^ preload
]

{ #category : #printing }
FogBugzCase >> printOn: stream [
	stream << self id << ' - ' << self title
]

{ #category : #accessing }
FogBugzCase >> project [
	^ project
]

{ #category : #accessing }
FogBugzCase >> project: anObject [
	project := anObject
]

{ #category : #accessing }
FogBugzCase >> projectTitle [
	^ self project title
]

{ #category : #accessing }
FogBugzCase >> publicUrl [

	^ self project tracker class hostname, '/f/cases/' , self id asString
]

{ #category : #updating }
FogBugzCase >> saveStatus [
	^ self saveStatus: ''
]

{ #category : #updating }
FogBugzCase >> saveStatus: aMessage [
	self tracker 
		editIssue: self id 
		withArguments: (Dictionary new  
				at: 'sEvent' put: aMessage asString;
				at: 'sStatus' put: self status;
				yourself)
]

{ #category : #updating }
FogBugzCase >> saveStatusAndTags: aMessage [
	self tracker 
		editIssue: self id 
		withArguments: (Dictionary new  
				at: 'sEvent'		put: aMessage asString;
				at: 'sStatus'		put: self status;
				at: 'sTags'		put: self tagsString;
				yourself)
]

{ #category : #updating }
FogBugzCase >> saveTags [
	^ self saveTags: ''
]

{ #category : #updating }
FogBugzCase >> saveTags: aMessage [
	self tracker 
		editIssue: self id 
		withArguments: (Dictionary new  
				at: 'sEvent' put: aMessage asString;
				at: 'sTags' put: self tagsString;
				yourself)
]

{ #category : #testing }
FogBugzCase >> shouldBeChecked [
	"Check if all subcases have been closed and that the issue has not yet been checked in this pharo version."
	| currentUpdateTag |
	
	currentUpdateTag := 'Validated in ', SystemVersion current highestUpdate asString.
	(self tags includes: currentUpdateTag)
		ifTrue: [ ^ false ].
	
	^ self subcases allSatisfy: [ :case | case hasBeenClosed ]
]

{ #category : #accessing }
FogBugzCase >> status [
	^ status
]

{ #category : #accessing }
FogBugzCase >> status: anObject [
	status := anObject
]

{ #category : #updating }
FogBugzCase >> statusFixReviewNeeded [
	^ self status: 'Resolved (Fix Review Needed)'
]

{ #category : #updating }
FogBugzCase >> statusFixReviewed [
	^ self status: 'Resolved (Fix Reviewed by the Monkey',"™"')'
]

{ #category : #updating }
FogBugzCase >> statusIntegrated [
	^ self status: 'Resolved (Fix Integrated)'
]

{ #category : #updating }
FogBugzCase >> statusMonkeyIsChecking [
	^ self status: 'Resolved (Monkey is Checking)'
]

{ #category : #updating }
FogBugzCase >> statusStaleTimeout [
	^ self status: 'Stale (Timeout)'
]

{ #category : #updating }
FogBugzCase >> statusWorkNeeded [
	^ self status: 'Work Needed'
]

{ #category : #updating }
FogBugzCase >> statusWorkNeededFailingTests [
	^ self status: 'Work Needed (Failing Test)'
]

{ #category : #updating }
FogBugzCase >> statusWorkNeededNoSources [
	^ self status: 'Work Needed (No Sources)'
]

{ #category : #accessing }
FogBugzCase >> subcases [
	
	(subcases anySatisfy: [ :each | each isInteger ])
			ifTrue: [ self loadSubcases ].
	^ subcases
]

{ #category : #accessing }
FogBugzCase >> subcases: anObject [
	
	subcases := anObject
]

{ #category : #accessing }
FogBugzCase >> tags [
	^ tags
]

{ #category : #accessing }
FogBugzCase >> tags: anObject [
	tags := anObject
]

{ #category : #accessing }
FogBugzCase >> tagsString [
	^ String streamContents: [ :stream| self tagsStringOn: stream ]
]

{ #category : #accessing }
FogBugzCase >> tagsStringOn: aStream [
	self tags
		do: [ :tag | aStream nextPut: $"; nextPutAll: tag asString; nextPut: $" ]
		separatedBy: [ aStream space ]
]

{ #category : #accessing }
FogBugzCase >> title [
	^ title
]

{ #category : #accessing }
FogBugzCase >> title: anObject [
	title := anObject
]

{ #category : #accessing }
FogBugzCase >> tracker [
	^ self project tracker
]

{ #category : #accessing }
FogBugzCase >> tracker: anIssueTracker [
	^ self project tracker: anIssueTracker
]

{ #category : #accessing }
FogBugzCase >> user [
	^ user
]

{ #category : #accessing }
FogBugzCase >> user: anObject [
	user := anObject
]
