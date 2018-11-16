# SHMIDIKit

## A lightweight MIDI framework for iOS and macOS
### Installation
SHMIDKit is written in Swift 4.2, so your code has to be written in Swift 4.x due to current binary compatibility limitations.

### CocoaPods
To use [CocoaPods](https://cocoapods.org) add SHMIDIKit to your `Podfile`:

```ruby
pod 'SHMIDIKit'
```
Then run `pod install`.

### Examples
**Import SHMIDIKit to your project**
```swift
import SHMIDIKit
```

**Get the MIDIHandler singleton**
```swift
let midiHandler = MIDIHandler.shared
```

**Create a virtual midi source and send out note on message**
```swift
let midiHandler = MIDIHandler.shared
// create a virtual MIDI source
midiHandler.configDevice()
// send message to the first midi channal
let channel: UInt8 = 0
// note number for middle C
let noteNumber: UInt8 = 60
// velocity (0 - 127)
let velocity: UInt8 = 90
// send the noteOn message out
midiHandler.sendNoteOn(channel: channel, noteNumber: noteNumber, velocity: velocity)
```
