#PDF Decrypt Action

A macOS shell script that automatically decrypts password-protected PDFs and removes PDF restrictions using multiple passwords. Designed to work seamlessly with Finder Quick Actions and iCloud Drive.

##Features

- Password-protected PDF decryption - Decrypt PDFs using stored passwords
- Remove PDF restrictions - Remove copy, print, and edit restrictions
- Multiple password support - Try multiple passwords automatically
- Batch processing - Process multiple PDFs at once
- iCloud Drive integration - Automatically downloads files from iCloud
- macOS notifications - Real-time progress updates
- Detailed logging - Comprehensive logs in ~/Library/Logs/
- Finder integration - Works as a Quick Action in Finder

##Requirements

- macOS 10.14 or later
- qpdf - Install via Homebrew

##Quick Start

1. Install qpdf:
   `brew install qpdf`

2. Download and install the script:
   `curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/install.sh | bash`

3. Set up your passwords:
   echo "your_password_1" > ~/.decrypt-pdf-action
   echo "your_password_2" >> ~/.decrypt-pdf-action

4. Use with Finder: Right-click any PDF → Services → "PDF Decrypt Action"

##Installation

###Automatic Installation:
`curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/install.sh | bash`

###Manual Installation
1. Clone the repository:
   `git clone https://github.com/bukshanekom/pdf-decrypt-action.git`
   `cd pdf-decrypt-action`

2. Run the install script:
   `./install.sh`

###Usage

Password File Setup
Create a password file with one password per line:
`echo "password1" > ~/.decrypt-pdf-action`
`echo "password2" >> ~/.decrypt-pdf-action`
`echo "password3" >> ~/.decrypt-pdf-action`

###Using with Finder
1. Right-click on one or more PDF files
2. Select "Services" → "PDF Decrypt Action"
3. The script will process the files and show progress notifications

###Command Line Usage
`./decrypt-pdf-action.sh /path/to/encrypted.pdf`
`./decrypt-pdf-action.sh /path/to/multiple/*.pdf`

###Documentation
- Installation Guide: docs/INSTALLATION.md
- Usage Guide: docs/USAGE.md
- Troubleshooting: docs/TROUBLESHOOTING.md

###Uninstallation
`curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/uninstall.sh | bash`

##Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

##License

MIT License - see LICENSE file for details.

##Security Notice:

This script stores passwords in plain text in ~/.decrypt-pdf-action. Ensure this file has appropriate permissions and consider the security implications for your use case.

##Support:
If you got this far, you are smart enough to figure it out yourself... if not, phone a friend

- Issues: GitHub Issues
- Discussions: GitHub Discussions
- Wiki: GitHub Wiki
