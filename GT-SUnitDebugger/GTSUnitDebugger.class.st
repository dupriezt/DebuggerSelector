"
I am a custom debugger for SUnit.
I embed a textual diff when an #assert:equals: assertion fails and provide access to the setUp/tearDown methods of a test.

"
Class {
	#name : #GTSUnitDebugger,
	#superclass : #GTGenericStackDebugger,
	#category : #'GT-SUnitDebugger'
}

{ #category : #testing }
GTSUnitDebugger class >> availableAutomatically [
	"Should this debugger be taken into account when looking for a debugger to handle an exception."
	
	^ true
]

{ #category : #accessing }
GTSUnitDebugger class >> defaultTitle [

	^ 'SUnit'
]

{ #category : #testing }
GTSUnitDebugger class >> handlesContext: aContext [
	| activationPredicate |
	activationPredicate := self sessionClass activationPredicate.
	^ (aContext stackOfSize: self lookupStackSize) 
		anySatisfy: [ :ctx | activationPredicate matches: ctx ] 
]

{ #category : #accessing }
GTSUnitDebugger class >> helpClass [
	^ GTSUnitDebuggerHelp
]

{ #category : #'debugger declaration' }
GTSUnitDebugger class >> iAmADebugger [
	"Leave blank for intermediate classes. Add the <iAmADebugger> pragma for concrete debugger classes. This pragma is used by the system to find all available debuggers"
	<iAmADebugger>
]

{ #category : #testing }
GTSUnitDebugger class >> lookupStackSize [
	^ 512
]

{ #category : #accessing }
GTSUnitDebugger class >> openOn: aDebugSession withFullView: aBool andNotification: aString [
	| newDebugSession debugger |
	newDebugSession := (self spanNewSessionFrom: aDebugSession).
	debugger := super openOn: newDebugSession withFullView: aBool andNotification: aString.
	newDebugSession stopKeepingAlive: debugger. "To undo the #keepAlive: done by GTMoldableDebugger>>#openOn:WithFullView:andNotification:"
	debugger originalSession: aDebugSession.
	aDebugSession keepAlive: debugger.
]

{ #category : #'debugger declaration' }
GTSUnitDebugger class >> rank [
	^ 100
]

{ #category : #'debugger declaration' }
GTSUnitDebugger class >> rankDebugSession: aDebugSession [
	"Returns an integer representing how much this debugger is suitable to debug @aDebugSession. The higher the integer returned, the more suitable this debugger is. Signal the DebugSessionCannotBeOpenedByThisDebugger exception if this debugger absolutely cannot debug @aDebugSession (for example if this debugger can only handle debug sessions from test executions, and @aDebugSession does not come from a test execution)"
	(self handlesContext: aDebugSession interruptedContext) ifTrue: [ ^ self rank ] ifFalse: [ DebugSessionCannotBeOpenedByThisDebugger signal ]
]

{ #category : #'tools registry' }
GTSUnitDebugger class >> register [

	self registerToolsOn: Smalltalk tools.
]

{ #category : #'tools registry' }
GTSUnitDebugger class >> registerToolsOn: registry [

	"Add ourselves to registry. See [Smalltalk tools]" 
	registry registerDebugger: self withRank: 70.
]

{ #category : #accessing }
GTSUnitDebugger class >> sessionClass [

	^ GTSUnitDebugSession
]

{ #category : #'accessing context' }
GTSUnitDebugger >> contextToSelectFrom: aSession [
	^ aSession assertionCallerContext ifNil: [ aSession testContext ]
]

{ #category : #'building presentations' }
GTSUnitDebugger >> inspectorDiffIn: aComposite [

	^ aComposite tabulator 
		with: [ :aTabulator |
			aTabulator when: [ self session supportsDiff].
			aTabulator 
				column: #actual;
				column: #expected.
			aTabulator transmit to: #actual; andShow: [ :anotherComposite |
				anotherComposite  dynamic 
					display: [:anObject |
				 		(GTDebuggerInspector new 
							startOn: self session actualResult) ] ].
			aTabulator transmit to: #expected; andShow: [ :anotherComposite |
				anotherComposite  dynamic 
					display: [:anObject |
				 		(GTDebuggerInspector new 
							startOn: self session expectedResult) ] ] ]
]

{ #category : #'building presentations' }
GTSUnitDebugger >> inspectorIn: aComposite [

	(self textualDiffIn: aComposite) title: 'Diff (actual vs. expected)'.
	(self inspectorDiffIn: aComposite) title: 'Objects (actual vs. expected)'.
	super inspectorIn: aComposite.
	self session supportsDiff ifTrue: [ 
		aComposite last title: 'Inspector' ]
]

{ #category : #'building presentations' }
GTSUnitDebugger >> setUpCodeIn: aComposite [

	aComposite pharoMethod
		title: [ self setUpPresentationTitle ];
		format: [ self session setUpMethod sourceCode ];
		smalltalkClass: [  self session testObject class ];
		when: [ self session overridesDefaultSetUpMethod ];
		doItReceiver: [ self session testObject ].
]

{ #category : #'accessing context' }
GTSUnitDebugger >> setUpPresentationTitle [

	^ 'SetUp', 
		(self session setUpMethod methodClass ~= self session testContext methodClass
			ifTrue: [ ' (', self session setUpMethod methodClass name,')' ]
			ifFalse: [ '' ])
]

{ #category : #'building presentations' }
GTSUnitDebugger >> tearDownCodeIn: aComposite [

	aComposite pharoMethod
		title: [ self tearDownPresentationTitle ];
		format: [ self session tearDownMethod sourceCode ];
		smalltalkClass: [  self session testObject class ];
		when: [ self session overridesDefaultTearDownMethod ];
		doItReceiver: [ self session testObject ].
]

{ #category : #'accessing context' }
GTSUnitDebugger >> tearDownPresentationTitle [

	^ 'TearDown', 
		(self session tearDownMethod methodClass ~= self session testContext methodClass
			ifTrue: [ ' (', self session tearDownMethod methodClass name,')' ]
			ifFalse: [ '' ])
]

{ #category : #'building presentations' }
GTSUnitDebugger >> textualDiffIn: composite [

	^ composite diff
			when: [ self session supportsDiff];
			display: [ 
				{self session actualResult gtDebuggerSUnitPrint. self session expectedResult gtDebuggerSUnitPrint} ]
]

{ #category : #building }
GTSUnitDebugger >> transmitFromStackToCodeIn: browser [
	browser transmit
		from: #stack port: #selection;
		to: #code;
		andShow: [ :composite :aContext | 
			self methodCodeIn: composite forContext: aContext.
			self setUpCodeIn: composite.
			self tearDownCodeIn: composite ]
]

{ #category : #updating }
GTSUnitDebugger >> updateBrowser [

	super updateBrowser.
	"The transmission will select the context of the test case. 
	This should only happen the first time.
	Should find another solution so this method doesn;t have to be overridden"
	((self browser paneNamed: #stack) port: #selection) value: self session interruptedContext
]
