# Apple Framework Capabilities

These three Apple frameworks are used by `mac-screen-search`. This document catalogs the full range of capabilities across all major Apple frameworks.

## Capabilities of All Major Apple Frameworks

### Graphics, Media & Vision

| Library | Category | Capabilities |
|---|---|---|
| **ScreenCaptureKit** | Screen recording | Record screen video continuously (mp4/mov), including audio streams |
| **ScreenCaptureKit** | Selective capture | Capture specific windows, apps, or display regions (exclude others) |
| **ScreenCaptureKit** | Streaming | Real-time pixel streaming for live preview, mirroring, or broadcasting |
| **ScreenCaptureKit** | Audio capture | Capture system audio and microphone audio alongside video |
| **ScreenCaptureKit** | Filtering | Include/exclude specific apps or windows from capture dynamically |
| **ScreenCaptureKit** | Presenter overlay | Overlay the camera feed on shared content (macOS 14+) |
| **Vision** | Text recognition (OCR) | Detect and recognize text in images (used by this project) |
| **Vision** | Face detection | Detect face locations, landmarks (eyes, nose, mouth), and face quality |
| **Vision** | Barcode/QR detection | Detect and decode barcodes and QR codes in images |
| **Vision** | Image classification | Classify image content into categories (animal, scene, object, etc.) |
| **Vision** | Object detection/tracking | Detect and track objects or rectangles across video frames |
| **Vision** | Body/hand pose | Detect human body pose (joints) and hand pose (finger positions) |
| **Vision** | Horizon detection | Detect the horizon angle for auto-leveling photos |
| **Vision** | Image similarity | Generate feature vectors for comparing image similarity |
| **Vision** | Document detection | Detect rectangular documents (for scanning/perspective correction) |
| **Vision** | Animal detection | Detect and recognize animal types (cat, dog) in images |
| **Vision** | Optical flow | Compute pixel-level motion between two frames |
| **Vision** | Person segmentation | Generate a mask separating people from the background |
| **CoreGraphics** | Image creation/editing | Create, composite, crop, resize, and transform bitmap images |
| **CoreGraphics** | Drawing (2D) | Draw shapes, paths, lines, arcs, gradients, and text into contexts |
| **CoreGraphics** | PDF rendering | Create, read, and render PDF documents page-by-page |
| **CoreGraphics** | Color management | Color space conversions, ICC profiles, wide-gamut color support |
| **CoreGraphics** | Display management | Enumerate displays, get resolution/refresh rate, configure mirroring |
| **CoreGraphics** | Window management | List all on-screen windows, get their positions/sizes/owners |
| **CoreGraphics** | Event handling | Create, post, and tap low-level keyboard/mouse events programmatically |
| **CoreGraphics** | Affine transforms | Apply rotation, scaling, translation, and shearing to drawings |
| **CoreGraphics** | Image I/O | Read/write images in PNG, JPEG, TIFF, BMP, GIF, HEIC via CGImageSource/Destination |
| **CoreGraphics** | Blending/compositing | Alpha blending, blend modes (multiply, overlay, screen, etc.) |
| **CoreImage** | Image filters | 200+ built-in filters: blur, sharpen, color adjust, distort, stylize, composite |
| **CoreImage** | Face detection | CIDetector-based face, rectangle, QR code, and text detection |
| **CoreImage** | Custom filters | Write custom GPU-accelerated image filters via CIKernel (Metal Shading Language) |
| **CoreImage** | RAW processing | Decode and process RAW camera image formats with full control |
| **CoreImage** | Chaining | Chain multiple filters into a pipeline; lazy evaluation for performance |
| **CoreImage** | Auto-enhance | Automatically analyze and suggest enhancement filters for a photo |
| **Metal** | GPU compute | General-purpose GPU computation via compute shaders |
| **Metal** | 3D rendering | Low-level, high-performance 3D rendering pipeline |
| **Metal** | Ray tracing | Hardware-accelerated ray tracing (Apple Silicon) |
| **Metal** | Machine learning | Metal Performance Shaders (MPS) for neural networks, matrix ops, image processing |
| **Metal** | Mesh shading | Mesh and object shaders for advanced geometry processing |
| **Metal** | Resource management | Fine-grained GPU memory and resource allocation/synchronization |
| **MetalKit** | View integration | MTKView for rendering Metal content in AppKit/UIKit views |
| **MetalKit** | Texture loading | Load textures from image files, asset catalogs, or model I/O |
| **MetalKit** | Model loading | Load 3D model meshes from Model I/O assets for Metal rendering |
| **CoreAnimation** | Layer animation | Animate layer properties (position, opacity, transform, bounds) implicitly or explicitly |
| **CoreAnimation** | Keyframe animation | Multi-step keyframe animations with custom timing functions |
| **CoreAnimation** | Transitions | Built-in transitions (fade, push, reveal, cube) between layer states |
| **CoreAnimation** | Layer types | Specialized layers: CAShapeLayer, CATextLayer, CAGradientLayer, CAEmitterLayer, CAReplicatorLayer |
| **CoreAnimation** | 3D transforms | Apply 3D perspective transforms to layers (CATransform3D) |
| **CoreAnimation** | Particle effects | Particle emitter system via CAEmitterLayer and CAEmitterCell |
| **SceneKit** | 3D scenes | Build and render 3D scenes with nodes, geometry, lights, and cameras |
| **SceneKit** | Physics | Built-in 3D physics engine with rigid bodies, joints, and fields |
| **SceneKit** | Animation | Skeletal animation, morph targets, and procedural animation |
| **SceneKit** | Particle systems | 3D particle system editor and runtime for effects (fire, smoke, sparks) |
| **SceneKit** | Model import | Import DAE, USD, OBJ, and other 3D file formats |
| **SceneKit** | AR integration | Use as renderer for ARKit augmented reality scenes |
| **SpriteKit** | 2D games | Build 2D games and animations with a sprite-based scene graph |
| **SpriteKit** | Physics | 2D physics engine (Box2D-based) with bodies, joints, and collision detection |
| **SpriteKit** | Particle effects | 2D particle emitter system with Xcode visual editor |
| **SpriteKit** | Tile maps | Tile map support for building grid-based levels and environments |
| **SpriteKit** | Video/shader effects | Apply custom CIFilter or SKShader effects to sprites and scenes |
| **RealityKit** | 3D rendering | Photorealistic rendering engine for AR and 3D content |
| **RealityKit** | Entity-component | Entity-component architecture for modeling 3D scenes and behaviors |
| **RealityKit** | Physics/animation | Built-in physics simulation, skeletal animation, and audio spatialization |
| **RealityKit** | Reality Composer | Author interactive AR experiences with Reality Composer Pro |
| **RealityKit** | visionOS | Primary framework for building spatial experiences on Apple Vision Pro |
| **ImageIO** | Format support | Read/write 30+ image formats: JPEG, PNG, TIFF, GIF, HEIF, WebP, AVIF, RAW, BMP, ICO, SVG |
| **ImageIO** | Metadata | Read/write EXIF, IPTC, GPS, and XMP metadata from image files |
| **ImageIO** | Thumbnails | Generate thumbnails efficiently from image files without full decode |
| **ImageIO** | Progressive decode | Incrementally decode images as data arrives (progressive JPEG) |
| **ImageIO** | Animated images | Read/write animated GIF and animated PNG frames |
| **PDFKit** | PDF display | Display and navigate PDF documents with built-in UI (PDFView) |
| **PDFKit** | Annotations | Add, remove, and modify PDF annotations (highlight, text, stamp, link) |
| **PDFKit** | Text extraction | Extract text and text positions from PDF pages |
| **PDFKit** | Search | Search for text across all pages of a PDF document |
| **PDFKit** | PDF creation | Create and modify PDF documents, add/remove/reorder pages |
| **PencilKit** | Drawing | Provide a full-featured drawing canvas with Apple Pencil support |
| **PencilKit** | Ink types | Multiple ink types: pen, marker, pencil, crayon, watercolor, fill |
| **PencilKit** | Stroke data | Access and manipulate individual strokes and points programmatically |
| **PencilKit** | Serialization | Save and load drawings as PKDrawing data objects |

