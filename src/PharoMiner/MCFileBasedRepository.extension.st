Extension { #name : #MCFileBasedRepository }

{ #category : #'*PharoMiner' }
MCFileBasedRepository >> fileNamesForPackageNamed: packageName [ 

	^ Array streamContents: [ :stream | 
		self allFileNamesOrCache do: [ :aFileName | 
			(aFileName copyUpToLast: $-) = packageName ifTrue: [ stream nextPut: aFileName ] ] ]
]
