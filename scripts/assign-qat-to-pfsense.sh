#!/bin/bash
# Convenience wrapper to move QAT VFs from OPNsense VM (900) back to pfSense VM (100)

set -e

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

FROM_VMID=${FROM_VMID:-900}
TO_VMID=${TO_VMID:-100}

"$ROOT_DIR/move-qat-vfs.sh" "$FROM_VMID" "$TO_VMID"
