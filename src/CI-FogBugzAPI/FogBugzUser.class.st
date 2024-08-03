"
I am a FogBugz user.

I implement a flyweight to ensure users are unique per id
"
Class {
	#name : #FogBugzUser,
	#superclass : #Object,
	#instVars : [
		'id',
		'mail',
		'username'
	],
	#classInstVars : [
		'users'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzUser class >> id: id username: username mail: mail [
	| user |
	
	user := self users 
				detect: [ :each | each id = id ] 
				ifNone: [ | newUser |
					newUser := super new 
									id: id;
									yourself.
					self users add: newUser.
					newUser ].

	^ user	
		mail: mail;
		username: username;
		yourself
]

{ #category : #'as yet unclassified' }
FogBugzUser class >> users [

        ^ users ifNil: [ users := Set new ]
]

{ #category : #accessing }
FogBugzUser >> id [
	^ id
]

{ #category : #accessing }
FogBugzUser >> id: anObject [
	id := anObject
]

{ #category : #accessing }
FogBugzUser >> mail [
	^ mail
]

{ #category : #accessing }
FogBugzUser >> mail: anObject [
	mail := anObject
]

{ #category : #printing }
FogBugzUser >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: '( '.
	self id printOn: aStream.
	aStream nextPutAll: ' - '.
	self username printOn: aStream.
	aStream nextPutAll: ' - '.
	self mail printOn: aStream.
	aStream nextPutAll: ' )'.
]

{ #category : #accessing }
FogBugzUser >> username [
	^ username
]

{ #category : #accessing }
FogBugzUser >> username: anObject [
	username := anObject
]
