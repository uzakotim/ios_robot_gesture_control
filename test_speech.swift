import Speech
import AVFoundation

let eng = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
let rus = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
print(eng != nil)
print(rus != nil)