### Audio & Video

| Library | Category | Capabilities |
|---|---|---|
| **AVFoundation** | Playback | Play audio and video files/streams with AVPlayer, queue multiple items |
| **AVFoundation** | Recording | Record audio (AVAudioRecorder) and video (AVCaptureSession) from device inputs |
| **AVFoundation** | Camera control | Access and configure cameras: focus, exposure, white balance, zoom, torch |
| **AVFoundation** | Editing | Non-linear audio/video editing: compose, trim, overlay, and export via AVComposition |
| **AVFoundation** | Export | Transcode and export media with AVAssetExportSession (format, codec, quality, presets) |
| **AVFoundation** | Asset inspection | Read metadata, tracks, duration, and codec info from media files |
| **AVFoundation** | Subtitles/captions | Read, display, and embed subtitle/closed-caption tracks |
| **AVFoundation** | Streaming | HTTP Live Streaming (HLS) playback with adaptive bitrate |
| **AVFoundation** | Speech synthesis | Text-to-speech synthesis with AVSpeechSynthesizer (multiple voices/languages) |
| **AVFoundation** | Photo capture | High-quality still photo capture with RAW, HDR, depth, and Live Photo support |
| **AVFoundation** | Depth/LiDAR | Capture depth maps from dual cameras or LiDAR scanner |
| **AVFAudio** | Audio engine | Real-time audio processing graph with AVAudioEngine (nodes, mixers, effects) |
| **AVFAudio** | Audio effects | Built-in effects: reverb, delay, EQ, distortion, pitch shift, time stretch |
| **AVFAudio** | 3D audio | Spatial audio positioning, HRTF rendering, and head tracking |
| **AVFAudio** | MIDI | Send and receive MIDI events; connect to MIDI instruments |
| **AVFAudio** | Audio session | Configure audio session category, mode, and routing (AVAudioSession on iOS) |
| **CoreAudio** | Low-latency audio | Ultra-low-latency audio I/O via Audio Units and Audio Queue Services |
| **CoreAudio** | Audio Units | Host and create audio plug-ins (instruments, effects) via AudioUnit/AUv3 |
| **CoreAudio** | Format conversion | Convert between audio formats, sample rates, and channel layouts |
| **CoreAudio** | Device management | Enumerate and configure audio input/output devices (macOS) |
| **CoreAudio** | Aggregate devices | Create virtual aggregate audio devices combining multiple hardware devices |
| **CoreMIDI** | MIDI I/O | Send/receive MIDI messages to/from hardware and virtual MIDI devices |
| **CoreMIDI** | MIDI network | MIDI over network sessions (Bonjour-based) |
| **CoreMIDI** | Bluetooth MIDI | Connect to MIDI devices over Bluetooth LE |
| **MediaPlayer** | Music library | Access and query the user's music library (MPMediaQuery) |
| **MediaPlayer** | Now Playing | Display and control now-playing info on lock screen and Control Center |
| **MediaPlayer** | Remote commands | Respond to remote control events (play, pause, skip, seek) |
| **MusicKit** | Apple Music API | Search, browse, and stream Apple Music catalog content |
| **MusicKit** | Library management | Access and manage user's Apple Music library and playlists |
| **MusicKit** | Playback | Play Apple Music songs with full playback controls |
| **SoundAnalysis** | Audio classification | Classify sounds in real-time using built-in or custom ML models |
| **SoundAnalysis** | Sound detection | Detect 300+ sound types: speech, music, laughter, alarms, animals, vehicles |
| **SoundAnalysis** | Custom models | Use custom Core ML sound classification models with SoundAnalysis |
| **Speech** | Speech recognition | On-device and server-based speech-to-text transcription |
| **Speech** | Live transcription | Real-time speech transcription from microphone or audio buffers |
| **Speech** | Language support | Recognize speech in 60+ languages and dialects |
| **Speech** | Timing/confidence | Per-word timestamps, confidence scores, and alternative transcriptions |

