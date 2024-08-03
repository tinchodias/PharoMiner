Class {
	#name : #BaselineOfPharoMiner,
	#superclass : #BaselineOf,
	#category : #BaselineOfPharoMiner
}

{ #category : #baselines }
BaselineOfPharoMiner >> baseline: spec [
	<baseline>

	spec for: #common do: [
		spec package: #PharoVersionsMiner.

		spec
			baseline: 'Soup'
			with: [ spec repository: 'github://pharo-contributions/Soup/' ].

		"Package 'CI-FogBugzAPI' was extracted from http://smalltalkhub.com/Pharo/ci/"
		spec
			package: #'CI-FogBugzAPI'
			with: [ spec requires: #( 'Soup' ) ].

		spec
			package: #PharoMiner
			with: [ spec requires: #( 'CI-FogBugzAPI' 'PharoVersionsMiner' ) ].

		spec
			group: 'default' with: #( 'PharoMiner' );
			group: 'core' with: #( 'PharoVersionsMiner' ) ]
]
