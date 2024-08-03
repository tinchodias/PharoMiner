"
A FogBugzAPITest is a test class for testing the behavior of FogBugzAPI
"
Class {
	#name : #FogBugzAPITest,
	#superclass : #TestCase,
	#category : #'CI-FogBugzAPI-Tests'
}

{ #category : #accessing }
FogBugzAPITest >> password [
	^ Smalltalk os environment at: 'PHARO_CI_PWD' ifAbsent: nil.
]

{ #category : #'tests identifying' }
FogBugzAPITest >> testGetListOfReviewNeededIssues [
	| client issues |
	
	client := FogBugzTracker pharo logOnWithEmail: self user password: self password .
	issues := client getAllReviewNeededIssues.
	self assert: (issues allSatisfy: [:e | e isKindOf: FogBugzCase ])
]

{ #category : #'tests identifying' }
FogBugzAPITest >> testRetrieveIdentifyingTokenFormServer [
	| client |
	
	client := FogBugzTracker pharo logOnWithEmail: self user password: self password.
	self assert: client identifyingToken size equals: 30
]

{ #category : #'tests identifying' }
FogBugzAPITest >> testSetNewTagAndCommentForIssue9 [
	| client issues |
	self skip: 'Causes too much noise'.
	client := FogBugzTracker pharo logOnWithEmail: self user password: self password.
	issues := client editIssue: 9 withArguments: (Dictionary new
														at: 'sEvent' put: 'Communicating from Pharo';
														at: 'sTags' put: 'PharoIsCOOOOOL';
														at: 'sStatus' put: 'WorkNeeded';
														yourself).
]

{ #category : #accessing }
FogBugzAPITest >> user [
	^ Smalltalk os environment at: 'PHARO_CI_USER' ifAbsent: nil.
]
