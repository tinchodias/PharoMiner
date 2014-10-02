Extension { #name : #FogBugzEvent }

{ #category : #'*PharoMiner' }
FogBugzEvent >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' ('.
	id printOn: aStream.
	aStream nextPutAll: ' - '.
	description printOn: aStream.
	aStream nextPutAll: ')'.
]