### Machine Learning & AI

| Library | Category | Capabilities |
|---|---|---|
| **CoreML** | Model inference | Run trained ML models on-device (CPU, GPU, Neural Engine) |
| **CoreML** | Model types | Support for classification, regression, image, text, audio, and tabular models |
| **CoreML** | Model formats | Load .mlmodel/.mlpackage (converted from TensorFlow, PyTorch, ONNX, etc.) |
| **CoreML** | On-device training | Update/personalize models on-device with user data (MLUpdateTask) |
| **CoreML** | Model optimization | Quantization, pruning, and palettization for smaller/faster models |
| **CoreML** | Async prediction | Batch and asynchronous prediction APIs |
| **CreateML** | Model training | Train ML models on-device in Swift Playgrounds or apps |
| **CreateML** | Training tasks | Image classification, object detection, text classification, sound classification, tabular, recommendation, action classification, hand pose, body pose, style transfer |
| **CreateML** | Data augmentation | Built-in data augmentation (flip, rotate, crop, noise) during training |
| **CreateML** | Evaluation | Built-in metrics: accuracy, precision, recall, confusion matrix |
| **NaturalLanguage** | Tokenization | Tokenize text by word, sentence, or paragraph with locale awareness |
| **NaturalLanguage** | Language detection | Detect the dominant language of a text string |
| **NaturalLanguage** | Named entities | Identify named entities: people, places, organizations in text |
| **NaturalLanguage** | Sentiment analysis | Determine sentiment polarity (positive/negative/neutral) of text |
| **NaturalLanguage** | Part of speech | Tag parts of speech (noun, verb, adjective, etc.) for each word |
| **NaturalLanguage** | Lemmatization | Reduce words to their base/dictionary form |
| **NaturalLanguage** | Text embeddings | Generate vector embeddings for words/sentences for similarity comparison |
| **NaturalLanguage** | Custom models | Use custom Core ML NLP models with NaturalLanguage APIs |
| **Translation** | Text translation | On-device text translation between 10+ language pairs |
| **Translation** | Translation UI | System-provided translation overlay UI |

### UI Frameworks

| Library | Category | Capabilities |
|---|---|---|
| **SwiftUI** | Declarative UI | Build cross-platform UIs declaratively with automatic state management |
| **SwiftUI** | Layout system | VStack, HStack, ZStack, Grid, LazyVGrid, LazyHGrid, custom Layout protocol |
| **SwiftUI** | Navigation | NavigationStack, NavigationSplitView, TabView, sheet, popover, fullScreenCover |
| **SwiftUI** | Animation | Built-in animation system: spring, easeIn/Out, keyframe, phase animations, transitions |
| **SwiftUI** | Data flow | @State, @Binding, @Observable, @Environment, @AppStorage for reactive data flow |
| **SwiftUI** | Lists/collections | List, ForEach, LazyVStack/HStack with efficient view recycling |
| **SwiftUI** | Platform adaptation | Automatic adaptation to macOS, iOS, watchOS, tvOS, visionOS conventions |
| **SwiftUI** | Widgets/complications | Build widgets (WidgetKit), watch complications, and Live Activities |
| **SwiftUI** | Previews | Xcode Previews for instant visual feedback during development |
| **SwiftUI** | Charts | Built-in charts framework: bar, line, area, point, rule, sector charts |
| **SwiftUI** | MapKit integration | Native Map view with annotations, overlays, and Look Around |
| **AppKit** | macOS UI | Full macOS desktop application UI framework (windows, menus, toolbars) |
| **AppKit** | NSWindow | Window management: styles, levels, transparency, tiling, tabbing |
| **AppKit** | NSView | Rich view hierarchy: text views, table views, outline views, split views, collection views |
| **AppKit** | Menus/toolbars | Menu bar, contextual menus, toolbar, Touch Bar customization |
| **AppKit** | Drag and drop | Full drag-and-drop support with promises and custom pasteboard types |
| **AppKit** | Printing | Print dialogs, page layout, PDF generation, print preview |
| **AppKit** | Accessibility | VoiceOver, accessibility descriptions, actions, and custom elements |
| **AppKit** | Text system | TextKit 2: advanced text layout, custom attributes, exclusion paths |
| **UIKit** | iOS UI | Full iOS/iPadOS application UI framework |
| **UIKit** | Collection views | Compositional layout, diffable data sources, cell registration |
| **UIKit** | Gestures | Tap, pinch, rotate, swipe, pan, long press, and custom gesture recognizers |
| **UIKit** | Adaptive layout | Auto Layout, trait collections, size classes for adaptive interfaces |
| **UIKit** | Multitasking | Split view, slide over, Stage Manager, multiple windows on iPadOS |
| **UIKit** | Haptic feedback | UIFeedbackGenerator for impact, selection, and notification haptics |
| **UIKit** | Context menus | Long-press context menus with previews and actions |
| **UIKit** | Drag and drop | Inter- and intra-app drag and drop on iPad |

