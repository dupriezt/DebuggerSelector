"
I am a copy of class BaselineOfCommander2. This comment is copied from there, and might not be entirely accurate

Please comment me using the following template inspired by Class Responsibility Collaborator (CRC) design:

For the Class part:  State a one line summary. For example, ""I represent a paragraph of text"".

For the Responsibility part: Three sentences about my main responsibilities - what I do, what I know.

For the Collaborators Part: State my main collaborators and one line about how I interact with them. 

Public API and Key Messages

- message one   
- message two 
- (for bonus points) how to create instances.

   One simple example is simply gorgeous.
 
Internal Representation and Key Implementation Points.


    Implementation Points
"
Class {
	#name : #BaselineOfDebuggerSelector,
	#superclass : #BaselineOf,
	#category : #BaselineOfDebuggerSelector
}

{ #category : #baselines }
BaselineOfDebuggerSelector >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec
				package: 'Debugger-Model';
				package: 'GT-BytecodeDebugger';
				package: 'GT-Debugger';
				package: 'GT-SUnitDebugger';
				package: 'GT-Tests-Debugger';
				package: 'Polymorph-Widgets';
				package: 'Tools';
				package: 'Tools-Test'
"				package: 'Commander2-Deprecations' with: [ spec requires: #('Commander2') ];"
				 ]
]
