//
//  MIDIFunc.swift
//  S-Motion
//
//  Created by WangRex on 6/24/18.
//  Copyright © 2018 WangRex. All rights reserved.
//

import Foundation
import CoreMIDI
import CoreAudio

public final class MIDIHandler {
    private var midiClient: MIDIClientRef = 0
    private var outPort: MIDIPortRef = 0
    private var srcPort: MIDIPortRef = 0
    
    
    var packetArray: [[UInt8]] = []
    
    /// Singleton of MIDIHandler
    public static var shared = MIDIHandler()
    
    

    
}

public extension MIDIHandler {
    /// Convert second to nanosecond, MIDI Timestamp is in nanosecond
    public static func secondToNanoSecond(second: UInt64) -> UInt64 {
        return second * UInt64(powf(10.0, 9.0))
    }
    
    
    /// Create a virtual MIDI source, for outputing midi data to DAWs
    public func configDevice() {
        MIDIClientCreate("S-Motion Midi Client" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient, "S-Motion MIDI Out" as CFString, &outPort)
        MIDISourceCreate(midiClient, "S-Motion" as CFString, &srcPort)
        if let uuid = UserDefaults.standard.value(forKey: "MIDISourceUUID") as? Int {
            MIDIObjectSetIntegerProperty(srcPort, kMIDIPropertyUniqueID, Int32(uuid))
        } else {
            var id: Int32 = 0
            MIDIObjectGetIntegerProperty(srcPort, kMIDIPropertyUniqueID, &id)
            UserDefaults.standard.set(Int(id), forKey: "MIDISourceUUID")
        }
    }
    
    
    /// buffer a midi packet
    ///
    /// - Parameters:
    ///   - event: See MIDIEvent Enum
    ///   - channel: MIDI Channel number 0-15
    ///   - data1: 2nd Byte of a MIDI message
    ///   - data2: 3nd Byte of a MIDI Message
    public func bufferMIDIEvent(event: MIDIEvent, channel: UInt8 = 0, data1: UInt8, data2: UInt8) {
        packetArray.append([event.rawValue + channel, data1, data2])
    }
    
    public func sendPacket() {
        #if os(iOS)
        let timeStamp = mach_absolute_time()
        #elseif os(OSX)
        let timeStamp = AudioConvertHostTimeToNanos(AudioGetCurrentHostTime())
        #endif
        let totalBytesInEvents = packetArray.reduce(0, {total, event in
            return total + event.count
        })
        let listSize = MemoryLayout<MIDIPacketList>.size + Int(totalBytesInEvents)
        guard totalBytesInEvents < 256 else {return}
        
        let byteBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: listSize)
        var packetList = byteBuffer.withMemoryRebound(to: MIDIPacketList.self, capacity: 1) { (packetArr) -> MIDIPacketList in
            var packet = MIDIPacketListInit(packetArr)
            packetArray.forEach{packet = MIDIPacketListAdd(packetArr, listSize, packet, timeStamp, $0.count, $0)}
            return packetArr.pointee
        }
        MIDIReceived(MIDIHandler.shared.srcPort, &packetList)
        packetArray = []
        byteBuffer.deallocate()
    }
    
    /// send a pair of note on & note off message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - noteNumber: 0-127
    ///   - velocity: 0-127
    ///   - duration: See NoteLength Enum
    public func sendNote(channel: UInt8 = 0, noteNumber: UInt8, velocity: UInt8, duration: NoteLength) {
        var onPacket = MIDIPacket()
        #if os(iOS)
        onPacket.timeStamp = mach_absolute_time()
        #elseif os(OSX)
        onPacket.timeStamp = AudioConvertHostTimeToNanos(AudioGetCurrentHostTime())
        #endif
        onPacket.length = 3
        onPacket.data.0 = MIDIEvent.NoteOn.rawValue
        onPacket.data.1 = noteNumber
        onPacket.data.2 = velocity
        
        guard duration != .Forever else {return}
        
        var offPacket = MIDIPacket()
        #if os(iOS)
        offPacket.timeStamp = mach_absolute_time() + MIDITimeStamp(duration.rawValue)
        #elseif os(OSX)
        offPacket.timeStamp = AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()) + MIDITimeStamp(duration.rawValue)
        #endif
        offPacket.length = 3
        offPacket.data.0 = MIDIEvent.NoteOff.rawValue
        offPacket.data.1 = noteNumber
        offPacket.data.2 = velocity
        
        var onPacketList = MIDIPacketList(numPackets: 1, packet: onPacket)
        var offPacketList = MIDIPacketList(numPackets: 1, packet: offPacket)
        MIDIReceived(MIDIHandler.shared.srcPort, &onPacketList)
        MIDIReceived(MIDIHandler.shared.srcPort, &offPacketList)
    }
    
    
    /// buffer a note on message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - noteNumber: 0-127
    ///   - velocity: 0-127
    public func bufferNoteOn (channel: UInt8 = 0, noteNumber: UInt8, velocity: UInt8) {
        bufferMIDIEvent(event: .NoteOn, channel: channel, data1: noteNumber, data2: velocity)
    }
    
    /// buffer a note off message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - noteNumber: 0-127
    public func bufferNoteOff (channel: UInt8 = 0, noteNumber: UInt8) {
        bufferMIDIEvent(event: .NoteOff, channel: channel, data1: noteNumber, data2: 0)
    }
    
    
    
    /// buffer a pitchbend message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - value: 0-127, 64 is pitchbend in the middle position
    public func bufferPitchBend (channel: UInt8 = 0, value: UInt8) {
        // input within 0 ... 127
        let input = Int(8192 + 8191 * Double(value).map(start1: 0, stop1: 127, start2: -1, stop2: 1))
        let data1 = UInt8(input & 127)
        let data2 = UInt8((input >> 7) & 127)
        bufferMIDIEvent(event: .PitchBend, data1: data1, data2: data2)
    }
    
    
    /// buffer a aftertouch message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - value: 0-127
    public func bufferAfterTouch (channel: UInt8 = 0, value: UInt8) {
        bufferMIDIEvent(event: .AfterTouch, data1: value, data2: 0)
    }
    
    
    /// buffer a midi control message
    ///
    /// - Parameters:
    ///   - channel: MIDI Channel number 0-15
    ///   - cc: controller number 0-127
    ///   - value: 0-127
    public func bufferControlMessage(channel: UInt8 = 0, cc: UInt8, value: UInt8) {
        bufferMIDIEvent(event: .ControlChange, data1: cc, data2: value)
    }
    
    /// Mute all notes on a channel
    public func bufferAllNoteOff(channel: UInt8 = 0) {
        bufferMIDIEvent(event: .ControlChange, data1: UInt8(MIDIController.AllNotesOff.rawValue), data2: 0)
    }
    
    /// MIDI Flush
    public func flushMIDI() {
        MIDIFlushOutput(srcPort)
    }
    
    /// Reset pitchbend to middle position
    public func resetPitchBend() {
        bufferPitchBend(value: 64)
    }
    
    
}