### Data & Storage

| Library | Category | Capabilities |
|---|---|---|
| **Foundation** | Collections | Array, Dictionary, Set, and specialized types (OrderedDictionary, Deque) |
| **Foundation** | Networking | URLSession for HTTP/HTTPS requests, downloads, uploads, WebSocket |
| **Foundation** | JSON/XML parsing | JSONDecoder/Encoder, JSONSerialization, XMLParser for data interchange |
| **Foundation** | File management | FileManager for file/directory operations, attributes, and coordination |
| **Foundation** | Date/time | Date, Calendar, DateFormatter, DateComponents, TimeZone handling |
| **Foundation** | Formatting | NumberFormatter, MeasurementFormatter, PersonNameComponents, ListFormatter |
| **Foundation** | Regex | Swift Regex with compile-time checking, RegexBuilder DSL |
| **Foundation** | Notifications | NotificationCenter for observer-pattern pub/sub communication |
| **Foundation** | Concurrency | OperationQueue, async/await integration, Process (subprocess launching) |
| **Foundation** | Localization | String localization, bundle resource loading, locale-aware formatting |
| **Foundation** | UserDefaults | Simple key-value persistent storage for preferences |
| **Foundation** | PropertyList | Read/write plist files (XML/binary) via PropertyListSerialization |
| **Foundation** | Archiving | Codable protocol, NSKeyedArchiver for object serialization |
| **SwiftData** | ORM | Swift-native persistence with @Model macro and schema declarations |
| **SwiftData** | Queries | #Predicate macro for type-safe queries with sorting and filtering |
| **SwiftData** | Migration | Lightweight and custom schema migration support |
| **SwiftData** | CloudKit sync | Automatic sync with iCloud via CloudKit integration |
| **SwiftData** | SwiftUI binding | @Query property wrapper for automatic UI updates on data changes |
| **CoreData** | Object graph | Managed object graph with relationships, fetched properties, and inheritance |
| **CoreData** | Persistence | SQLite, binary, and in-memory persistent stores |
| **CoreData** | Fetch requests | NSFetchRequest with predicates, sort descriptors, and batch fetching |
| **CoreData** | CloudKit sync | NSPersistentCloudKitContainer for automatic iCloud sync |
| **CoreData** | Batch operations | Batch insert, update, and delete for bulk data operations |
| **CoreData** | Migration | Lightweight and heavyweight (mapping model) schema migration |
| **CoreData** | History tracking | Persistent history tracking for background processing and sync |
| **CloudKit** | Cloud database | Store structured records in iCloud public, private, and shared databases |
| **CloudKit** | Subscriptions | Push notifications on record changes (query, zone, database subscriptions) |
| **CloudKit** | Sharing | Share records between iCloud users with role-based permissions |
| **CloudKit** | Assets | Store large binary assets (images, files) attached to records |
| **CloudKit** | Zones | Organize records into custom zones for atomic operations |
| **CloudKit** | Server-to-server | Server-side API for web services to access CloudKit containers |
| **FileProvider** | File extension | Provide cloud-stored files to the system Files app and file dialogs |
| **FileProvider** | Materialization | On-demand download/upload with progress and eviction support |
| **FileProvider** | Sync | Incremental sync engine for cloud file providers |

### Networking & Communication

