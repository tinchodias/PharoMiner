"
I a raised when an error occured during the identifaction phase
"
Class {
	#name : #FogBugzIdentificationError,
	#superclass : #Error,
	#instVars : [
		'response'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #'instance creation' }
FogBugzIdentificationError class >> response: queryRespons [
 
	^ self new
		response: queryRespons;
		yourself
]

{ #category : #accessing }
FogBugzIdentificationError >> response: queryResponse [
	
	 response := queryResponse
]
