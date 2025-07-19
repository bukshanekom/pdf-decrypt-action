
#!/bin/bash

set -e

echo "Installing PDF Decrypt Action..."

# Check if macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is designed for macOS only."
    exit 1
fi

# Check macOS version (require macOS 13+)
MACOS_VERSION=$(sw_vers -productVersion)
MAJOR_VERSION=$(echo "$MACOS_VERSION" | cut -d. -f1)

if [[ $MAJOR_VERSION -lt 13 ]]; then
    echo "This script requires macOS 13 (Ventura) or later."
    echo "Your version: $MACOS_VERSION"
    exit 1
fi

# Check if qpdf is installed
if ! command -v qpdf &> /dev/null; then
    echo "qpdf is required but not installed."
    echo "Please install it with: brew install qpdf"
    exit 1
fi

# Create directories
SCRIPT_DIR="$HOME/Library/Scripts"
QUICKACTION_DIR="$HOME/Library/Services"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$QUICKACTION_DIR"

# Download the main script
echo "Downloading main script..."
curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/decrypt-pdf-action.sh -o "$SCRIPT_DIR/decrypt-pdf-action.sh"
chmod +x "$SCRIPT_DIR/decrypt-pdf-action.sh"

# Download the AppleScript for enabling extensions
echo "Downloading AppleScript helper..."
curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/enable_extensions.applescript -o "$SCRIPT_DIR/enable_extensions.applescript"

# Create Automator Quick Action directory
mkdir -p "$QUICKACTION_DIR/PDF Decrypt Action.workflow/Contents"

# Create Automator Quick Action Info.plist
cat > "$QUICKACTION_DIR/PDF Decrypt Action.workflow/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSIconName</key>
			<string>NSActionTemplate</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>PDF Decrypt Action</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSRequiredContext</key>
			<array>
				<dict>
					<key>NSApplicationIdentifier</key>
					<string>com.apple.finder</string>
				</dict>
			</array>
			<key>NSSendFileTypes</key>
			<array>
				<string>com.adobe.pdf</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF

# Create the workflow document.wflow file
cat > "$QUICKACTION_DIR/PDF Decrypt Action.workflow/Contents/document.wflow" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>528</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>$HOME/Library/Scripts/decrypt-pdf-action.sh "$@"</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>915F07C4-4890-4FBA-9A30-A821AA3C8710</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>DB1ED7DB-A16D-450B-84A9-99C4189E4B3F</string>
				<key>UUID</key>
				<string>E0EBCA63-860C-4A5B-A419-4125C4D3DC8E</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>706.000000:305.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleID</key>
		<string>com.apple.finder</string>
		<key>applicationBundleIDsByPath</key>
		<dict>
			<key>/System/Library/CoreServices/Finder.app</key>
			<string>com.apple.finder</string>
		</dict>
		<key>applicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>applicationPaths</key>
		<array>
			<string>/System/Library/CoreServices/Finder.app</string>
		</array>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.PDF</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>15</integer>
		<key>processesInput</key>
		<integer>0</integer>
		<key>serviceApplicationBundleID</key>
		<string>com.apple.finder</string>
		<key>serviceApplicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.PDF</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
EOF

# Create example password file if it doesn't exist
if [ ! -f "$HOME/.decrypt-pdf-action" ]; then
    echo "Creating example password file..."
    echo "# Add your passwords here, one per line" > "$HOME/.decrypt-pdf-action"
    echo "# Example:" >> "$HOME/.decrypt-pdf-action"
    echo "# password123" >> "$HOME/.decrypt-pdf-action"
    echo "# your_id_number" >> "$HOME/.decrypt-pdf-action"
    echo ""
    echo "Please edit ~/.decrypt-pdf-action and add your passwords"
fi

# Refresh services database
echo "Refreshing services database..."
/System/Library/CoreServices/pbs -flush

echo ""
echo "✅ Installation complete!"
echo ""

echo "🔧 IMPORTANT: Enable the Quick Action"
echo ""
echo "Would you like to run automated UI exploration to find and enable the PDF Decrypt Action? (y/n)"
printf "Your choice: "
read REPLY

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🤖 Running automated UI exploration..."
    echo ""

    # Run the downloaded AppleScript
    if osascript "$SCRIPT_DIR/enable_extensions.applescript"; then
        echo "✅ UI exploration completed!"
        echo "Check the debug log for details: ~/Library/Logs/applescript-debug.log"
    else
        echo "⚠️ AppleScript failed. Check the log file: ~/Library/Logs/applescript-debug.log"
    fi

else
    echo ""
    echo "📝 To enable manually:"
    echo "   1. System Settings → Login Items & Extensions"
    echo "   2. Click 'Extensions' on the right side"
    echo "   3. Find 'PDF Decrypt Action' and enable it"
fi

echo ""
echo "📝 Setup passwords:"
echo "   Edit ~/.decrypt-pdf-action and add your passwords (one per line)"
echo ""
echo "🎯 Usage after setup:"
echo "   Right-click any PDF → Quick Actions → 'PDF Decrypt Action'"
echo ""
echo "📊 Debug logs: ~/Library/Logs/applescript-debug.log"