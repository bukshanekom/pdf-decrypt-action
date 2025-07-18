#!/bin/bash

# Create log file in proper macOS user logs directory
LOGDIR="$HOME/Library/Logs"
LOGFILE="$LOGDIR/decrypt-pdf-action.log"

# Create the logs directory if it doesn't exist
mkdir -p "$LOGDIR"

echo "=== PDF Decryption Debug Log - $(date) ===" > "$LOGFILE"

# Load passwords from file
PASSWORD_FILE="$HOME/.decrypt-pdf-action"

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR: Password file not found at $PASSWORD_FILE" >> "$LOGFILE"
    echo "Please create the file ~/.decrypt-pdf-action with your password(s)" >> "$LOGFILE"
    osascript -e "display notification \"Please create ~/.decrypt-pdf-action with your password(s)\" with title \"PDF Decryption Setup Required\""

    # Show a more helpful dialog
    osascript -e "display dialog \"Password file not found!\n\nPlease create the file:\n~/.decrypt-pdf-action\n\nPut one password per line.\n\nExample:\necho \\\"PASSWORD1\\\" > ~/.decrypt-pdf-action\necho \\\"PASSWORD2\\\" >> ~/.decrypt-pdf-action\" with title \"PDF Decryption Setup\" buttons {\"OK\"} default button \"OK\" with icon caution"

    exit 0  # Exit with success code to avoid generic error popup
fi

# Read passwords from file (remove empty lines and trim whitespace)
PASSWORDS=()
while IFS= read -r line; do
    # Trim whitespace and skip empty lines
    trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$trimmed_line" ]; then
        PASSWORDS+=("$trimmed_line")
    fi
done < "$PASSWORD_FILE"

