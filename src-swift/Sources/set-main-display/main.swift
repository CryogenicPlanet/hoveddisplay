//
//  main.swift
//  main-display-config
//
//  Created by Rahul Tarak on 2022-10-25.
//

import ApplicationServices
import Foundation

struct Display: Encodable {
    var id: CGDirectDisplayID = 0
    var uuid: CFString = "" as CFString
    var type: String = ""
    var rect: CGRect = .init(x: 0, y: 0, width: 0, height: 0)
    var isMain: Bool = false

    enum CodingKeys: CodingKey {
        case id
        case uuid
        case type
        case rect
        case isMain
    }

    enum RectKeys: CodingKey {
        case x
        case y
        case width
        case height
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(uuid as String, forKey: .uuid)
        try container.encode(type, forKey: .type)
        try container.encode(isMain, forKey: .isMain)

        var rectContainer = container.nestedContainer(keyedBy: RectKeys.self, forKey: .rect)
        try rectContainer.encode(rect.origin.x, forKey: .x)
        try rectContainer.encode(rect.origin.y, forKey: .y)
        try rectContainer.encode(rect.size.width, forKey: .width)
        try rectContainer.encode(rect.size.height, forKey: .height)
    }
}

func getDisplays() -> [Display] {
    let screenCountPtr = UnsafeMutablePointer<UInt32>.allocate(capacity: 4)
    CGGetOnlineDisplayList(UINT32_MAX, nil, screenCountPtr)
    var displays = [Display]()
    let mainDisplay = CGMainDisplayID()

    // Screen ids start from 1 (idk why)
    let screenCount = screenCountPtr.pointee + 1
    for i in 1 ..< screenCount {
        let displayRect = CGDisplayBounds(i)
        var newDisplay = Display(id: i, rect: displayRect)

        if i == mainDisplay {
            newDisplay.isMain = true
        }

        // char curScreenUUID[UUID_SIZE];
        let uuid = CFUUIDCreateString(kCFAllocatorDefault, CGDisplayCreateUUIDFromDisplayID(i).takeRetainedValue())

        if uuid != nil {
            newDisplay.uuid = uuid!
        }

        if CGDisplayIsBuiltin(i) != 0 {
            newDisplay.type = "Built-in Display"
        } else {
            let size = CGDisplayScreenSize(i)
            let diagonal = round(sqrt((size.width * size.width) + (size.height * size.height)) / 25.4) // 25.4mm in an inch
            newDisplay.type = "\(diagonal) inch Monitor"
        }

        displays.append(newDisplay)
    }

    screenCountPtr.deallocate()

    return displays
}

func printDisplays() {
    let displays = getDisplays()
    for display in displays {
        print("\(display.uuid): Main: \(display.isMain ? "True " : "False") Type: \(display.type) ")
    }
}

func displayJson() {
    let displays = getDisplays()
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(displays)
    let json = String(data: data, encoding: .utf8)!
    print(json)
}

// Steps to change display
// 1. Get the display uuid of the display you want to move
// 2. Get the current positions of all displays
// 3. Set the uuid display to origin (0,0)
// 4. Compute new origins for other displays to ensure the same configuration is maintained
// 5. Complete transaction
func changeDisplay(displayId: CFString) {
    let moveUUID = displayId
    // let moveUUID = "FB75C17C-573B-4350-B680-CEC29EFC8617" as CFString

    let beforeDisplays = getDisplays()

    var isSuccess = true

    print("Before", beforeDisplays)

    let configRef = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 4)

    CGBeginDisplayConfiguration(configRef)

    var moveToDisplay = CGMainDisplayID()

    for display in beforeDisplays {
        if display.uuid == moveUUID {
            moveToDisplay = display.id
        }
    }

    if moveToDisplay == CGMainDisplayID() {
        print("Display is already main")
        return
    }

    let error = CGConfigureDisplayOrigin(configRef.pointee, moveToDisplay, 0, 0)

    if error != .success {
        isSuccess = false
        print("Failed to set", moveUUID, "as main display")
    }

    // Compute new origins for other displays
    let oldMain = beforeDisplays.first(where: { $0.isMain })!
    let newMain = beforeDisplays.first(where: { $0.id == moveToDisplay })!

    let xDiff = oldMain.rect.origin.x - newMain.rect.origin.x
    let yDiff = oldMain.rect.origin.y - newMain.rect.origin.y

    for display in beforeDisplays {
        if display.id != moveToDisplay {
            let newOrigin = CGPoint(x: display.rect.origin.x + xDiff, y: display.rect.origin.y + yDiff)
            let error = CGConfigureDisplayOrigin(configRef.pointee, display.id, Int32(newOrigin.x), Int32(newOrigin.y))

            if error != .success {
                isSuccess = false
                print("Failed to update", display.uuid, "'s origin")
            }
        }
    }

    if isSuccess {
        let error = CGCompleteDisplayConfiguration(configRef.pointee, .forSession)
        if error != .success {
            print("Failed to complete transaction")
        }
    } else {
        let error = CGCancelDisplayConfiguration(configRef.pointee)
        if error != .success {
            print("Failed to cancel transaction")
        }
        print("Cancelled transaction")
    }
}

func main() {
    let arguments = CommandLine.arguments

    let type = arguments[1]

    switch type {
    case "list":
        printDisplays()
    case "json":
        displayJson()
    case "change":
        if arguments.count < 3 {
            print("Please provide a display uuid")
            return
        }
        let displayId = arguments[2] as CFString?
        if displayId != nil {
            changeDisplay(displayId: displayId!)
        } else {
            print("Invalid display uuid")
        }
    default:
        print("Invalid argument")
    }
}

main()

// Displayer config for Rahul if the code screws up my setup

// Default

// displayplacer "id:F18F06D6-0A39-4BB8-B247-0B9E3134727E res:2560x1080 hz:75 color_depth:8 scaling:off origin:(0,0) degree:0" "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1728x1117 hz:120 color_depth:8 scaling:on origin:(2560,0) degree:0" "id:FB75C17C-573B-4350-B680-CEC29EFC8617 res:1920x1080 hz:60 color_depth:8 scaling:off origin:(640,-1080) degree:0"

// Main display 3

// displayplacer "id:FB75C17C-573B-4350-B680-CEC29EFC8617 res:1920x1080 hz:60 color_depth:8 scaling:off origin:(0,0) degree:0"
// "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1728x1117 hz:120 color_depth:8 scaling:on origin:(1920,1080) degree:0"
// "id:F18F06D6-0A39-4BB8-B247-0B9E3134727E res:2560x1080 hz:75 color_depth:8 scaling:off origin:(-640,1080) degree:0"
