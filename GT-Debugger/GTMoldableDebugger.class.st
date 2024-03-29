"
I provide the basic functionality needed to create new debuggers. 
Subclasses should override the following methods:
	debuggerStructureIn: -> provides the structure of the debugger
	debuggerTransmissionsIn: -> creates transmissions between the widgets of a debuggers
	selectedContext 
"
Class {
	#name : #GTMoldableDebugger,
	#superclass : #GLMCompositePresentation,
	#traits : 'GTBrowsingActions',
	#classTraits : 'GTBrowsingActions classTrait',
	#instVars : [
		'originalSession'
	],
	#classVars : [
		'EnableDebuggerWindowDistinctColor',
		'EnableStackColoring'
	],
	#category : #'GT-Debugger-UI'
}

{ #category : #testing }
GTMoldableDebugger class >> availableAutomatically [
	"Should this debugger be taken into account when looking for a debugger to handle an exception."
	
	^ false
]

{ #category : #'instance creation' }
GTMoldableDebugger class >> debugSession: aSession [

	<primitive: 19> "simulation guard"

	"WorldState addDeferredUIMessage: ["
		^ self openOn: aSession 
	"]"
]

{ #category : #accessing }
GTMoldableDebugger class >> defaultTitle [
	self subclassResponsibility
]

{ #category : #'settings api' }
GTMoldableDebugger class >> enableDebuggerWindowDistinctColor [
	^ EnableDebuggerWindowDistinctColor ifNil: [EnableDebuggerWindowDistinctColor := false]
]

{ #category : #'settings api' }
GTMoldableDebugger class >> enableDebuggerWindowDistinctColor: aBoolean [
	EnableDebuggerWindowDistinctColor := aBoolean.
]

{ #category : #'settings api' }
GTMoldableDebugger class >> enableStackColoring [
	^ EnableStackColoring ifNil: [EnableStackColoring := false]
]

{ #category : #'settings api' }
GTMoldableDebugger class >> enableStackColoring: aBoolean [
	EnableStackColoring := aBoolean.
]

{ #category : #testing }
GTMoldableDebugger class >> handlesContext: aContext [
	self subclassResponsibility 
]

{ #category : #accessing }
GTMoldableDebugger class >> helpClass [

	self subclassResponsibility
]

{ #category : #'instance creation api' }
GTMoldableDebugger class >> on: aDebugSession [

	^ self new 	
			session: aDebugSession
]

{ #category : #'opening api' }
GTMoldableDebugger class >> openOn: aDebugSession withFullView: aBool [
	
	self openOn: aDebugSession withFullView: aBool andNotification: nil
]

{ #category : #'opening api' }
GTMoldableDebugger class >> openOn: aDebugSession withFullView: aBool andNotification: aString [
	
	| debugger |	
	"debugger := (Smalltalk tools 
		debuggerDispatcherFor: aDebugSession interruptedContext
		matching: [:aDebugger | aDebugger availableAutomatically ]) 
			ifNil: [ 
				""Use the current debugger""
				self on: aDebugSession ]
			ifNotNil: [ :aDebugger | 
				""Use a custom extension""
				aDebugger on: (aDebugger spanNewSessionFrom: aDebugSession) ]."
	
	debugger := self on: aDebugSession "(self spanNewSessionFrom: aDebugSession)".
	debugger originalSession: aDebugSession.
	
	aDebugSession keepAlive: debugger.
	aBool | aString isNil "In case the string is nil it means we should show the full debugger and not a notification"
		ifTrue: [ debugger openWithFullView ]
		ifFalse: [ debugger openWithNotification: aString].
	^ debugger
]

{ #category : #'window color api' }
GTMoldableDebugger class >> patchworkUIThemeColor [
	"Answer a default color for UI themes that make use of different colors for Browser, MessageList etc..."

	^ Color lightRed

]

{ #category : #accessing }
GTMoldableDebugger class >> sessionClass [
	self subclassResponsibility
]

{ #category : #'opening api' }
GTMoldableDebugger class >> signalCannotOpenDebugSessionException [
	"For use by TKTDebugger, a debugger from newTools, when DebuggerSelector is in the image.
	The exception signalling is done here because TKTDebugger cannot have a reference to this exception class since it only exist with DebuggerSelector, while TKTDebugger can exist without DebuggerSelector"
	DebugSessionCannotBeOpenedByThisDebugger signal
]

{ #category : #private }
GTMoldableDebugger class >> spanNewSessionForContext: aContext fromProcess: aProcess [

	^ self sessionClass 
		named: 'temporary name' on: aProcess startedAt: aContext
]

{ #category : #accessing }
GTMoldableDebugger class >> spanNewSessionFrom: anotherSession [

	^ (self sessionClass 
		named: anotherSession name 
		on: anotherSession interruptedProcess 
		startedAt: anotherSession interruptedContext)
			errorWasInUIProcess: anotherSession errorWasInUIProcess;
			yourself
]

{ #category : #private }
GTMoldableDebugger class >> spanNewSessionLabeled: aString forContext: aContext fromProcess: aProcess [

	^ self sessionClass 
		named: aString on: aProcess startedAt: aContext
]

{ #category : #icons }
GTMoldableDebugger class >> taskbarIconName [
	^ #smallDebugIcon
]

{ #category : #callbacks }
GTMoldableDebugger >> actOnBrowserClosing: ann [
	"Terminating debug sessions is now handled by DebugSessionStorage, to allow other debuggers to re-open the debug session debugged by a GTDebugger after the latter has been closed"
	"self session ifNotNil: [ :aSession | aSession terminate ]"
"	self session ifNotNil: [ :aSession | aSession stopKeepingAlive: self ]"
	self originalSession ifNotNil: [ :aSession | aSession stopKeepingAlive: self ]
]

{ #category : #callbacks }
GTMoldableDebugger >> actOnInspectorPaneRemoved: ann [
]

{ #category : #'building actions' }
GTMoldableDebugger >> actionsForPragmas: aSymbolsCollection [

	self session interruptedContext ifNil: [ ^ #() ].
	^ (self allActionsForPragmas: aSymbolsCollection)
				collect: [ :aDebugAction | aDebugAction asGlamourAction ]

]

{ #category : #'building actions' }
GTMoldableDebugger >> allActionsForPragmas: aSymbolsCollection [
	
	^ (self session class 
		debuggingActionsForPragmas: aSymbolsCollection 
		for: self)

	

]

{ #category : #accessing }
GTMoldableDebugger >> browser [ 

	^ self presentations first
]

{ #category : #actions }
GTMoldableDebugger >> close [

	self browser ifNotNil: [ :aBrowser | aBrowser close ]
]

{ #category : #building }
GTMoldableDebugger >> compose [
	"give the window a dedicated reddish color to ensure it gets noticed"
	self class enableDebuggerWindowDistinctColor ifTrue: [ 
		self color: (Color r: 1.0 g: 0.3 b: 0.3) ].
	self installDebuggingActionsFor: self.
	self tabulator with: [:browser | 
		self debuggerStructureIn: browser.
		self debuggerTransmissionsIn: browser ].
	self registerActions
]

{ #category : #'accessing context' }
GTMoldableDebugger >> contextToSelectFrom: aSession [
	^ aSession interruptedContext
]

{ #category : #'accessing context' }
GTMoldableDebugger >> currentContext [

	^self selectedContext 
		ifNil: [ self interruptedContext ] 
		ifNotNil:  [ self selectedContext  ]
]

{ #category : #actions }
GTMoldableDebugger >> debug: aContext using: aDebuggerClass [
	| currentSession newDebugger |
	
	currentSession := self session.
	self detachSession.
	self browser close.
	currentSession updateContextTo: aContext.
	newDebugger := aDebuggerClass on: (aDebuggerClass spanNewSessionFrom: currentSession).
	^ self openAndInitialize: newDebugger 
		
]

{ #category : #building }
GTMoldableDebugger >> debuggerStructureIn: browser [
	self subclassResponsibility
		
]

{ #category : #building }
GTMoldableDebugger >> debuggerTransmissionsIn: browser [
	self subclassResponsibility 
]

{ #category : #actions }
GTMoldableDebugger >> detachSession [
	self flag: 'why silent value?'.
	(self browser pane port: #entity) silentValue: nil
]

{ #category : #protocol }
GTMoldableDebugger >> initialExtent [
"This code was taken from the standard debugger to get the same behavior. Fell free to refactor"

	RealEstateAgent standardWindowExtent y < 400 "a tiny screen" 
		ifTrue: [^ 700@500].
	
	^ [ | w h |
		w := Display width.
		h := Display height.
		(w - (w // 3)) @ (h - (h // 5)) ]
		on: Error
		do: [ 850@600 ]
]

{ #category : #'building actions' }
GTMoldableDebugger >> installActionsForRootPragmas: aSymbolsCollection in: aPresentation [

	aPresentation dynamicActions: [ :presentation |
		self actionsForPragmas: (aSymbolsCollection collect: [ :aSymbol | #gt, aSymbol capitalized ]) ] .
	
	aPresentation dynamicActionsOnSelection: [ :presentation |
		self actionsForPragmas: (aSymbolsCollection collect: [ :aSymbol | #gtContext, aSymbol capitalized ]) ] .
]

{ #category : #'building actions' }
GTMoldableDebugger >> installDebuggingActionsFor: aPresentation [

	self subclassResponsibility
]

{ #category : #'accessing context' }
GTMoldableDebugger >> interruptedContext [

	^ self session interruptedContext
]

{ #category : #accessing }
GTMoldableDebugger >> interruptedProcess [

	^ self session interruptedProcess
]

{ #category : #'scripting opening' }
GTMoldableDebugger >> open [		
	| window |
	window := super open.
	
	self class environment at: #GTDebuggerEventCollector ifPresent: [ :eventCollector | 
		eventCollector new collectDataFrom: self ].
		
	^ window.
]

{ #category : #actions }
GTMoldableDebugger >> openAndInitialize: aNewDebugger [
	
	aNewDebugger color: self color.
	aNewDebugger openWithFullView.
	aNewDebugger window window "Hack to get this working with SpecDebugger"
		position: self window position;
		extent: self window extent.
	^ aNewDebugger
]

{ #category : #'scripting opening' }
GTMoldableDebugger >> openOn: anObject [
	
	^ (super openOn: anObject)
		extent: self initialExtent;
		title: self session name;
		yourself
]

{ #category : #callbacks }
GTMoldableDebugger >> originalSession [
	^ originalSession
]

{ #category : #actions }
GTMoldableDebugger >> originalSession: aDebugSession [
	originalSession := aDebugSession
]

{ #category : #building }
GTMoldableDebugger >> registerActions [

	self when: GLMBrowserClosing send: #actOnBrowserClosing: to: self.
	self when: DebugActionExecuted send: #updateBrowserFrom: to: self.
	self when: GLMPaneRemoved send: #actOnInspectorPaneRemoved: to: self.

]

{ #category : #updating }
GTMoldableDebugger >> removeSessionSilently [

	(self browser pane port: #entity) silentValue: nil
]

{ #category : #'accessing context' }
GTMoldableDebugger >> selectedContext [
	self subclassResponsibility 
]

{ #category : #accessing }
GTMoldableDebugger >> session [
 
	^ (self browser pane port: #entity) value
]

{ #category : #accessing }
GTMoldableDebugger >> session: aSession [

	(self browser pane port: #entity) value: aSession.
	self title: aSession name
]

{ #category : #building }
GTMoldableDebugger >> taskbarIcon [
	^ self iconNamed: #glamorousBug
]

{ #category : #accessing }
GTMoldableDebugger >> title [
	
	^ super title 
		ifNil: [ self class defaultTitle ] 
		ifNotNil: [ :aString | aString ] 
]

{ #category : #updating }
GTMoldableDebugger >> updateBrowser [
	| browserPane session |
	
	session := self session.
	session interruptedContext ifNil: [ 
		self close.
		UIManager default inform: 'End of debugged execution'.
		 ] ifNotNil: [  
	browserPane := self browser pane.
	(browserPane port: #entity) silentValue: nil.
	(browserPane port: #entity) value: session. ]
]

{ #category : #updating }
GTMoldableDebugger >> updateBrowserFrom: anAnnouncement [
	
	anAnnouncement action needsUpdate ifTrue: [
		self updateBrowser ].
	
	self announcer announce: ( GTDebuggerBrowserUpdateRequest from: anAnnouncement )
]

{ #category : #callbacks }
GTMoldableDebugger >> windowIsClosing [ 
	self flag: 'bug here when an announcement is inspected?'.
	self announce: (GLMBrowserClosing new presentation: self)
]