| Library | Category | Capabilities |
|---|---|---|
| **Network** | TCP/UDP | Modern API for TCP, UDP, and QUIC connections and listeners |
| **Network** | TLS | Built-in TLS/DTLS with certificate pinning and custom verification |
| **Network** | Path monitoring | Monitor network path changes (Wi-Fi, cellular, VPN status) |
| **Network** | Bonjour | Browse and advertise Bonjour/mDNS services on the local network |
| **Network** | WebSocket | Native WebSocket protocol support via NWProtocolWebSocket |
| **Network** | Proxy support | Automatic proxy configuration and CONNECT tunnel support |
| **MultipeerConnectivity** | Peer discovery | Discover nearby peers via Wi-Fi, Bluetooth, and peer-to-peer Wi-Fi |
| **MultipeerConnectivity** | Messaging | Send data, stream bytes, and transfer files between peers |
| **MultipeerConnectivity** | Sessions | Manage multi-peer sessions with automatic reconnection |
| **CallKit** | VoIP integration | Integrate VoIP calls with native Phone UI (incoming call screen, recents) |
| **CallKit** | Call directory | Caller ID identification and call blocking extensions |
| **PushKit** | VoIP push | Receive VoIP push notifications to wake app for incoming calls |
| **PushKit** | Complication push | Push updates to watchOS complications |
| **WebKit** | Web content | Display web content with WKWebView (full WebKit rendering engine) |
| **WebKit** | JavaScript bridge | Two-way communication between Swift/ObjC and JavaScript |
| **WebKit** | Content rules | Content blocking rules (Safari-style ad blocking) |
| **WebKit** | Navigation control | Intercept and control page navigation, authentication challenges |
| **WebKit** | Extensions | Safari Web Extensions for customizing browser behavior |
| **LinkPresentation** | URL previews | Fetch and display rich link previews (title, icon, image, video) |

### Location, Maps & Sensors

| Library | Category | Capabilities |
|---|---|---|
| **CoreLocation** | GPS location | Get device latitude/longitude/altitude with configurable accuracy |
| **CoreLocation** | Geocoding | Forward/reverse geocoding (address to coordinates and back) |
| **CoreLocation** | Region monitoring | Monitor entry/exit of geographic regions (geofencing) |
| **CoreLocation** | Beacon ranging | Detect and range iBeacon Bluetooth beacons |
| **CoreLocation** | Heading | Get compass heading (magnetic and true north) |
| **CoreLocation** | Visit monitoring | Detect when user arrives at or departs from a location |
| **CoreLocation** | Background location | Continuous location updates in the background |
| **MapKit** | Map display | Display interactive maps with Apple Maps rendering |
| **MapKit** | Annotations/overlays | Add pins, custom annotations, polylines, polygons, circles, and custom overlays |
| **MapKit** | Search | Search for points of interest, addresses, and places via MKLocalSearch |
| **MapKit** | Directions | Calculate driving, walking, and transit routes between locations |
| **MapKit** | Look Around | Embed Apple's street-level imagery (Look Around) in apps |
| **MapKit** | Map snapshots | Generate static map images server-side or on-device |
| **MapKit** | Map configuration | Satellite, flyover, standard, and hybrid map styles with filtering |
| **CoreMotion** | Accelerometer | Raw accelerometer data (x, y, z acceleration) |
| **CoreMotion** | Gyroscope | Raw gyroscope data (rotation rate around three axes) |
| **CoreMotion** | Magnetometer | Raw magnetometer data for compass and magnetic field detection |
| **CoreMotion** | Device motion | Fused sensor data: attitude, rotation rate, gravity, user acceleration |
| **CoreMotion** | Pedometer | Step count, distance, pace, floors ascended/descended |
| **CoreMotion** | Activity recognition | Detect activity type: walking, running, cycling, driving, stationary |
| **CoreMotion** | Altitude | Relative altitude changes via barometric pressure (CMAltimeter) |
| **CoreBluetooth** | BLE central | Scan, connect, read/write characteristics of BLE peripherals |
| **CoreBluetooth** | BLE peripheral | Advertise services and respond to read/write requests as a peripheral |
| **CoreBluetooth** | Background BLE | BLE operations in background mode with state restoration |
| **CoreBluetooth** | L2CAP channels | Low-latency stream-oriented data transfer via L2CAP |
| **CoreNFC** | Tag reading | Read NFC tags: NDEF, ISO 7816, ISO 15693, FeliCa, MIFARE |
| **CoreNFC** | Tag writing | Write NDEF messages to NFC tags |
| **CoreNFC** | Custom APDUs | Send custom APDU commands to ISO 7816 smart cards |
| **CoreHaptics** | Custom haptics | Design and play custom haptic patterns with precise timing |
| **CoreHaptics** | Audio-haptic sync | Synchronize haptic feedback with audio playback |
| **CoreHaptics** | Pattern parameters | Control intensity, sharpness, and envelope of haptic events |
| **Nearby Interaction** | UWB ranging | Peer-to-peer distance and direction using Ultra-Wideband (U1/U2 chip) |
| **Nearby Interaction** | Accessory support | UWB-based precise finding for third-party accessories |

### Augmented Reality

| Library | Category | Capabilities |
|---|---|---|
| **ARKit** | World tracking | Track device position and orientation in 3D space (6DoF) |
| **ARKit** | Plane detection | Detect horizontal and vertical surfaces in the environment |
| **ARKit** | Image tracking | Detect and track 2D reference images in the real world |
| **ARKit** | Object detection | Detect and track 3D reference objects |
| **ARKit** | Face tracking | Track facial expressions with 52 blend shapes (TrueDepth camera) |
| **ARKit** | Body tracking | Full body motion capture with 91 skeleton joints |
| **ARKit** | Scene geometry | LiDAR-based mesh reconstruction of the environment |
| **ARKit** | Raycasting | Cast rays from screen points into the real-world scene |
| **ARKit** | Light estimation | Estimate ambient lighting conditions for realistic rendering |
| **ARKit** | Collaboration | Share AR world maps between devices for multi-user experiences |
| **ARKit** | Geo anchors | Place AR content at specific real-world GPS coordinates |
| **ARKit** | Scene understanding | Room classification, object placement on surfaces, occlusion |

