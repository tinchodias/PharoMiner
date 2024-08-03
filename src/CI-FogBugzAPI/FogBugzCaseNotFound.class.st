"
I get signaled when a case with a specific id is looked up and not found
"
Class {
	#name : #FogBugzCaseNotFound,
	#superclass : #Error,
	#instVars : [
		'id'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #accessing }
FogBugzCaseNotFound >> id [
	^ id
]

{ #category : #accessing }
FogBugzCaseNotFound >> id: anObject [
	id := anObject
]
