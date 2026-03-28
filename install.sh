#!/bin/bash
# GNOME Template Manager - Static & Reliable Version
# Dynamically detects system language and provides a native "New Document" menu.

## 1. Automatic Name Detection (Dynamic Localized Names)
get_localized_name() {
    local gettext_id="$1"   # Standard GNOME msgid
    local default_en="$2"   # Default English name
    local translated
    translated=$(gettext -d nautilus "$gettext_id" 2>/dev/null)
    # If gettext found a translation, use it, otherwise use English default
    [[ -n "$translated" && "$translated" != "$gettext_id" ]] && echo "$translated" || echo "$default_en"
}

# Define filenames dynamically
NAME_EMPTY=$(get_localized_name "Empty Document" "Empty Document")
NAME_TEXT=$(get_localized_name "Text File" "Text File.txt")
NAME_SHELL=$(get_localized_name "Shell Script" "Shell Script.sh")
NAME_MD=$(get_localized_name "Markdown File" "Markdown File.md")
NAME_HTML=$(get_localized_name "HTML File" "HTML File.html")
NAME_CALC=$(get_localized_name "Spreadsheet" "Spreadsheet.ods")
NAME_PRESENT=$(get_localized_name "Presentation" "Presentation.odp")
NAME_WRITER=$(get_localized_name "Document" "Document.odt")

# Define template contents map
declare -A template_contents
template_contents=(
  ["$NAME_EMPTY"]=""
  ["$NAME_TEXT"]=""
  ["$NAME_SHELL"]="#!/bin/bash\n"
  ["$NAME_MD"]="# "
  ["$NAME_HTML"]="<!DOCTYPE html>\n<html>\n<head>\n\t<title></title>\n</head>\n<body>\n\t\n</body>\n</html>"
  ["$NAME_CALC"]=""
  ["$NAME_PRESENT"]=""
  ["$NAME_WRITER"]=""
)

# Detect Templates path
T_DIR=$(xdg-user-dir TEMPLATES 2>/dev/null || echo "$HOME/Templates")
S_DIR="$HOME/.local/share/nautilus/scripts"

## 2. Dynamic LibreOffice Detection
HAS_LIBREOFFICE=false
command -v libreoffice >/dev/null && HAS_LIBREOFFICE=true
command -v localc >/dev/null && HAS_CALC=true || HAS_CALC=$HAS_LIBREOFFICE
command -v lowriter >/dev/null && HAS_WRITER=true || HAS_WRITER=$HAS_LIBREOFFICE
command -v loimpress >/dev/null && HAS_IMPRESS=true || HAS_IMPRESS=$HAS_LIBREOFFICE

# Interactive Menu
echo "=========================================================="
echo "          GNOME TEMPLATE MANAGER                        "
echo "=========================================================="
echo "This script installs static templates into your native "
echo "GNOME 'New Document' right-click menu."
echo ""
echo "Select items to install:"
echo "  1) $NAME_EMPTY"
echo "  2) $NAME_TEXT"
echo "  3) $NAME_SHELL"
echo "  4) $NAME_MD"
echo "  5) $NAME_HTML"
$HAS_CALC && echo "  6) LibreOffice Calc"
$HAS_IMPRESS && echo "  7) LibreOffice Impress"
$HAS_WRITER && echo "  8) LibreOffice Writer"
echo "  9) Install ALL"
echo "  10) Uninstall ALL"
echo "  0) Exit"
echo ""

read -p "Choice(s): " choices < /dev/tty
read -a choices_arr <<< "$choices"

if [[ " ${choices_arr[@]} " =~ " 0 " ]]; then exit 0; fi

# Arrays for summary
installed_items=()
removed_items=()

# Uninstall Logic
if [[ " ${choices_arr[@]} " =~ " 10 " ]]; then
    echo "Uninstalling templates..."
    # Cleanup standard templates
    for p in "$NAME_EMPTY" "$NAME_TEXT" "$NAME_SHELL" "$NAME_MD" "$NAME_HTML" "$NAME_CALC" "$NAME_PRESENT" "$NAME_WRITER"; do
        if [ -f "$T_DIR/$p" ]; then
            rm "$T_DIR/$p"
            removed_items+=("$p")
        fi
    done
    # Cleanup interactive scripts too (from previous versions if any)
    [ -d "$S_DIR" ] && find "$S_DIR" -name "*Create New*" -delete 2>/dev/null
    pkill -9 nautilus 2>/dev/null || true
    echo "Summary: Uninstall complete. Removed ${#removed_items[@]} items."
    for item in "${removed_items[@]}"; do echo "  - Removed: $item"; done
    exit 0
fi

# Multi-Purpose Installation func
install_static_template() {
    local t_name="$1"
    local t_content="$2"
    
    mkdir -p "$T_DIR"
    printf "$t_content" > "$T_DIR/$t_name"
    [[ "$t_name" == *.sh ]] && chmod +x "$T_DIR/$t_name"
    installed_items+=("$t_name")
}

# Main Execution
echo "Installing selected templates..."

is_all=false
[[ " ${choices_arr[@]} " =~ " 9 " ]] && is_all=true

if $is_all || [[ " ${choices_arr[@]} " =~ " 1 " ]]; then install_static_template "$NAME_EMPTY" ""; fi
if $is_all || [[ " ${choices_arr[@]} " =~ " 2 " ]]; then install_static_template "$NAME_TEXT" ""; fi
if $is_all || [[ " ${choices_arr[@]} " =~ " 3 " ]]; then install_static_template "$NAME_SHELL" "#!/bin/bash\n"; fi
if $is_all || [[ " ${choices_arr[@]} " =~ " 4 " ]]; then install_static_template "$NAME_MD" "# "; fi
if $is_all || [[ " ${choices_arr[@]} " =~ " 5 " ]]; then install_static_template "$NAME_HTML" "<!DOCTYPE html>\n"; fi
if $HAS_CALC && { $is_all || [[ " ${choices_arr[@]} " =~ " 6 " ]]; }; then install_static_template "$NAME_CALC" ""; fi
if $HAS_IMPRESS && { $is_all || [[ " ${choices_arr[@]} " =~ " 7 " ]]; }; then install_static_template "$NAME_PRESENT" ""; fi
if $HAS_WRITER && { $is_all || [[ " ${choices_arr[@]} " =~ " 8 " ]]; }; then install_static_template "$NAME_WRITER" ""; fi

# Hard-refresh Nautilus
pkill -9 nautilus 2>/dev/null || true
echo ""
echo "=========================================================="
echo "               INSTALLATION SUMMARY                       "
echo "=========================================================="
if [ ${#installed_items[@]} -gt 0 ]; then
    echo "SUCCESSFULLY INSTALLED:"
    for item in "${installed_items[@]}"; do echo "  - $item"; done
    echo ""
    echo "HOW TO USE: Right-click -> 'New Document' "
else
    echo "No changes were made."
fi
echo "=========================================================="