### Security & Authentication

| Library | Category | Capabilities |
|---|---|---|
| **Security** | Keychain | Store passwords, keys, and certificates securely in the Keychain |
| **Security** | Certificates | Evaluate certificate trust, create certificate chains |
| **Security** | Cryptography | Encrypt/decrypt (AES, RSA), sign/verify, hash (SHA) via CommonCrypto |
| **Security** | Secure Transport | TLS/SSL session management (legacy, prefer Network framework) |
| **Security** | Code signing | Verify code signatures and entitlements at runtime |
| **Security** | Access control | Set biometric/passcode requirements for Keychain items |
| **CryptoKit** | Hashing | SHA-256, SHA-384, SHA-512, and HMAC |
| **CryptoKit** | Symmetric encryption | AES-GCM and ChaChaPoly authenticated encryption |
| **CryptoKit** | Public-key crypto | Curve25519, P-256, P-384, P-521 for key agreement and signing |
| **CryptoKit** | Secure Enclave | Generate and use private keys protected by the Secure Enclave |
| **CryptoKit** | Key derivation | HKDF for deriving symmetric keys from shared secrets |
| **LocalAuthentication** | Biometrics | Authenticate via Face ID or Touch ID |
| **LocalAuthentication** | Device passcode | Fall back to device passcode/password authentication |
| **LocalAuthentication** | Policy evaluation | Evaluate authentication policies (biometric, passcode, watch) |
| **AuthenticationServices** | Sign in with Apple | Authenticate users with Apple ID (privacy-preserving) |
| **AuthenticationServices** | Passkeys | Create and use FIDO2/WebAuthn passkeys for passwordless login |
| **AuthenticationServices** | Password autofill | Integrate with system password autofill and Keychain |
| **AuthenticationServices** | OAuth/web login | ASWebAuthenticationSession for OAuth and web-based login flows |
| **DeviceCheck** | Device attestation | Generate per-device tokens to verify with your server (DeviceCheck) |
| **DeviceCheck** | App attestation | Attest app integrity to prevent tampering (App Attest) |

### App Services & System Integration

| Library | Category | Capabilities |
|---|---|---|
| **App Intents** | Shortcuts | Define app actions discoverable by Siri, Shortcuts, and Spotlight |
| **App Intents** | App Shortcuts | Automatically available shortcuts without user setup (iOS 16+) |
| **App Intents** | Parameters | Rich parameter types with dynamic options, validation, and disambiguation |
| **App Intents** | Entities | Expose app entities (e.g., documents, contacts) for Siri queries |
| **App Intents** | Focus filters | Customize app behavior based on the user's current Focus mode |
| **WidgetKit** | Home screen widgets | Display glanceable content on the home screen (iOS) or desktop (macOS) |
| **WidgetKit** | Lock screen widgets | Small widgets on the iOS lock screen (circular, rectangular, inline) |
| **WidgetKit** | Interactive widgets | Buttons and toggles directly in widgets (iOS 17+) |
| **WidgetKit** | Timeline provider | Provide widget content snapshots at scheduled intervals |
| **ActivityKit** | Live Activities | Display real-time updating content on lock screen and Dynamic Island |
| **ActivityKit** | Push updates | Update Live Activities via push notifications |
| **TipKit** | Feature tips | Display contextual tips to teach users about features |
| **TipKit** | Rules | Show tips based on event counts, parameter conditions, or custom rules |
| **TipKit** | Sync | Sync tip state across devices via iCloud |
| **StoreKit** | In-app purchases | Sell consumable, non-consumable, and subscription products |
| **StoreKit** | Subscriptions | Manage auto-renewable subscriptions with offer codes, trials, and grace periods |
| **StoreKit** | Transaction history | Verify and manage purchase transactions (StoreKit 2: async/await API) |
| **StoreKit** | Refund requests | Initiate refund requests from within the app |
| **StoreKit** | App Store review | Request App Store ratings and reviews (SKStoreReviewController) |
| **StoreKit** | Product display | System-provided product purchase UI (SubscriptionStoreView) |
| **UserNotifications** | Local notifications | Schedule local notifications with text, images, sounds, and actions |
| **UserNotifications** | Push notifications | Handle remote push notifications (APNs) |
| **UserNotifications** | Rich notifications | Notification content extensions with custom UI |
| **UserNotifications** | Notification actions | Interactive actions and text input in notifications |
| **UserNotifications** | Notification groups | Group and manage notifications by thread or category |
| **EventKit** | Calendar access | Read and write events in the user's calendars |
| **EventKit** | Reminders | Read and write reminders in the user's Reminders app |
| **EventKit** | Recurring events | Create and modify events with complex recurrence rules |
| **EventKit** | Calendar UI | Built-in event editing and viewing controllers (EventKitUI) |
| **Contacts** | Contact access | Read and write contacts from the user's address book |
| **Contacts** | Contact UI | Built-in contact picker and detail view controllers |
| **Contacts** | Formatting | Locale-aware name and postal address formatting |
| **Photos** | Photo library | Read and write photos/videos in the user's photo library |
| **Photos** | Albums/moments | Access albums, smart albums, and moments |
| **Photos** | Asset editing | Non-destructive photo/video editing with adjustment data |
| **Photos** | Change observation | Observe and react to photo library changes in real time |
| **Photos** | iCloud Photos | Access iCloud Photo Library with on-demand downloading |
| **PhotosUI** | Photo picker | System photo picker (PHPickerViewController) with privacy-preserving access |
| **CoreSpotlight** | Indexing | Index app content for Spotlight search results |
| **CoreSpotlight** | Search results | Display app content in Spotlight with titles, descriptions, and thumbnails |
| **CoreSpotlight** | Search continuation | Deep-link from Spotlight results directly into app content |

