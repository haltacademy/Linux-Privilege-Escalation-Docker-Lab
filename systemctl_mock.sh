#!/bin/bash
if [ "$1" = "restart" ] && [ "$2" = "vuln-service.service" ]; then
    echo "Stopping vuln-service.service..."
    echo "Starting vuln-service.service..."
    # Execute the custom daemon as root in the background
    /usr/local/bin/custom-daemon &
    exit 0
else
    # Fallback to the real systemctl
    if [ -f /bin/systemctl.real ]; then
        exec /bin/systemctl.real "$@"
    else
        echo "System has not been booted with systemd as init system (PID 1). Can't operate."
        exit 1
    fi
fi
