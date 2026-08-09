#!/bin/bash

# Jacob deployment — see deploy-to-jacob-vms.sh for configuration.
# This wrapper keeps the legacy script name working in docs and muscle memory.
exec "$(dirname "$0")/deploy-to-jacob-vms.sh" "$@"
