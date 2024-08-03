"
I am an attachment for the FogBugz issue tracker.
I am attached to an event
"
Class {
	#name : #FogBugzAttachment,
	#superclass : #Object,
	#instVars : [
		'event',
		'url',
		'attachementName'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzAttachment class >> event: parent [

	^ self new
		event: parent;
		yourself
]

{ #category : #accessing }
FogBugzAttachment >> attachementName [
	^ attachementName
]

{ #category : #accessing }
FogBugzAttachment >> attachementName: anObject [
	attachementName := anObject
]

{ #category : #accessing }
FogBugzAttachment >> event [
	^ event
]

{ #category : #accessing }
FogBugzAttachment >> event: anObject [
	
	event := anObject
]

{ #category : #'instance creation' }
FogBugzAttachment >> fromXML: xml [
 
	attachementName := (xml findTag: 'sfilename') children first text.
	url := (xml findTag: 'surl') children first text.
]

{ #category : #accessing }
FogBugzAttachment >> url [
	^ url
]

{ #category : #accessing }
FogBugzAttachment >> url: anObject [
	url := anObject
]
