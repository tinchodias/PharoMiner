Extension { #name : #SoupTag }

{ #category : #'*CI-FogBugzAPI' }
SoupTag >> findTagText: tagName default: defaultValue [
	^ (self findTag: tagName)
		ifNotNil: [ :tag | tag text ]
		ifNil: [ defaultValue ]  
]
