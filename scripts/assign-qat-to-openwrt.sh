#!/bin/bash
# Move QAT VFs from current holder (default: OPNsense VM 900) to OpenWrt VM (910)

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

FROM_VMID=${FROM_VMID:-900}
TO_VMID=${TO_VMID:-910}

"$ROOT_DIR/move-qat-vfs.sh" "$FROM_VMID" "$TO_VMID"
