"
I am an FogBugz case event (comment)
"
Class {
	#name : #FogBugzEvent,
	#superclass : #Object,
	#instVars : [
		'id',
		'attachements',
		'description',
		'comment',
		'changes',
		'date',
		'case',
		'user'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzEvent class >> fromXML: xml [ 

	^ self new
		fromXML: xml;
		yourself
]

{ #category : #accessing }
FogBugzEvent >> attachements [
	^ attachements
]

{ #category : #accessing }
FogBugzEvent >> attachements: anObject [
	attachements := anObject
]

{ #category : #accessing }
FogBugzEvent >> case [
	^ case
]

{ #category : #accessing }
FogBugzEvent >> case: anObject [
	case := anObject
]

{ #category : #accessing }
FogBugzEvent >> changes [
	^ changes
]

{ #category : #accessing }
FogBugzEvent >> changes: anObject [
	changes := anObject
]

{ #category : #accessing }
FogBugzEvent >> comment [
	^ comment
]

{ #category : #accessing }
FogBugzEvent >> comment: anObject [
	comment := anObject
]

{ #category : #accessing }
FogBugzEvent >> date [
	^ date
]

{ #category : #accessing }
FogBugzEvent >> date: anObject [
	date := anObject
]

{ #category : #accessing }
FogBugzEvent >> description [
	^ description
]

{ #category : #accessing }
FogBugzEvent >> description: anObject [
	description := anObject
]

{ #category : #'instance creation' }
FogBugzEvent >> fromXML: xml [ 

	case := FogBugzCase id: ((xml attributeAt: 'ixBug') asInteger).
	id := (xml attributeAt: 'ixBugEvent') asInteger.
	attachements := Set new.

	comment := (xml findTag: 's')
						ifNil: [ '' ]
						ifNotNil: [:node | node children isEmpty
											ifTrue: [ node text ]
											ifFalse: [ node children first text ]].	
						
	date := xml dt text asDateAndTime.
	description := xml evtdescription next text.
	changes := (xml findTag: 'schanges') next name = 'sformat'
					ifTrue: [ nil ] 
					ifFalse: [ (xml findTag: 'schanges') next text trimBoth ].
					
	user := FogBugzUser
		id: (xml findTag: 'ixperson') next text asInteger
		username: (xml findTag: 'sperson') next text
		mail: nil.

	(xml findTag: 'rgattachments') children allButLast 		
		collect: [:node | 
			attachements 
			add: ((FogBugzAttachment event: id)
						fromXML: node;
						yourself) ].
]

{ #category : #testing }
FogBugzEvent >> hasChanges [

	^ changes notNil
]

{ #category : #accessing }
FogBugzEvent >> id [
	^ id
]

{ #category : #accessing }
FogBugzEvent >> id: anObject [
	id := anObject
]

{ #category : #accessing }
FogBugzEvent >> user [
	^ user
]

{ #category : #accessing }
FogBugzEvent >> user: anObject [
	user := anObject
]

{ #category : #accessing }
FogBugzEvent >> username [
	^ self user username
]