### Health, Fitness & Home

| Library | Category | Capabilities |
|---|---|---|
| **HealthKit** | Health data | Read/write 100+ health data types: heart rate, steps, sleep, nutrition, labs |
| **HealthKit** | Workouts | Record and query workout sessions with route and heart rate data |
| **HealthKit** | Statistics | Compute statistics (sum, average, min, max) over health data time ranges |
| **HealthKit** | Background delivery | Receive callbacks when new health data is available in the background |
| **HealthKit** | Clinical records | Access FHIR-formatted clinical health records (allergies, conditions, meds) |
| **HealthKit** | Electrocardiogram | Read ECG waveform data from Apple Watch recordings |
| **HomeKit** | Device control | Control smart home accessories: lights, locks, thermostats, cameras, switches |
| **HomeKit** | Scenes | Activate predefined scenes that set multiple accessories at once |
| **HomeKit** | Automation | Create trigger-based automations (time, location, accessory state, sensor) |
| **HomeKit** | Cameras/doorbells | Stream live video from HomeKit cameras and doorbells |
| **HomeKit** | Matter support | Control Matter-compatible smart home devices |
| **WeatherKit** | Current weather | Get current conditions: temperature, humidity, wind, UV index, visibility |
| **WeatherKit** | Forecasts | Hourly and daily weather forecasts for any location |
| **WeatherKit** | Severe weather | Active weather alerts and severe weather notifications |
| **WeatherKit** | Historical weather | Access historical weather data for past dates |
| **WeatherKit** | Minute-by-minute | Next-hour precipitation forecast (where available) |

### System & Low-Level

| Library | Category | Capabilities |
|---|---|---|
| **Combine** | Reactive streams | Publisher/Subscriber pattern for asynchronous event processing |
| **Combine** | Operators | Map, filter, merge, zip, combineLatest, debounce, throttle, retry, and more |
| **Combine** | Integration | Built-in publishers for URLSession, NotificationCenter, KVO, Timer |
| **Observation** | @Observable | Macro-based observation for automatic UI updates without Combine boilerplate |
| **Observation** | Tracking | Fine-grained property-level tracking (only re-render on changed properties) |
| **Accelerate** | Vector/matrix math | High-performance SIMD, BLAS, LAPACK, and vDSP operations |
| **Accelerate** | Signal processing | FFT, convolution, correlation, and digital filtering |
| **Accelerate** | Image processing | vImage: fast image scaling, format conversion, convolution, histogram, alpha compositing |
| **Accelerate** | Compression | LZFSE, LZ4, ZLIB, LZMA compression and decompression |
| **Accelerate** | Sparse math | Sparse matrix solvers and operations |
| **SystemConfiguration** | Reachability | Monitor network reachability (SCNetworkReachability) |
| **SystemConfiguration** | Dynamic store | Access and monitor system configuration values |
| **IOKit** | Device access | Communicate with hardware devices and drivers (macOS) |
| **IOKit** | USB/HID | Access USB devices and HID (human interface) devices |
| **IOKit** | Power management | Monitor battery level, charging state, and power source changes |
| **IOKit** | Storage info | Query disk/volume properties and SMART data |
| **DiskArbitration** | Disk events | Monitor disk mount, unmount, eject, and rename events (macOS) |
| **DiskArbitration** | Disk approval | Approve or deny disk mount/unmount operations |
| **Virtualization** | Virtual machines | Create and run lightweight Linux and macOS VMs on Apple Silicon |
| **Virtualization** | Shared directories | Share directories between host and guest VM |
| **Virtualization** | Networking | NAT and bridged networking for virtual machines |
| **Virtualization** | Rosetta in Linux | Run x86_64 Linux binaries inside ARM Linux VMs via Rosetta |
| **EndpointSecurity** | System events | Monitor file, process, and network events system-wide (macOS security tools) |
| **EndpointSecurity** | Event authorization | Allow or deny system events in real time (endpoint security extensions) |
| **OSLog** | Structured logging | High-performance structured logging with categories and levels |
| **OSLog** | Log store | Query and retrieve persisted log messages from the unified log |
| **os** | Signposts | Instrument code with signposts for Instruments profiling |
| **os** | Locks | os_unfair_lock for low-level, high-performance mutual exclusion |
| **XCTest** | Unit testing | Write and run unit tests with assertions, expectations, and async support |
| **XCTest** | UI testing | Automated UI testing with accessibility-based element queries |
| **XCTest** | Performance testing | Measure code execution time and memory usage with baselines |
| **Swift Testing** | Modern testing | Macro-based test framework with @Test, #expect, parameterized tests |
| **Swift Testing** | Tags/traits | Organize tests with tags, display names, enabled/disabled traits |
| **Distributed** | Distributed actors | Swift actor-based framework for building distributed systems |
| **Distributed** | Transport | Pluggable transport layer for distributed actor communication |
| **UniformTypeIdentifiers** | Type identifiers | Declare and query file/data types (replaces UTI C API) |
| **UniformTypeIdentifiers** | Conformance | Check type conformance hierarchies (e.g., "is this a type of image?") |

