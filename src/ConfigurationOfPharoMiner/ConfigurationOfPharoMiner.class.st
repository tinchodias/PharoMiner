Class {
	#name : #ConfigurationOfPharoMiner,
	#superclass : #Object,
	#instVars : [
		'project'
	],
	#classVars : [
		'LastVersionLoad'
	],
	#category : #ConfigurationOfPharoMiner
}

{ #category : #'development support' }
ConfigurationOfPharoMiner class >> DevelopmentSupport [

"See the methods in the 'development support' category on the class-side of MetacelloBaseConfiguration. Decide what development support methods you would like to use and copy them the the class-side of your configuration."
	<apiDocumentation>

]

{ #category : #private }
ConfigurationOfPharoMiner class >> baseConfigurationClassIfAbsent: aBlock [

	^Smalltalk
		at: #MetacelloBaseConfiguration
		ifAbsent: [ 
			self ensureMetacelloBaseConfiguration.
			Smalltalk at: #MetacelloBaseConfiguration ifAbsent: aBlock ].

]

{ #category : #private }
ConfigurationOfPharoMiner class >> ensureMetacello [

	(self baseConfigurationClassIfAbsent: []) ensureMetacello
]

{ #category : #private }
ConfigurationOfPharoMiner class >> ensureMetacelloBaseConfiguration [

	Smalltalk
		at: #MetacelloBaseConfiguration
		ifAbsent: [ 
			| repository version |
			repository := MCHttpRepository location: 'http://seaside.gemstone.com/ss/metacello' user: '' password: ''.
			repository
				versionReaderForFileNamed: 'Metacello-Base-DaleHenrichs.2.mcz'
				do: [ :reader | 
					version := reader version.
					version load.
					version workingCopy repositoryGroup addRepository: repository ] ]
]

{ #category : #'metacello tool support' }
ConfigurationOfPharoMiner class >> isMetacelloConfig [
	"Answer true and the Metacello tools will operate on you"
	
	^true
]

{ #category : #loading }
ConfigurationOfPharoMiner class >> load [
	"Load the #stable version defined for this platform. The #stable version is the version that is recommended to be used on this platform."

	"self load"

	<apiDocumentation>
	^(self project version: #stable) load
]

{ #category : #loading }
ConfigurationOfPharoMiner class >> loadBleedingEdge [
	"Load the latest versions of the mcz files defined for this project. It is not likely that the #bleedingEdge has been tested."

	"self loadBleedingEdge"

	<apiDocumentation>
	^(self project version: #bleedingEdge) load
]

{ #category : #loading }
ConfigurationOfPharoMiner class >> loadDevelopment [
	"Load the #development version defined for this platform. The #development version will change over time and is not expected to be stable."

	"self loadDevelopment"

	<apiDocumentation>
	^(self project version: #development) load
]

{ #category : #accessing }
ConfigurationOfPharoMiner class >> project [

	^self new project
]

{ #category : #'development support' }
ConfigurationOfPharoMiner class >> validate [
	"Check the configuration for Errors, Critical Warnings, and Warnings (see class comment for MetacelloMCVersionValidator for more information). 
	Errors identify specification issues that will result in unexpected behaviour when you load the configuration. 
	Critical Warnings identify specification issues that may result in unexpected behavior when you load the configuration.
	Warnings identify specification issues that are technically correct, but are worth take a look at."

	"self validate"

	<apiDocumentation>
	self ensureMetacello.
	^ ((Smalltalk at: #MetacelloToolBox) validateConfiguration: self debug: #() recurse: false) explore
]

{ #category : #baselines }
ConfigurationOfPharoMiner >> baseline01: spec [
	<version: '0.1-baseline'>

	spec for: #'common' do: [
		spec blessing: #'baseline'.
		spec repository: 'http://smalltalkhub.com/mc/MartinDias/PharoMiner/main/'.

		spec baseline: 'LibGit' with: [
			spec 
				repository: 'github://theseion/LibGit:master' ].

		spec
			project: 'CI' with: [
				spec
					className: #ConfigurationOfCI;
					versionString: #stable;
					repository: 'http://smalltalkhub.com/mc/Pharo/ci/main' ].

		spec package: #PharoVersionsMiner with: [
			spec requires: #('LibGit') ].
		spec package: #PharoMiner with: [
			spec requires: #('CI' 'PharoVersionsMiner') ].
		
		spec
			group: 'default' with: #('PharoMiner');
			group: 'core' with: #('PharoVersionsMiner').
	
	 ].

]

{ #category : #baselines }
ConfigurationOfPharoMiner >> baseline02: spec [
	<version: '0.2-baseline'>

	spec for: #'common' do: [
		spec blessing: #'baseline'.
		spec repository: 'http://smalltalkhub.com/mc/MartinDias/PharoMiner/main/'.

		spec baseline: 'LibGit' with: [
			spec 
				repository: 'github://jvdsandt/LibGit:pharo50';
				loads: #('development') ].

		spec
			project: 'CI' with: [
				spec
					className: #ConfigurationOfCI;
					versionString: #stable;
					repository: 'http://smalltalkhub.com/mc/Pharo/ci/main' ].

		spec package: #PharoVersionsMiner with: [
			spec requires: #('LibGit') ].
		spec package: #PharoMiner with: [
			spec requires: #('CI' 'PharoVersionsMiner') ].
		
		spec
			group: 'default' with: #('PharoMiner');
			group: 'core' with: #('PharoVersionsMiner').
	
	 ].

]

{ #category : #baselines }
ConfigurationOfPharoMiner >> baseline03: spec [
	<version: '0.3-baseline'>

	spec for: #'common' do: [
		spec blessing: #'baseline'.
		spec repository: 'http://smalltalkhub.com/mc/MartinDias/PharoMiner/main/'.

		spec
			project: 'CI' with: [
				spec
					className: #ConfigurationOfCI;
					versionString: #stable;
					repository: 'http://smalltalkhub.com/mc/Pharo/ci/main' ].

		spec package: #PharoVersionsMiner.
		spec package: #PharoMiner with: [
			spec requires: #('CI' 'PharoVersionsMiner') ].
		
		spec
			group: 'default' with: #('PharoMiner');
			group: 'core' with: #('PharoVersionsMiner').
	
	 ].

]

{ #category : #accessing }
ConfigurationOfPharoMiner >> customProjectAttributes [
	 "Edit to return a collection of any custom attributes e.g. for conditional loading: Array with: #'Condition1' with: #'Condition2.
	For more information see: http://code.google.com/p/metacello/wiki/CustomProjectAttrributes"

	^ #().
]

{ #category : #'symbolic versions' }
ConfigurationOfPharoMiner >> development: spec [
	<symbolicVersion: #'development'>

	spec for: #'pharo5.x' version: '0.2-baseline'.
	spec for: #'pharo6.x' version: '0.3-baseline'.
	spec for: #'pharo7.x' version: '0.3-baseline'.

]

{ #category : #accessing }
ConfigurationOfPharoMiner >> project [

	^ project ifNil: [ 
		"Bootstrap Metacello if it is not already loaded"
		(self class baseConfigurationClassIfAbsent: []) ensureMetacello.
		"Construct Metacello project"
		project := MetacelloMCProject new projectAttributes: self customProjectAttributes. 
		(Smalltalk at: #MetacelloVersionConstructor) on: self project: project.
		project loadType: #linear. "change to #atomic if desired"
		project ]
]

{ #category : #versions }
ConfigurationOfPharoMiner >> version10: spec [
	<version: '1.0' imports: #('0.1-baseline' )>

	spec for: #'common' do: [
		spec blessing: #'development'.
		spec description: 'version 1.0'.
		spec author: 'MartinDias'.
		spec timestamp: '6/25/2015 11:28'.
		spec 
			baseline: 'LibGit' with: 'baseline';
			project: 'CI' with: #'stable'.
		spec 
			package: #PharoVersionsMiner with: 'PharoVersionsMiner-MartinDias.5';
			package: #PharoMiner with: #PharoMiner. ].

]
