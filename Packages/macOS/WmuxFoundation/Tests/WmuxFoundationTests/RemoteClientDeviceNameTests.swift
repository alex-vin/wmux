import WmuxFoundation
import Testing

struct RemoteClientDeviceNameTests {
    @Test(arguments: [
        ("MacBook.local", "wmux-MacBook"),
        ("Austin's MacBook.local", "wmux-Austin-s-MacBook"),
        ("build-box.example.com", "wmux-build-box"),
        ("", "wmux-mac"),
        (String(repeating: "x", count: 100), "wmux-" + String(repeating: "x", count: 40))
    ])
    func keepsTheExistingRemoteLabelFormat(hostName: String, expected: String) {
        #expect(RemoteClientDeviceName(hostName: hostName).value == expected)
    }
}
