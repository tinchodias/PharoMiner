"
I am a FogBugz tracker. I am the entry point

Example:

	| projects |
	projects := FogBugzTracker pharo
		logOnWithEmail: 'emailAddress' password: 'password';
		projects
"
Class {
	#name : #FogBugzTracker,
	#superclass : #Object,
	#instVars : [
		'identifyingToken',
		'projects',
		'hostname'
	],
	#category : #'CI-FogBugzAPI'
}

{ #category : #private }
FogBugzTracker class >> columnsToQuery [
	^ #(
	sTitle
	sCategory
	ixProject
	sProject
	events
	tags
	sFixFor
	dtLastUpdated
	dtOpened
	dtResolved
	dtClosed
	sStatus
	configurationof
	configurationversion
	preload
	postload)
]

{ #category : #'instance creation' }
FogBugzTracker class >> email: emailAddress password: password [

	^ self new
		logOnWithEmail: emailAddress password: password;
		yourself
]

{ #category : #private }
FogBugzTracker class >> extractErrorMessage: aResponse [
	self shouldBeImplemented
]

{ #category : #queries }
FogBugzTracker class >> extractTokenFrom: response [

	| startIdentifier stopIdentifier firstIndex offset lastIndex |

	startIdentifier := self startTokenResponseIdentifier.
	stopIdentifier := self stopTokenResponseIdentifier.

	firstIndex := response findString: startIdentifier.
	offset := startIdentifier size.
	lastIndex := response findString: stopIdentifier startingAt: firstIndex.

	^ response copyFrom: firstIndex+offset to: lastIndex-1
]

{ #category : #private }
FogBugzTracker class >> extractXMLErrorMessage: aResponse [
	^ ((Soup fromString: aResponse) findTag: 'error') string
]

{ #category : #'instance creation' }
FogBugzTracker class >> forProject: aHostname [

	^ self new
		hostname: aHostname;
		yourself
]

{ #category : #constants }
FogBugzTracker class >> hostname [

	^ 'https://pharo.fogbugz.com'
]

{ #category : #'instance creation' }
FogBugzTracker class >> identifyingToken: token [ 
	
	^ self new 
		identifyingToken: token ;
		yourself
]

{ #category : #'instance creation' }
FogBugzTracker class >> penelope [

	^ self pharo
]

{ #category : #'instance creation' }
FogBugzTracker class >> pharo [

	^ self forProject: 'pharo'
]

{ #category : #constants }
FogBugzTracker class >> pharoIssueTrackerURL [

	^ self hostname, '/api.asp?' 
]

{ #category : #private }
FogBugzTracker class >> sendFileWithArguments: arguments ifError: aBlock [
 	| client entity response files |
	
	client := ZnClient new
				url: self pharoIssueTrackerURL;
				yourself.
	
	entity := client multiPartFormDataEntity.
	files := arguments associations select:[ :e | e key beginsWith: 'File' ].
	files do: [:association |
		entity addPart: (ZnMimePart 
			fieldName: association key 
			fileName: association value asFileReference basename 
			entity: (ZnEntity bytes: association value asFileReference readStream binary contents)) ].
				
	arguments associationsDo: [:association | 
		client queryAt: association key put: association value ].
	
	response := client post.
	client response isError  ifTrue: aBlock.
	^ response
]

{ #category : #private }
FogBugzTracker class >> sendRequestWithArguments: arguments [
	| event groupOf lastIndex text |
	
	event := arguments at: 'sEvent' ifAbsent: ''.	
	groupOf := 750.
	
	event groupsOf: groupOf atATimeDo: [:collection |
		text := String streamContents: [:s | collection do: [:c | s nextPut: c ]].
		arguments at: 'sEvent' put: text.
		self sendRequestWithArguments: arguments ifError: [ :message| self error: message ]].
	
	lastIndex := (event size // groupOf) * groupOf.
	text := event copyFrom: lastIndex + 1 to: event size.
	arguments at: 'sEvent' put: text.
	
	^ self sendRequestWithArguments: arguments ifError: [ :message| self error: message ]
]

{ #category : #private }
FogBugzTracker class >> sendRequestWithArguments: arguments ifError: aBlock [
 	| client response |
	
	(arguments keys anySatisfy: [ :key | key beginsWith: 'File' ])
		ifTrue: [ ^ self sendFileWithArguments: arguments ifError: aBlock ].
	
	client := ZnClient new
				url: self pharoIssueTrackerURL;
				yourself.
				
	arguments keysAndValuesDo: [ :key :value | 
		client formAt: key put: value ].
	
	response := client post.
	client response isError 
		ifTrue: [ aBlock cull: (self extractErrorMessage: client response) ].
	self validateXML: response ifError: aBlock.
	^ response
]

{ #category : #constants }
FogBugzTracker class >> startTokenResponseIdentifier [

	^ '![CDATA['
]

{ #category : #constants }
FogBugzTracker class >> stopTokenResponseIdentifier [

	^ ']]'
]

{ #category : #private }
FogBugzTracker class >> validateXML: response ifError: aBlock [
	"Manually check if the response contains an error message from fogbugz.
	Most probably this is a bug since the http response is not flagged as an error"
	
	(response endsWith: ']]></error></response>')
		ifTrue: [ aBlock cull: (self extractXMLErrorMessage: response) ]
]

{ #category : #private }
FogBugzTracker >> analyzeLabels: col andFill: arguments [
	| tags |
	
	(self extractCategoryFrom: col)
		ifNotNil: [:category | arguments at: 'sCategory' put: category ].
		
	(self extractMilestoneFrom: col)
		ifNotNil: [:milestone | arguments at: 'sFixFor' put: milestone ].
		
	(self extractPriorityFrom: col)
		ifNotNil: [:priority | arguments at: 'sPriority' put: priority ].
		
	(self containsHorribleError: col)
		ifTrue: [ arguments at: 'sPriority' put: '1- Show Stopper !!!!!!' ].

	tags := self rejectInvalidLabelsFrom: col.
	tags ifNotEmpty: [	arguments at: 'sTags' put: (tags joinUsing:',') ]
]

{ #category : #querying }
FogBugzTracker >> availableStates [
	| rawStatuses |
	
	rawStatuses := self sendRequestWithArguments: {'cmd' -> 'listStatuses'} asDictionary.
	^ (FogBugzStatus buildStatusesFrom: rawStatuses) select: #isActive
]

{ #category : #editing }
FogBugzTracker >> closeIssue: id [
	| arguments response |

	
	arguments := Dictionary new
		at: 'cmd' put: 'close';
		at: 'ixBug' put: id asString;
		yourself.

	response := self sendRequestWithArguments: arguments.
	self flag: 'analyse response for error'.
	^ response
]

{ #category : #tools }
FogBugzTracker >> closeOldIssues [

	| issues |
	issues := self getIssuesForQuery: 'status:Open orderBy:"-lastupdated"' max: 5.
	issues do: [ :each | 
		DateAndTime now - each lastModification > 1 year ifTrue: [ 
			each 
				statusStaleTimeout;
				saveStatus: 'Pharo is moving fast: We release a new major version every year, with many, many changes.
Issue tracker entries tend to get stale after a new release. Bugs are fixed, subsystems
replaced or removed.

After seeing many out-dated, very old issues staying around forever, we have adopted the
following policy:

- Issues that do not see ​*any*​ activity are closed autmatically after one year of inactivity.
- This is done by a completely automated job which closes up to 5 issues per day older than
one year.

The issue can (and should!) be re-opened if it is still relavant in the current development
version!';
				close
			 ]				
 	]
]

{ #category : #querying }
FogBugzTracker >> closedIssues [

	^ self getIssuesForQuery: 'status:closed'
]

{ #category : #private }
FogBugzTracker >> columnsToQuery [
	"A list of columns to query to be used in the #getIssuesFor:... methods"
	^String streamContents: [ :stream | 
		self class columnsToQuery 
			asStringOn: stream 
			delimiter: ',' ]
]

{ #category : #private }
FogBugzTracker >> containsHorribleError: collection [

	^ collection includes: 'Type-HorribleErrorBlockingEverything'
]

{ #category : #editing }
FogBugzTracker >> editIssue: id withArguments: arguments [
	| response |

	arguments 	
		at: 'cmd' put: 'edit';
		at: 'ixBug' put: id asString.

	response := self sendRequestWithArguments: arguments.
	self flag: 'analyse response for error'.
	^ response
]

{ #category : #private }
FogBugzTracker >> extractCategoryFrom: collection [
	| type |
	
	type := collection detect: [:e | e beginsWith: 'Type-' ] ifNone: [ ^ nil ].
	type := type copyFrom: 6 to: type size.
	
	type = 'Bug' ifTrue: [ ^ 'Bug' ].
	type = 'FirstImpressionsCount' ifTrue: [ ^ 'First Impressions Counts' ].
	type = 'Feature' ifTrue: [ ^ 'Feature' ].
	type = 'Enh' ifTrue: [ ^ 'Enhancement' ].
	type = 'Cleanup' ifTrue: [ ^ 'Cleanup' ].
	type = 'FailingTest' ifTrue: [ ^ 'Failing Test' ].

	^ nil
]

{ #category : #private }
FogBugzTracker >> extractMilestoneFrom: collection [
	| milestone dashIndex |
	
	milestone := collection detect: [:e | e beginsWith: 'Milestone-' ] ifNone: [ ^ nil ].
	milestone := 'Pharo', (milestone copyFrom: 11 to: milestone size).
	dashIndex := milestone indexOf: $-.

	^ dashIndex isZero
		ifTrue: [ milestone ]
		ifFalse: [ milestone copyFrom: 1 to: dashIndex-1 ]

]

{ #category : #private }
FogBugzTracker >> extractPriorityFrom: collection [
	| priority |
	
	priority := collection detect: [:e | e beginsWith: 'Importance-' ] ifNone: [ ^ nil ].
	priority := priority copyFrom: 12 to: priority size.
	
	priority = 'Low' ifTrue: [ ^ '4 - Fix if Time' ].
	priority = 'High' ifTrue: [ ^ '5 - Really Important' ].

	^ nil
]

{ #category : #querying }
FogBugzTracker >> getAllProjects [
	| rawProjects |
	
	rawProjects := self sendRequestWithArguments: {'cmd' -> 'listProjects'} asDictionary.
	^ FogBugzProject buildProjectsFrom: rawProjects
]

{ #category : #querying }
FogBugzTracker >> getAllReviewNeededIssues [
	
	^ self getIssuesForQuery: 'status:ReviewNeeded'
]

{ #category : #querying }
FogBugzTracker >> getIssueWithID: id [

	^ (self getIssuesForQuery: 'ixbug:', id asString)
		ifEmpty: [ 
			FogBugzCaseNotFound new 
				id: id; 
				signal ]
		ifNotEmpty: [ :cases | cases first ]
]

{ #category : #private }
FogBugzTracker >> getIssuesForQuery: query [
	^ self 
		getIssuesForQuery: query 
		max: nil
]

{ #category : #private }
FogBugzTracker >> getIssuesForQuery: query max: maxSize [
	| arguments rawIssues |
	
	arguments := Dictionary new
		at: 'cmd' put: 'search';
		at: 'q' put: query;
		at: 'cols' put: self columnsToQuery;
		yourself.
		
	maxSize ifNotNil: [ 
		arguments at: 'max' put: maxSize asString ].
					
	rawIssues := self sendRequestWithArguments: arguments.
	^ FogBugzCase 
		buildIssuesFrom: rawIssues
		tracker: self
]

{ #category : #querying }
FogBugzTracker >> getIssuesWithIDs: ids [
	^ ids collect: [ :id | self getIssueWithID: id ]
]

{ #category : #querying }
FogBugzTracker >> getRawIssuesForProject: aString [ 
	| arguments |
	
	arguments := Dictionary new
		at: 'cmd' put: 'search';
		at: 'q' put: 'status:open project:', aString;
		at: 'cols' put: 'sTitle,sCategory,ixProject,sProject,events,tags,sFixFor,dtLastUpdated,dtOpened,dtResolved,dtClosed,sStatus';
		yourself.
	
	^ self sendRequestWithArguments: arguments
]

{ #category : #accessing }
FogBugzTracker >> hostname [

	^ hostname
]

{ #category : #accessing }
FogBugzTracker >> hostname: aString [

 	hostname := aString
]

{ #category : #accessing }
FogBugzTracker >> identifyingToken [
	
	^ identifyingToken
]

{ #category : #accessing }
FogBugzTracker >> identifyingToken: token [

	identifyingToken := token
]

{ #category : #querying }
FogBugzTracker >> informationAboutProject: id [

	^ self sendRequestWithArguments: (Dictionary new
		at: 'cmd' put: 'viewProject';
		at: 'ixProject' put: id asString;
		yourself)
]

{ #category : #testing }
FogBugzTracker >> isAuthenticated [

	^ self identifyingToken notNil
]

{ #category : #testing }
FogBugzTracker >> isLoggedIn [ 
	^ self isAuthenticated
]

{ #category : #querying }
FogBugzTracker >> issueWithId: id [
	^ self getIssueWithID: id
]

{ #category : #querying }
FogBugzTracker >> issues: statusCollection milestone: aString [
	| status |
	
	status := String streamContents: [ :stream | 
		statusCollection 
			do: [ :each | stream << 'status:"' << each << '"' ]
			separatedBy: [ stream << ' OR ' ] ].
	
	^ self getIssuesForQuery: '(', status, ' AND milestone:"Pharo', aString, '")'
]

{ #category : #private }
FogBugzTracker >> knownLabels [
	
	^ #( 'Type-Bug' 'Type-FirstImpressionsCount' 'Type-Cleanup' 'Type-Enh' 'Type-FailingTest' 'Type-Feature' 'Type-HorribleErrorBlockingEverything'
	'Target-Collection' 'Target-Command' 'Target-Debugging' 'Target-File' 'Target-Fuel' 'Target-Jenkins' 'Target-Monticello' 'Target-Morphic' 'Target-NativeBoost' 'Target-Nautilus' 'Target-Network' 'Target-Opal' 'Target-Pharo' 'Target-RPackage' 'Target-Seed' 'Target-Spec' 'Target-Trait' 'Target-UI'
	'Milestone-1.0' 'Milestone-1.1' 'Milestone-1.2' 'Milestone-1.3' 'Milestone-1.4' 'Milestone-2.0' 'Milestone-3.0'
	'Importance-Low' 'Importance-High')
]

{ #category : #logging }
FogBugzTracker >> logOff [
	self sendRequestWithArguments: {'cmd'->'logoff'} asDictionary.
	identifyingToken := nil
]

{ #category : #logging }
FogBugzTracker >> logOnWithEmail: emailAddress password: password [
	| arguments response token |

	arguments := Dictionary new 
					at: 'cmd' put: 'logon';
					at: 'email' put: emailAddress;
					at: 'password' put: password;
					yourself.
					
	response := self sendRequestWithArguments: arguments ifError: [ :message |
			FogBugzIdentificationError signal: message ].
		
	token := self class extractTokenFrom: response.
	^ self identifyingToken: token.
]

{ #category : #editing }
FogBugzTracker >> newIssueTitled: aName ownedBy: aOwner description: description category: category milestone: milestone tags: tags project: project [
	| response arguments xml id |

	arguments := Dictionary new
		at: 'cmd' put: 'new';
		at: 'sPersonAssignedTo' put: aOwner;
		at: 'sTitle' put: aName;
		at: 'sProject' put: project;
		yourself.

	category
		ifNotNil: [ arguments at: 'sCategory' put: category ].
		
	milestone
		ifNotNil: [ arguments at: 'sFixFor' put: milestone ].
		
	tags ifNotEmpty: [	arguments at: 'sTags' put: (tags joinUsing:',') ].
		
	response := self 
		sendRequestWithArguments:arguments
		ifError: [ self error: 'TODO: Send a proper one' ].
		
	xml := Soup fromString: response contents.
	id := (xml / 'response') child first @ 'ixBug'.
	 
	^ self getIssueWithID: id asInteger
]

{ #category : #editing }
FogBugzTracker >> newIssueTitled: aName ownedBy: aOwner description: description tags: tags project: project [
	| response arguments xml id |

	arguments := Dictionary new
		at: 'cmd' put: 'new';
		at: 'sPersonAssignedTo' put: aOwner;
		at: 'sTitle' put: aName;
		at: 'sProject' put: project;
		yourself.

	self analyzeLabels: tags andFill: arguments.

	description ifNotNil: [ arguments at: 'sEvent' put: description ].

	response := self 
		sendRequestWithArguments:arguments
		ifError: [ self error: 'TODO: Send a proper one' ].
		
	xml := Soup fromString: response contents.
	id := (xml / 'response') child first @ 'ixBug'.
	 
	^ self getIssueWithID: id asInteger
]

{ #category : #querying }
FogBugzTracker >> nextIssueQuery [
	^ 'status:"Fix Review"',
	'status:open ',
	'-milestone:Later ',
	'milestone:"Pharo', SystemVersion current dottedMajorMinor,'" ',
	'-tag:noMonkey ',
	'sort:priority ' 
]

{ #category : #querying }
FogBugzTracker >> nextIssueToBeChecked [
	
	^ (self getIssuesForQuery: self nextIssueQuery max: 50)
		ifEmpty: [ nil ]
		ifNotEmpty: [ :issues | 
			issues 
				detect: [ :issue | issue shouldBeChecked ] 
				ifNone: [ nil ]]
]

{ #category : #querying }
FogBugzTracker >> openIssues [

	^ self getIssuesForQuery: 'status:open'
]

{ #category : #querying }
FogBugzTracker >> projects [
	
	^ projects ifNil: [ projects := [ self getAllProjects ] on: Error do: [ #() ] ]
]

{ #category : #querying }
FogBugzTracker >> readyForIntegrationIssuesMilestone: aString [
	^ self 
		issues: #(
			'Resolved (Fix To Include)' 
			'Resolved (Fix Reviewed by the Monkey)'
			'Resolved (Fix Review Needed)')
		milestone: aString
]

{ #category : #private }
FogBugzTracker >> refreshProjects [
	| newProjects |

	[ newProjects := self getAllProjects ] on: Error do: [ :ex | ^ self ].
	projects := newProjects
]

{ #category : #registering }
FogBugzTracker >> registerEmail: email [
	| fullName indexOfAt indexOfPlus index |
	
	indexOfAt := email indexOf: $@.
	indexOfPlus := email indexOf: $+.
	
	index := 
		indexOfAt isZero 
			ifTrue: [ indexOfPlus ]
			ifFalse: [ indexOfPlus isZero
						ifTrue: [ indexOfAt ]
						ifFalse: [ indexOfAt min: indexOfPlus ]].
	
	fullName := email copyFrom:1 to: index -1.
	
	^ self registerUserNamed: fullName email: email password: 'random'
]

{ #category : #registering }
FogBugzTracker >> registerUserNamed: fullName email: email [

	^ self registerUserNamed: fullName email: email password: 'random'
]

{ #category : #registering }
FogBugzTracker >> registerUserNamed: fullName email: email password: password [

	^ self registerUserNamed: fullName email: email password: password type: 0
]

{ #category : #registering }
FogBugzTracker >> registerUserNamed: fullName email: email password: password type: type [
	^ self sendRequestWithArguments: (Dictionary new
		at: 'cmd' put: 'newPerson';
		at: 'sEmail' put: email;
		at:'sFullname' put: fullName;
		at: 'sPassword' put: password;
		at: 'nType' put: type asString;
		yourself)
]

{ #category : #private }
FogBugzTracker >> rejectInvalidLabelsFrom: aCollection [

	^ aCollection reject:[ :e | self knownLabels anySatisfy:[ :label | e beginsWith: label ]]
]

{ #category : #tools }
FogBugzTracker >> resumeHangedIssues [

	| issues |
	issues := self getIssuesForQuery: 'status:"Resolved (Monkey is checking)" orderBy:"-lastupdated"' max: 5.
	issues do: [ :each | 
		each isHangingOnMonkeyCheck ifTrue: [ 
			each 
				statusFixReviewNeeded;
				saveStatus: 'Check seems to be stuck. I will try it again'
			 ]				
 	]
]

{ #category : #private }
FogBugzTracker >> sendRequestWithArguments: arguments [

	arguments at: 'token' put: self identifyingToken.
	^ self class sendRequestWithArguments: arguments
]

{ #category : #private }
FogBugzTracker >> sendRequestWithArguments: arguments ifError: aBlock [ 

	arguments at: 'token' put: self identifyingToken.
	^ self class 
		sendRequestWithArguments: arguments 
		ifError: aBlock
]

{ #category : #updating }
FogBugzTracker >> update [
	self refreshProjects
]
