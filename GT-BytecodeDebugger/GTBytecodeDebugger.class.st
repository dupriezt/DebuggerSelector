"
I am a debugger that provides the ability to step through the execution at the bytecode level (e.g. one bytecode at a time).
"
Class {
	#name : #GTBytecodeDebugger,
	#superclass : #GTGenericStackDebugger,
	#category : #'GT-BytecodeDebugger-UI'
}

{ #category : #accessing }
GTBytecodeDebugger class >> defaultTitle [

	^ 'Bytecode'
]

{ #category : #accessing }
GTBytecodeDebugger class >> helpClass [
	^ GTBytecodeDebuggerHelp
]

{ #category : #'debugger declaration' }
GTBytecodeDebugger class >> iAmADebugger [
	"Leave blank for intermediate classes. Add the <iAmADebugger> pragma for concrete debugger classes. This pragma is used by the system to find all available debuggers"
	<iAmADebugger>
]

{ #category : #'opening api' }
GTBytecodeDebugger class >> openOn: aDebugSession withFullView: aBool andNotification: aString [
	| newDebugSession debugger |
	newDebugSession := (self spanNewSessionFrom: aDebugSession).
	debugger := super openOn: newDebugSession withFullView: aBool andNotification: aString.
	newDebugSession stopKeepingAlive: debugger. "To undo the #keepAlive: done by GTMoldableDebugger>>#openOn:WithFullView:andNotification:"
	debugger originalSession: aDebugSession.
	aDebugSession keepAlive: debugger.
]

{ #category : #'debugger declaration' }
GTBytecodeDebugger class >> rank [
	^ 50
]

{ #category : #'debugger declaration' }
GTBytecodeDebugger class >> rankDebugSession: aDebugSession [
	"Returns an integer representing how much this debugger is suitable to debug @aDebugSession. The higher the integer returned, the more suitable this debugger is. Signal the DebugSessionCannotBeOpenedByThisDebugger exception if this debugger absolutely cannot debug @aDebugSession (for example if this debugger can only handle debug sessions from test executions, and @aDebugSession does not come from a test execution)"
	(self handlesContext: aDebugSession interruptedContext) ifTrue: [ ^ self rank ] ifFalse: [ DebugSessionCannotBeOpenedByThisDebugger signal ]
]

{ #category : #'tools registry' }
GTBytecodeDebugger class >> register [

	self registerToolsOn: Smalltalk tools.
]

{ #category : #'tools registry' }
GTBytecodeDebugger class >> registerToolsOn: registry [

	"Add ourselves to registry. See [Smalltalk tools]" 
	registry registerDebugger: self withRank: 5.
]

{ #category : #accessing }
GTBytecodeDebugger class >> sessionClass [

	^ GTBytecodeDebuggerSession
]

{ #category : #accessing }
GTBytecodeDebugger class >> variablesBrowserClass [

	^ GTBytecodeDebuggerVariablesBrowser
]

{ #category : #'building actions' }
GTBytecodeDebugger >> bytecodeActionsPragmas [

	^ #( bytecodeCodeDebuggingAction )
]

{ #category : #'building presentations' }
GTBytecodeDebugger >> bytecodeIn: aComposite forContext: aContext [

	(self methodBytecodeWidgetIn: aComposite forContext: aContext)
		initialize: [ :bytecodePresentation |
				bytecodePresentation selection: (self session symbolicBytecodeForCurrentPCFrom: self currentContext) ];
		with: [ :bytecode | self installActionsForRootPragmas: self bytecodeActionsPragmas in: bytecode ].
]

{ #category : #accessing }
GTBytecodeDebugger >> bytecodePane [

	^ self browser paneNamed: #bytecode
]

{ #category : #accessing }
GTBytecodeDebugger >> bytecodePresentation [
	
	^ self bytecodePane presentations first
]

{ #category : #building }
GTBytecodeDebugger >> debuggerStructureIn: browser [
	
	browser
		row: #stack;
		row: [ :c | c
			column: #code; 
			column: #bytecode ] span: 2;
		row: #inspector.
		
]

{ #category : #building }
GTBytecodeDebugger >> debuggerTransmissionsIn: browser [

	super debuggerTransmissionsIn: browser.
	browser transmit
		from: #stack port: #selection;
		to: #bytecode;
		andShow: [ :composite :aContext | self bytecodeIn: composite forContext: aContext ]

]

{ #category : #'building presentations' }
GTBytecodeDebugger >> decompiledCodeWidgetIn: composite forContext: aContext [

	^ composite pharoMethod
		title: 'Decompiled';
		format: [ aContext method codeForNoSource ];
		smalltalkClass: [  aContext methodClass ];
		doItReceiver: [ aContext receiver ];
		doItContext: [  aContext ]
]

{ #category : #'printing/formatting' }
GTBytecodeDebugger >> formatBytecode: aBytecode [
	| textAttributes|
	
	textAttributes := {TextColor new color: self theme textColor}.
	self selectedContext pc = aBytecode offset ifTrue: [ textAttributes := {TextColor new color: self theme textColor. TextEmphasis italic} ]. 
	self selectedContext pc > aBytecode offset ifTrue: [ textAttributes := {TextColor new color: Color gray} ].
	^ Text 
		string: aBytecode printString
		attributes: textAttributes
]

{ #category : #'building presentations' }
GTBytecodeDebugger >> methodBytecodeWidgetIn: aComposite forContext: aContext [

	^ aComposite tree
		title: 'Bytecode';
		rootsExpanded;
		display: [ aContext method symbolicBytecodes ];
		children: [ :each | each isArray ifTrue: [each] ifFalse: #() ];
		format: [ :each | self formatBytecode: each ];
		onChangeOfPort: #selection act: [ :bytecodes | 
			self codePresentation 
				selectionInterval: (bytecodes selection
					ifNil: [ 1 to: 0 ] 
					ifNotNil: [:selectedBytecode| selectedBytecode sourceInterval]) ] 
]

{ #category : #'building presentations' }
GTBytecodeDebugger >> methodCodeIn: composite forContext: aContext [

	(self methodCodeWidgetIn: composite forContext: aContext)
		with: [ :code | self installCodeActionsFor: code ].
	"self decompiledCodeWidgetIn: composite forContext: aContext"
]
