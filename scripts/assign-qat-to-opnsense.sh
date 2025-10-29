#!/bin/bash
# Convenience wrapper to move QAT VFs from pfSense VM (100) to OPNsense VM (900)

set -e

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

FROM_VMID=${FROM_VMID:-100}
TO_VMID=${TO_VMID:-900}

"$ROOT_DIR/move-qat-vfs.sh" "$FROM_VMID" "$TO_VMID"
