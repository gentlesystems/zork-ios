// swift-tools-version: 5.9
import PackageDescription

// Legacy Dungeon C sources at the repo root, kept byte-identical to upstream
// (https://github.com/devshane/zork). The bridge target wraps them without
// edits using two preprocessor/linker tricks:
//
//   1. -Dmain=dungeon_main rewrites dmain.c's `void main(...)` at compile time.
//   2. ios_bridge.c provides its own exit(), printf(), puts(), putchar() that
//      shadow libSystem's via Darwin two-level namespace, so unmodified supp.c's
//      `exit(0)` longjmp's back to run_dungeon() instead of terminating.
private let legacySources: [String] = [
    "actors.c", "ballop.c", "clockr.c", "demons.c", "dgame.c", "dinit.c",
    "dmain.c", "dso1.c", "dso2.c", "dso3.c", "dso4.c", "dso5.c", "dso6.c",
    "dso7.c", "dsub.c", "dverb1.c", "dverb2.c", "gdt.c", "lightp.c", "local.c",
    "nobjs.c", "np.c", "np1.c", "np2.c", "np3.c", "nrooms.c", "objcts.c",
    "rooms.c", "sobjs.c", "supp.c", "sverbs.c", "verbs.c", "villns.c",
    "Sources/CDungeon/ios_bridge.c",
]

let package = Package(
    name: "ZorkIOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ZorkUI", targets: ["ZorkUI"]),
    ],
    targets: [
        .target(
            name: "CDungeon",
            path: ".",
            sources: legacySources,
            publicHeadersPath: "Sources/CDungeon/include",
            cSettings: [
                .headerSearchPath("."),
                .define("main", to: "dungeon_main"),
                .define("unix", to: "1"),
                .define("MORE_NONE", to: "1"),
                .define("TEXTFILE", to: "\"dtextc.dat\""),
                .define("LOCALTEXTFILE", to: "\"dtextc.dat\""),
            ]
        ),
        .target(
            name: "ZorkUI",
            dependencies: ["CDungeon"],
            path: "Sources/ZorkUI"
        ),
    ]
)
