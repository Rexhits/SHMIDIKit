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

**Create a virtual midi source and send out a MIDI message**
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

**Send out a pitchbend message**
```swift
let midiHandler = MIDIHandler.shared
// create a virtual MIDI source
midiHandler.configDevice()
// Value for pitchbend: 0 = Lowest position, 64 = Middle position, 127=Highest Position
midiHandler.sendPitchBend(value: 127)
```

**Send out a sequence of control message**
``` swift
let midiHandler = MIDIHandler.shared
// create a virtual MIDI source
midiHandler.configDevice()
// get the cc number for Pan
let pan = MIDIController.Pan.rawValue
// Pan your sound to the left
midiHandler.sendControlMessage(cc: pan, value: 0)
// Wait a second
sleep(1)
// Pan your sound to the right
midiHandler.sendControlMessage(cc: pan, value: 127)
usleep(1)
// Return your pan to the middle
midiHandler.sendControlMessage(cc: pan, value: 64)
```
[Documentation](https://rexhits.github.io/SHMIDIKit/)