@objc public enum MIDIEvent: UInt8 {
    case NoteOff = 0x80
    case NoteOn = 0x90
    case PolyAfterTouch = 0xA0
    case ControlChange = 0xB0
    case ProgramChange = 0xC0
    case AfterTouch = 0xD0
    case PitchBend = 0xE0
}

public enum MIDIController: Int, CaseIterable {
    case BankSelect = 0
    case FootController = 4
    case PortamentoTime = 5
    case DataEntryMSB = 6
    case Balance = 8
    case EffectController1 = 12
    case EffectController2 = 13
    case GeneralPurposeController1 = 16
    case GeneralPurposeController2 = 17
    case GeneralPurposeController3 = 18
    case GeneralPurposeController4 = 19
    case PortamentoSwitch = 65
    case SostenutoSwitch = 66
    case SoftPedal = 67
    case LegatoSwitch = 68
    case AllSoundOff = 120
    case ResetAllControllers = 121
    case LocalSwitch = 122
    case AllNotesOff = 123
    case OmniModeOff = 124
    case OmniModeOn = 125
    case MonoMode = 126
    case PolyMode = 127
}

public enum CommonMIDIController: Int, CaseIterable {
    case PitchBend = 999
    case Aftertouch = 1000
    case ModWheel = 1
    case BreathController = 2
    case Volume = 7
    case Pan = 10
    case Expression = 11
    case SustainPedal = 64
    case Resonance_XG = 71
    case ReleaseTime_XG = 72
    case AttackTime_XG = 73
    case Brightness_XG = 74
}

public enum CCShortName: Int, CaseIterable {
    case PB = 999
    case AT = 1000
    case Mod = 1
    case Bre = 2
    case Vol = 7
    case Pan = 10
    case Exp = 11
    case Sus = 64
    case Res = 71
    case Rel = 72
    case Att = 73
    case Bri = 74
}

public enum DrumNotes: UInt8 {
    case Kick = 36
    case Snare = 38
    case FloorTom2 = 41
    case FloorTom1 = 43
    case HiHatClosed = 42
    case LowTom = 45
    case LowMidTom = 47
    case HiHatOpen = 46
    case HiTom = 50
    case CrashCymbal = 49
}

public enum NoteLength: Int64 {
    case Impluse = 500000000
    case Short = 1000000000
    case Long = 3000000000
    case Forever = -1
    
    public func getIndex() -> Int {
        switch self {
        case .Impluse:
            return 0
        case .Short:
            return 1
        case .Long:
            return 2
        case .Forever:
            return 3
        }
    }
    
    public static func fromIndex(_ index: Int) -> NoteLength {
        switch index {
        case 0:
            return .Impluse
        case 1:
            return .Short
        case 2:
            return .Long
        default:
            return .Forever
        }
    }
}

