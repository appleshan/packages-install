#!/bin/bash

# --- Configuration ---
PACKAGES_FILE="/home/alecshan/projects/private/packages-install/packages.sh"
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# --- Logging Functions ---
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_cn() { echo -e "${PURPLE}[CN-REPO]${NC} $1"; }

# --- Check for dependencies ---
check_deps() {
  if ! command -v pacman &> /dev/null; then
    log_error "pacman not found."
    exit 1
  fi
}

# --- Repository Checkers ---
get_sync_repo() {
  # Support both English (Repository) and Chinese (软件库)
  yay -Si "$1" 2>/dev/null | grep -E "^(Repository|软件库)" | awk -F': ' '{print $2}' | xargs
}

# --- Main Logic ---
main() {
  check_deps

  log_info "Reading current package lists from ${PACKAGES_FILE}..."

  extract_array() {
    local name="$1"
    awk "/export ${name}=\\(/, /\\)/ { if (\$0 !~ /export/ && \$0 !~ /\\)/) print \$0 }" "${PACKAGES_FILE}" | \
    sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' | \
    grep -v '^$'
  }

  mapfile -t PKG_OLD < <(extract_array "PKG")
  mapfile -t AUR_OLD < <(extract_array "AUR")
  mapfile -t CN_OLD < <(extract_array "archlinuxcn")

  # Combine all packages into one unique pool
  ALL_PACKAGES=($(printf "%s\n" "${PKG_OLD[@]}" "${AUR_OLD[@]}" "${CN_OLD[@]}" | sort -u))

  if [ ${#ALL_PACKAGES[@]} -eq 0 ]; then
    log_error "No packages found. Aborting."
    exit 1
  fi

  declare -a NEW_PKG=()
  declare -a NEW_AUR=()
  declare -a NEW_CN=()

  log_info "Re-classifying ${#ALL_PACKAGES[@]} packages (Priority: CN > AUR > PKG)..."

  for pkg in "${ALL_PACKAGES[@]}"; do
    pkg=$(echo "$pkg" | xargs)
    [ -z "$pkg" ] && continue

    echo -ne "Processing: ${pkg} \033[K\r"

    # Retry logic: Try up to 3 times if REPO comes back empty
    MAX_RETRIES=3
    RETRY_COUNT=0
    REPO=""

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
      REPO=$(get_sync_repo "$pkg")
      if [ -n "$REPO" ]; then
        break
      fi
      
      RETRY_COUNT=$((RETRY_COUNT + 1))
      if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        log_warning "Retrying ${pkg} due to empty result ($RETRY_COUNT/$MAX_RETRIES)..."
        sleep 1
      fi
    done

    # 1. Priority: Check archlinuxcn
    if [ "$REPO" == "archlinuxcn" ]; then
      # NEW: Check if this archlinuxcn package also exists in AUR
      if yay -Si --aur "$pkg" &>/dev/null; then
        NEW_AUR+=("$pkg")
        log_warning "$pkg -> AUR (available in both archlinuxcn and AUR)"
      else
        NEW_CN+=("$pkg")
        log_cn "$pkg -> archlinuxcn"
      fi
    
    # 2. Priority: Check AUR
    elif [ "$REPO" == "aur" ]; then
      NEW_AUR+=("$pkg")
      log_warning "$pkg -> AUR"
    
    # 3. Priority: Official repositories
    elif [ -n "$REPO" ]; then
      NEW_PKG+=("$pkg")
      log_success "$pkg -> official ($REPO)"
      
    # 4. Final Fallback (After all retries failed)
    else
      NEW_PKG+=("$pkg")
      log_error "$pkg -> Unknown (Keeping in PKG after $MAX_RETRIES attempts)"
    fi
  done

  echo -e "\nClassification finished."

  log_info "Updating ${PACKAGES_FILE}..."

  {
    echo "#!/bin/bash"
    echo ""
    echo "export PKG=("
    printf "  %s\n" "${NEW_PKG[@]}" | sort -u
    echo ")"
    echo ""
    echo "export AUR=("
    printf "  %s\n" "${NEW_AUR[@]}" | sort -u
    echo ")"
    echo ""
    echo "export archlinuxcn=("
    printf "  %s\n" "${NEW_CN[@]}" | sort -u
    echo ")"
  } > "${PACKAGES_FILE}"

  log_success "Task Complete!"
  echo -e "Summary: CN:${#NEW_CN[@]} | AUR:${#NEW_AUR[@]} | Official:${#NEW_PKG[@]}"
}

main