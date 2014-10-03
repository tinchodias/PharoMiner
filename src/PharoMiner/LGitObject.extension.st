Extension { #name : #LGitObject }

{ #category : #'*PharoMiner' }
LGitObject >> object_lookup_bypath: out treeish: treeish path: path type: type [ 
	<primitive: #primitiveNativeCall module: #NativeBoostPlugin error: errorCode>
	"TODO: LGitReturnCodeEnum"
	^self call: #(int git_object_lookup_bypath(LGitObject * out, LGitTree treeish, String path, LG2GitOtypeE type)) options: #(  )
]
