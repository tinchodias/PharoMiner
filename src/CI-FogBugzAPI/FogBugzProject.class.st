"
I am a FogBugz project.

I implement a flyweight to ensure projects are unique per id
"
Class {
	#name : #FogBugzProject,
	#superclass : #Object,
	#instVars : [
		'id',
		'title',
		'isInbox',
		'owner',
		'cases',
		'tracker',
		'rawIssues'
	],
	#classInstVars : [
		'projects'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzProject class >> buildProjectsFrom: string [
	| xml | 

	xml := Soup fromString: string.
	^ (xml findAllTags: 'project') collect: [ :node| self fromXML: node ]
]

{ #category : #'instance creation' }
FogBugzProject class >> fromXML: xml [
	| instance |
	
	instance := self id: (xml findTag: 'ixproject') next asString asInteger.
	instance fromXML: xml.
	^ instance
]

{ #category : #'instance creation' }
FogBugzProject class >> id: id [

	^ self projects 
		detect: [ :e | e id = id ] 
		ifNone: [ | instance |
			instance := super new
							id: id;
							yourself.
			self projects add: instance.
			instance ]
]

{ #category : #'instance creation' }
FogBugzProject class >> new [

	^ self error: 'Wrong way'
]

{ #category : #accessing }
FogBugzProject class >> projects [

        ^ projects ifNil: [ projects := Set new ]
]

{ #category : #updating }
FogBugzProject class >> updateAll [

	self projects do: [ :each | each update ]
]

{ #category : #queries }
FogBugzProject >> cases [

	^ cases ifNil: [ self refreshCases ]
]

{ #category : #accessing }
FogBugzProject >> fromXML: xml [

	title := (xml findTag: 'sproject') children first text.
	id := (xml findTag: 'ixproject') next asString asInteger.
	
	isInbox := (xml findTag: 'finbox') next text = 'true'.
	
	owner := FogBugzUser
				id: (xml findTag: 'ixpersonowner') next text asInteger
				username: (xml findTag: 'spersonowner') next text
				mail: (xml findTag: 'semail') next text.
]

{ #category : #queries }
FogBugzProject >> getAllCases [
	
	^ FogBugzCase buildIssuesFrom: self rawIssues tracker: self tracker
]

{ #category : #queries }
FogBugzProject >> getFirstCases: number [
	^ FogBugzCase 
		buildIssuesFrom: (self getFirstRawCases: number) 
		tracker: self tracker
]

{ #category : #queries }
FogBugzProject >> getFirstRawCases: number [
	| issues index occurrences |
	
	occurrences := 0.
	issues := self rawIssues.
	index := issues findString: 'case ixBug='.
	index = 0 
		ifTrue: [ ^ '' ].
	
	[ index > 0 and: [ occurrences < number ] ] 
		whileTrue:
			[ 
				occurrences := occurrences + 1.
				index := issues findString: 'case ixBug=' startingAt: index+1 ].

	index = 0 ifTrue: [ ^ issues ].
	^ issues copyFrom: 1 to: index + 1
]

{ #category : #accessing }
FogBugzProject >> id [
	^ id
]

{ #category : #accessing }
FogBugzProject >> id: anObject [
	id := anObject
]

{ #category : #accessing }
FogBugzProject >> isInbox [
	^ isInbox
]

{ #category : #accessing }
FogBugzProject >> isInbox: anObject [
	isInbox := anObject
]

{ #category : #queries }
FogBugzProject >> numberOfOpenCases [
	| issues index occurrences |
	
	occurrences := 0.
	issues := self rawIssues.
	index := issues findString: 'case ixBug='.
	index = 0 
		ifTrue: [ ^ 0 ].
	
	[ index > 0 ] 
		whileTrue:
			[ 
				occurrences := occurrences + 1.
				index := issues findString: 'case ixBug=' startingAt: index+1 ].
	
	^ occurrences
]

{ #category : #accessing }
FogBugzProject >> owner [
	^ owner
]

{ #category : #accessing }
FogBugzProject >> owner: anObject [
	owner := anObject
]

{ #category : #printing }
FogBugzProject >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: '( '.
	self id printOn: aStream.
	aStream nextPutAll: ' - '.
	self title printOn: aStream.
	aStream nextPutAll: ' )'.
]

{ #category : #accessing }
FogBugzProject >> rawIssues [

	^ rawIssues ifNil: [ self refreshRawIssues ]
]

{ #category : #queries }
FogBugzProject >> refreshCases [

	cases := nil.
	
	^ cases := self getAllCases
]

{ #category : #accessing }
FogBugzProject >> refreshRawIssues [
	^ rawIssues := self tracker getRawIssuesForProject: self title asString.
]

{ #category : #accessing }
FogBugzProject >> title [
	^ title
]

{ #category : #accessing }
FogBugzProject >> title: anObject [
	title := anObject
]

{ #category : #accessing }
FogBugzProject >> tracker [

	^ tracker ifNil: [ tracker := FogBugzTracker penelope ]
]

{ #category : #accessing }
FogBugzProject >> tracker: anIssueTracker [

	tracker := anIssueTracker
]

{ #category : #updating }
FogBugzProject >> update [
	self refreshRawIssues.
	self refreshCases.
]