if [ ${#PASSWORDS[@]} -eq 0 ]; then
    echo "ERROR: No passwords found in file" >> "$LOGFILE"
    osascript -e "display notification \"No passwords found in file\" with title \"PDF Decryption\""
    osascript -e "display dialog \"The password file ~/.decrypt-pdf-action exists but contains no valid passwords.\n\nPlease add your password(s) to it (one per line).\n\nExample:\necho \\\"PASSWORD1\\\" > ~/.decrypt-pdf-action\necho \\\"PASSWORD2\\\" >> ~/.decrypt-pdf-action\" with title \"PDF Decryption Setup\" buttons {\"OK\"} default button \"OK\" with icon caution"
    exit 0  # Exit with success code to avoid generic error popup
fi

echo "Loaded ${#PASSWORDS[@]} password(s) from file" >> "$LOGFILE"
for i in "${!PASSWORDS[@]}"; do
    echo "Password $((i+1)): length ${#PASSWORDS[i]} characters" >> "$LOGFILE"
done

# Check if processing multiple files
MULTIPLE_FILES=false
if [ $# -gt 1 ]; then
    MULTIPLE_FILES=true
    echo "Processing multiple files ($# files) - suppressing individual popups" >> "$LOGFILE"
fi

# Initialize counters for batch processing
TOTAL_FILES=$#
PROCESSED_COUNT=0
SUCCESS_COUNT=0
SKIP_COUNT=0
FAILED_COUNT=0

for f in "$@"
do
    echo "Processing file: $f" >> "$LOGFILE"

    # Show notification (always show these)
    osascript -e "display notification \"Processing: $(basename "$f")\" with title \"PDF Decryption\""

    # Check if file exists
    if [ ! -f "$f" ]; then
        echo "ERROR: File does not exist: $f" >> "$LOGFILE"
        osascript -e "display notification \"File not found\" with title \"PDF Decryption\""
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    echo "File exists, checking download status..." >> "$LOGFILE"

    # Check if file is actually downloaded by checking disk usage
    DISK_USAGE=$(du -k "$f" | cut -f1)
    echo "Disk usage: ${DISK_USAGE}k" >> "$LOGFILE"

    # If disk usage is 0, file is not downloaded
    if [ "$DISK_USAGE" -eq 0 ]; then
        echo "File is not downloaded from iCloud, forcing download..." >> "$LOGFILE"
        osascript -e "display notification \"Downloading from iCloud...\" with title \"PDF Decryption\""

        # Use brctl to download the file
        echo "Using brctl to download file..." >> "$LOGFILE"
        if command -v brctl > /dev/null 2>&1; then
            brctl download "$f" >> "$LOGFILE" 2>&1
            echo "brctl download command executed" >> "$LOGFILE"
        else
            echo "brctl not found, trying alternative method..." >> "$LOGFILE"

            # Alternative: use xattr to remove download-on-demand flag
            echo "Trying xattr method..." >> "$LOGFILE"
            xattr -d com.apple.icloud.needs-download "$f" >> "$LOGFILE" 2>&1

            # Or try opening with Preview to trigger download
            echo "Trying to open with Preview..." >> "$LOGFILE"
            open -a Preview "$f" >> "$LOGFILE" 2>&1
            sleep 3
            osascript -e 'tell application "Preview" to quit' >> "$LOGFILE" 2>&1
        fi

        # Wait and check if download completed
        echo "Waiting for download to complete..." >> "$LOGFILE"
        COUNT=0
        while [ $COUNT -lt 30 ]; do
            sleep 2
            NEW_DISK_USAGE=$(du -k "$f" | cut -f1)
            echo "Check $COUNT: Disk usage now ${NEW_DISK_USAGE}k" >> "$LOGFILE"

            if [ "$NEW_DISK_USAGE" -gt 0 ]; then
                echo "File downloaded successfully!" >> "$LOGFILE"
                osascript -e "display notification \"Download complete!\" with title \"PDF Decryption\""
                break
            fi

            COUNT=$((COUNT + 1))

            # Show progress every 5 checks
            if [ $((COUNT % 5)) -eq 0 ]; then
                osascript -e "display notification \"Still downloading... (${COUNT}0s)\" with title \"PDF Decryption\""
            fi
        done

        # Final check
        FINAL_DISK_USAGE=$(du -k "$f" | cut -f1)
        if [ "$FINAL_DISK_USAGE" -eq 0 ]; then
            echo "TIMEOUT: File still not downloaded after 30 attempts" >> "$LOGFILE"
            osascript -e "display notification \"Download timeout - try manually opening file first\" with title \"PDF Decryption\""
            FAILED_COUNT=$((FAILED_COUNT + 1))
            continue
        fi
    else
        echo "File is already downloaded" >> "$LOGFILE"
    fi

    # Now proceed with decryption
    echo "Starting PDF processing..." >> "$LOGFILE"

    # Check if it's a PDF
    HEADER=$(head -c 4 "$f" 2>/dev/null || echo "")
    echo "File header: '$HEADER'" >> "$LOGFILE"

    if ! echo "$HEADER" | grep -q "%PDF"; then
        echo "ERROR: File doesn't appear to be a PDF" >> "$LOGFILE"
        osascript -e "display notification \"Not a PDF file\" with title \"PDF Decryption\""
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    # Set up paths
    DIR=$(dirname "$f")
    BASENAME=$(basename "$f")

    # Create a temporary file with a unique name in /tmp
    TEMP_FILE="/tmp/pdf_decrypt_$$_$(date +%s).pdf"
    QPDF_PATH="/usr/local/bin/qpdf"

    # Check if qpdf exists
    if [ ! -f "$QPDF_PATH" ]; then
        echo "ERROR: qpdf not found at $QPDF_PATH" >> "$LOGFILE"
        osascript -e "display notification \"qpdf not found\" with title \"PDF Decryption\""
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi

    # Check encryption status by looking for encryption methods
    echo "Checking PDF encryption/restrictions status..." >> "$LOGFILE"
    ENCRYPTION_CHECK=$("$QPDF_PATH" --show-encryption "$f" 2>&1)
    ENCRYPTION_EXIT_CODE=$?
    echo "Encryption check exit code: $ENCRYPTION_EXIT_CODE" >> "$LOGFILE"
    echo "Encryption check output: $ENCRYPTION_CHECK" >> "$LOGFILE"

    # Initialize variables
    NEEDS_PROCESSING=false
    HAS_RESTRICTIONS_ONLY=false
    PROCESSING_TYPE=""

    # Look for encryption method indicators
    if echo "$ENCRYPTION_CHECK" | grep -q "encryption method:"; then
        echo "PDF has encryption methods - it's encrypted" >> "$LOGFILE"
        NEEDS_PROCESSING=true
        PROCESSING_TYPE="decryption"
    elif echo "$ENCRYPTION_CHECK" | grep -q "File is not encrypted"; then
        echo "PDF is explicitly not encrypted" >> "$LOGFILE"
        NEEDS_PROCESSING=false
    elif echo "$ENCRYPTION_CHECK" | grep -q "R = "; then
        # Has R (revision) but no encryption methods = restrictions only
        echo "PDF has restrictions but no encryption methods - removing restrictions" >> "$LOGFILE"
        NEEDS_PROCESSING=true
        HAS_RESTRICTIONS_ONLY=true
        PROCESSING_TYPE="restriction removal"
    else
        echo "Could not determine encryption status, assuming not encrypted" >> "$LOGFILE"
        NEEDS_PROCESSING=false
    fi

    # If no processing needed, skip
    if [ "$NEEDS_PROCESSING" = false ]; then
        echo "INFO: PDF has no encryption or restrictions - skipping processing" >> "$LOGFILE"
        osascript -e "display notification \"PDF has no encryption or restrictions\" with title \"PDF Processing\""

        # Only show popup for single file processing
        if [ "$MULTIPLE_FILES" = false ]; then
            osascript -e "display dialog \"✅ PDF Processing Complete\n\nFile: $(basename "$f")\n\nStatus: This PDF has no encryption or restrictions.\nNo processing was needed.\" with title \"PDF Status\" buttons {\"OK\"} default button \"OK\" with icon note"
        fi

        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # If we get here, the PDF needs processing
    if [ "$HAS_RESTRICTIONS_ONLY" = true ]; then
        echo "PDF has restrictions only, removing restrictions..." >> "$LOGFILE"
        osascript -e "display notification \"Removing PDF restrictions...\" with title \"PDF Processing\""
    else
        echo "PDF is encrypted, proceeding with decryption..." >> "$LOGFILE"
        osascript -e "display notification \"Decrypting PDF...\" with title \"PDF Processing\""
    fi

    # Try processing with multiple passwords
    PROCESSING_SUCCESSFUL=false
    SUCCESSFUL_PASSWORD=""
    LAST_OUTPUT=""

    # First try with empty password (for restrictions-only PDFs)
    echo "Attempting $PROCESSING_TYPE with empty password..." >> "$LOGFILE"
    OUTPUT=$("$QPDF_PATH" --decrypt --password="" "$f" "$TEMP_FILE" 2>&1)
    QPDF_EXIT_CODE=$?
    echo "Empty password - qpdf exit code: $QPDF_EXIT_CODE" >> "$LOGFILE"
    echo "Empty password - qpdf output: $OUTPUT" >> "$LOGFILE"

    if [ -f "$TEMP_FILE" ] && [ $QPDF_EXIT_CODE -eq 0 ]; then
        echo "SUCCESS: $PROCESSING_TYPE successful with empty password" >> "$LOGFILE"
        PROCESSING_SUCCESSFUL=true
        SUCCESSFUL_PASSWORD="(empty password)"
    else
        # Clean up failed temp file
        if [ -f "$TEMP_FILE" ]; then
            rm "$TEMP_FILE" 2>> "$LOGFILE"
        fi

        # Try each password from the file
        for i in "${!PASSWORDS[@]}"; do
            PASSWORD="${PASSWORDS[i]}"
            PASSWORD_NUM=$((i+1))

            echo "Attempting $PROCESSING_TYPE with password #$PASSWORD_NUM..." >> "$LOGFILE"

            OUTPUT=$("$QPDF_PATH" --decrypt --password="$PASSWORD" "$f" "$TEMP_FILE" 2>&1)
            QPDF_EXIT_CODE=$?
            echo "Password #$PASSWORD_NUM - qpdf exit code: $QPDF_EXIT_CODE" >> "$LOGFILE"
            echo "Password #$PASSWORD_NUM - qpdf output: $OUTPUT" >> "$LOGFILE"

            if [ -f "$TEMP_FILE" ] && [ $QPDF_EXIT_CODE -eq 0 ]; then
                echo "SUCCESS: $PROCESSING_TYPE successful with password #$PASSWORD_NUM" >> "$LOGFILE"
                PROCESSING_SUCCESSFUL=true
                SUCCESSFUL_PASSWORD="password #$PASSWORD_NUM"
                break
            else
                # Clean up failed temp file
                if [ -f "$TEMP_FILE" ]; then
                    rm "$TEMP_FILE" 2>> "$LOGFILE"
                fi

                # Show progress for multiple passwords
                if [ ${#PASSWORDS[@]} -gt 1 ]; then
                    osascript -e "display notification \"Trying password $PASSWORD_NUM of ${#PASSWORDS[@]}...\" with title \"PDF Processing\""
                fi
            fi

            # Store the last output for error reporting
            LAST_OUTPUT="$OUTPUT"
        done
    fi

    # Check if processing was successful
    if [ "$PROCESSING_SUCCESSFUL" = true ] && [ -f "$TEMP_FILE" ]; then
        echo "SUCCESS: $PROCESSING_TYPE successful using $SUCCESSFUL_PASSWORD" >> "$LOGFILE"
        echo "Temp file created: $TEMP_FILE" >> "$LOGFILE"
        echo "Temp file size: $(ls -l "$TEMP_FILE")" >> "$LOGFILE"

        # Remove the original file first
        echo "Removing original file..." >> "$LOGFILE"
        if rm "$f" 2>> "$LOGFILE"; then
            echo "Original file removed successfully" >> "$LOGFILE"

            # Now copy the temp file to the original location
            echo "Copying processed file to original location..." >> "$LOGFILE"
            if cp "$TEMP_FILE" "$f" 2>> "$LOGFILE"; then
                echo "File copied successfully to original location" >> "$LOGFILE"

                # Remove temp file
                rm "$TEMP_FILE" 2>> "$LOGFILE"
                echo "Temp file cleaned up" >> "$LOGFILE"

                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

                # Show success notifications and popups
                if [ "$HAS_RESTRICTIONS_ONLY" = true ]; then
                    osascript -e "display notification \"Restrictions removed! File processed in place.\" with title \"PDF Processing\""

                    # Only show popup for single file processing
                    if [ "$MULTIPLE_FILES" = false ]; then
                        osascript -e "display dialog \"✅ PDF Restrictions Removed\n\nFile: $(basename "$f")\n\nAll PDF restrictions have been removed using $SUCCESSFUL_PASSWORD. You can now copy, edit, and modify the document freely.\" with title \"PDF Processing Complete\" buttons {\"OK\"} default button \"OK\" with icon note"
                    fi
                else
                    osascript -e "display notification \"Decryption successful! File decrypted in place.\" with title \"PDF Processing\""

                    # Only show popup for single file processing
                    if [ "$MULTIPLE_FILES" = false ]; then
                        osascript -e "display dialog \"✅ PDF Decryption Successful\n\nFile: $(basename "$f")\n\nThe PDF has been decrypted using $SUCCESSFUL_PASSWORD and all restrictions removed.\" with title \"PDF Processing Complete\" buttons {\"OK\"} default button \"OK\" with icon note"
                    fi
                fi
            else
                echo "ERROR: Failed to copy temp file back" >> "$LOGFILE"
                echo "Temp file remains at: $TEMP_FILE" >> "$LOGFILE"
                osascript -e "display notification \"Processing successful but file is at: $TEMP_FILE\" with title \"PDF Processing\""
                FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        else
            echo "ERROR: Could not remove original file" >> "$LOGFILE"

            # Clean up temp file
            rm "$TEMP_FILE" 2>> "$LOGFILE"

            osascript -e "display notification \"Processing successful but couldn't replace original\" with title \"PDF Processing\""
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        echo "ERROR: $PROCESSING_TYPE failed with all ${#PASSWORDS[@]} password(s)" >> "$LOGFILE"
        echo "Final error output: $LAST_OUTPUT" >> "$LOGFILE"

        FAILED_COUNT=$((FAILED_COUNT + 1))

        # Show failure notifications and popups
        osascript -e "display notification \"Processing failed: All passwords tried\" with title \"PDF Processing\""

        # Only show popup for single file processing
        if [ "$MULTIPLE_FILES" = false ]; then
            # Check if it's a password error specifically
            if echo "$LAST_OUTPUT" | grep -q "invalid password"; then
                osascript -e "display dialog \"❌ PDF Processing Failed\n\nFile: $(basename "$f")\n\nError: All ${#PASSWORDS[@]} password(s) failed\n\nNone of the passwords in ~/.decrypt-pdf-action worked for this PDF. You may need to add the correct password.\n\nCheck the log file for more details:\n~/Library/Logs/decrypt-pdf-action.log\" with title \"PDF Processing Failed\" buttons {\"OK\"} default button \"OK\" with icon stop"
            else
                osascript -e "display dialog \"❌ PDF Processing Failed\n\nFile: $(basename "$f")\n\nError: $LAST_OUTPUT\n\nTried ${#PASSWORDS[@]} password(s) from ~/.decrypt-pdf-action\n\nCheck the log file for more details:\n~/Library/Logs/decrypt-pdf-action.log\" with title \"PDF Processing Failed\" buttons {\"OK\"} default button \"OK\" with icon stop"
            fi
        fi

        # Clean up temp file if it exists
        if [ -f "$TEMP_FILE" ]; then
            rm "$TEMP_FILE" 2>> "$LOGFILE"
        fi
    fi

    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))

    echo "Finished processing: $f" >> "$LOGFILE"
    echo "---" >> "$LOGFILE"
done

# Show batch summary for multiple files
if [ "$MULTIPLE_FILES" = true ]; then
    echo "=== Batch Processing Summary ===" >> "$LOGFILE"
    echo "Total files: $TOTAL_FILES" >> "$LOGFILE"
    echo "Successfully processed: $SUCCESS_COUNT" >> "$LOGFILE"
    echo "Skipped (no processing needed): $SKIP_COUNT" >> "$LOGFILE"
    echo "Failed: $FAILED_COUNT" >> "$LOGFILE"
    echo "Passwords available: ${#PASSWORDS[@]}" >> "$LOGFILE"

    # Show summary notification
    osascript -e "display notification \"Batch complete: $SUCCESS_COUNT processed, $SKIP_COUNT skipped, $FAILED_COUNT failed\" with title \"PDF Processing\""

    # Show summary dialog with View Log button
    DIALOG_RESULT=$(osascript -e "display dialog \"📊 Batch Processing Complete\n\nTotal files: $TOTAL_FILES\n✅ Successfully processed: $SUCCESS_COUNT\n⏭️ Skipped (no processing needed): $SKIP_COUNT\n❌ Failed: $FAILED_COUNT\n\nUsed ${#PASSWORDS[@]} password(s) from ~/.decrypt-pdf-action\n\nWould you like to view the detailed log file?\" with title \"PDF Batch Processing Summary\" buttons {\"View Log\", \"OK\"} default button \"OK\" with icon note" 2>/dev/null)

    # Check if user clicked "View Log"
    if echo "$DIALOG_RESULT" | grep -q "View Log"; then
        echo "User requested to view log file" >> "$LOGFILE"

        # Open the log file in the default text editor
        open "$LOGFILE"

        # Alternative: Open in Console app (better for log files)
        # open -a Console "$LOGFILE"

        # Alternative: Open in a specific app like TextEdit
        # open -a TextEdit "$LOGFILE"
    fi
fi

echo "=== Script completed - $(date) ===" >> "$LOGFILE"
echo "Log file location: $LOGFILE"