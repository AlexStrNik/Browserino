from pathlib import Path
import re,json
source=Path('Browserino/Models/BrowserTabScripting.swift').read_text()
scripts=re.findall(r'runScript\("""\n(.*?)\n        """',source,re.S)
scripts.append(scripts[0].replace('\\(property)', 'current tab').replace('\\(tabID)', '0').replace('\\(identifier)', 'com.apple.Safari'))
swift=['import AppKit','var failures = 0']
for index,script in enumerate(scripts):
 script=script.replace('\\(identifier)','com.google.Chrome').replace('\\(property)','active tab').replace('\\(tabID)','(id of t) as integer').replace('\\(source.bundleIdentifier)','com.google.Chrome').replace('\\(source.identity.windowID)','1').replace('\\(source.identity.tabID)','2')
 assert '\\(' not in script
 swift+=['do {','let source = '+json.dumps(script),'let script = NSAppleScript(source: source)!','var error: NSDictionary?','if !script.compileAndReturnError(&error) { FileHandle.standardError.write(Data(String(describing: error).utf8)); failures += 1 }','}']
swift+=['if failures != 0 { fatalError("AppleScript compile failed") }','print("AppleScript syntax checks passed")']
Path('/tmp/browserino-check-scripts.swift').write_text('\n'.join(swift)+'\n')