### Game Development

| Library | Category | Capabilities |
|---|---|---|
| **GameKit** | Game Center | Leaderboards, achievements, and player profiles |
| **GameKit** | Matchmaking | Real-time and turn-based multiplayer matchmaking |
| **GameKit** | Challenges | Player-to-player challenges based on leaderboard scores or achievements |
| **GameKit** | Access Point | Floating Game Center dashboard access point in-game |
| **GameController** | MFi controllers | Support MFi, Xbox, PlayStation, and generic Bluetooth game controllers |
| **GameController** | Virtual controller | On-screen virtual game controller overlay |
| **GameController** | Keyboard/mouse | Direct keyboard and mouse input for macOS and iPad games |
| **GameController** | Motion | Controller motion sensing (gyroscope, accelerometer) |
| **Game Center** | Friends | Access player friend lists and multiplayer invitations |

### Sharing & Extensions

| Library | Category | Capabilities |
|---|---|---|
| **ShareKit/UIActivityViewController** | Share sheet | Present the system share sheet for sharing content |
| **App Extensions** | Share extension | Add custom actions to the share sheet |
| **App Extensions** | Today widget | Show app content in the Today view/Notification Center (legacy) |
| **App Extensions** | Action extension | Provide custom actions on selected content (e.g., translate, markup) |
| **App Extensions** | Keyboard extension | Create custom system keyboards |
| **App Extensions** | Photo editing | Provide photo/video editing capabilities within the Photos app |
| **App Extensions** | Content blocker | Block content in Safari (ads, trackers) via rule-based lists |
| **App Extensions** | Finder Sync | Add badges, contextual menus, and toolbars in Finder (macOS) |
| **App Extensions** | Credential provider | Supply passwords and passkeys to the autofill system |
| **App Groups** | Shared container | Share files and UserDefaults between an app and its extensions |
| **App Groups** | Shared CoreData | Share a CoreData/SwiftData store between app and extensions |

## Language Availability Breakdown: Swift vs Objective-C

### Available to Both Swift & Objective-C (~50+ frameworks)

The vast majority of Apple frameworks were originally written in Objective-C (or C) and are fully bridged to Swift: Foundation, UIKit, AppKit, CoreGraphics, CoreImage, CoreData, AVFoundation, AVFAudio, CoreLocation, MapKit, CoreBluetooth, CoreMotion, HealthKit, HomeKit, CloudKit, Metal, MetalKit, SceneKit, SpriteKit, ARKit, CoreML, Vision, NaturalLanguage, CoreAnimation, WebKit, StoreKit (v1), GameKit, GameController, Network, Security, LocalAuthentication, AuthenticationServices, UserNotifications, Photos, PhotosUI, Contacts, EventKit, CoreSpotlight, Speech, SoundAnalysis, CreateML, Accelerate, PDFKit, PencilKit, ScreenCaptureKit, CoreNFC, CoreHaptics, MultipeerConnectivity, CallKit, PushKit, Virtualization, EndpointSecurity, XCTest, LinkPresentation, DeviceCheck, CoreAudio, CoreMIDI, MediaPlayer, FileProvider, WeatherKit, etc.

### Swift-Only Frameworks (~15+)

These have **no** Objective-C API:

| Framework | Introduced |
|---|---|
| **SwiftUI** | 2019 |
| **Combine** | 2019 |
| **CryptoKit** | 2019 |
| **RealityKit** | 2019 |
| **Swift Charts** | 2022 |
| **SwiftData** | 2023 |
| **Observation** | 2023 |
| **TipKit** | 2023 |
| **App Intents** | 2022 |
| **WidgetKit** | 2020 |
| **ActivityKit** | 2022 |
| **StoreKit 2** | 2021 |
| **MusicKit** (modern) | 2021 |
| **Translation** | 2024 |
| **Swift Testing** | 2024 |
| **Distributed** | 2022 |

### Objective-C Only: Zero

There are no frameworks that work in Objective-C but **not** in Swift. Swift can call any Objective-C API via bridging.

### Pure C APIs (usable from both, but not "native" to either)

CoreGraphics, CoreAudio, IOKit, SystemConfiguration, DiskArbitration, ImageIO, and parts of Security/Accelerate are C APIs — callable from both languages but feel more natural in neither.

### Summary

| Category | Count | % |
|---|---|---|
| Both Swift & ObjC | ~50+ | ~75% |
| Swift-only | ~15+ | ~20% |
| ObjC-only | 0 | 0% |
| Pure C (both) | ~8 | ~5% |

Apple stopped creating Objective-C APIs in ~2019. Every new framework since then has been Swift-only. The existing ObjC frameworks remain accessible from both languages, but all new development is happening on the Swift side.

## Current Usage in This Project

This project currently uses a narrow slice of these frameworks:

- **ScreenCaptureKit** -- capturing screenshots
- **Vision** -- OCR text recognition (`VNRecognizeTextRequest`)
- **CoreGraphics** -- drawing annotation rectangles and image I/O
