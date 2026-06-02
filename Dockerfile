FROM ubuntu:18.04

# Avoid prompt during installations
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, compilers, tools, SSH, and docker client
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    vim \
    net-tools \
    gcc \
    libcap2-bin \
    docker.io \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Download and install vulnerable sudo version (CVE-2019-14287)
RUN curl -o /tmp/sudo.deb http://archive.ubuntu.com/ubuntu/pool/main/s/sudo/sudo_1.8.21p2-3ubuntu1_amd64.deb && \
    dpkg -i /tmp/sudo.deb && \
    rm /tmp/sudo.deb && \
    apt-mark hold sudo

# Configure SSH daemon
RUN mkdir /var/run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Add user 'student' with password 'student123'
RUN useradd -m -s /bin/bash student && \
    echo 'student:student123' | chpasswd

# ----------------- ESCALATION PATHS SETUP -----------------

# [4] Password Reuse: Set root password same as student
RUN echo 'root:student123' | chpasswd

# [8] Sensitive Files Exposure: Generate root SSH key and save a backup in /var/backups
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa && \
    mkdir -p /var/backups && \
    cp /root/.ssh/id_rsa /var/backups/root_ssh.bak && \
    chmod 644 /var/backups/root_ssh.bak

# Create all 15 Flag Files
RUN mkdir -p /root && \
    echo "FLAG{weak_file_perms_bashrc_success}" > /root/flag1.txt && \
    echo "FLAG{suid_binary_abuse_success}" > /root/flag2.txt && \
    echo "FLAG{misconfigured_sudo_rights_success}" > /root/flag3.txt && \
    echo "FLAG{password_reuse_success}" > /root/flag4.txt && \
    echo "FLAG{world_writable_cron_success}" > /root/flag5.txt && \
    echo "FLAG{path_hijacking_success}" > /root/flag6.txt && \
    echo "FLAG{writable_service_exec_success}" > /root/flag7.txt && \
    echo "FLAG{sensitive_files_exposure_success}" > /root/flag8.txt && \
    echo "FLAG{writable_etc_passwd_success}" > /root/flag9.txt && \
    echo "FLAG{cron_path_injection_success}" > /root/flag10.txt && \
    echo "FLAG{nfs_misconfiguration_success}" > /root/flag11.txt && \
    echo "FLAG{capabilities_abuse_success}" > /root/flag12.txt && \
    echo "FLAG{env_variable_abuse_success}" > /root/flag13.txt && \
    echo "FLAG{kernel_version_enum_success}" > /root/flag14.txt && \
    echo "FLAG{docker_group_priv_esc_success}" > /root/flag15.txt && \
    chmod 600 /root/flag*.txt && \
    chown root:root /root/flag*.txt

# [1] Weak File Permissions (Writable Files): Make global bashrc writable
RUN chmod 666 /etc/bash.bashrc

# [2] SUID Binary Abuse: Set SUID on find
RUN chmod u+s /usr/bin/find

# [5] World Writable Cron Jobs: Create world-writable cleanup script executed by root cron
RUN echo '#!/bin/bash\n' > /usr/local/bin/cleanup.sh && \
    chmod 777 /usr/local/bin/cleanup.sh && \
    echo "* * * * * root /usr/local/bin/cleanup.sh" >> /etc/crontab

# [6] PATH Hijacking: Copy C source, compile SUID binary, and remove source
COPY status_check.c /tmp/status_check.c
RUN gcc /tmp/status_check.c -o /usr/local/bin/status_check && \
    chmod u+s /usr/local/bin/status_check && \
    rm /tmp/status_check.c

# [7] Writable Service Executables: Writable custom service binary and mock systemctl restart wrapper
RUN echo '#!/bin/bash\nsleep 3600' > /usr/local/bin/custom-daemon && \
    chmod 777 /usr/local/bin/custom-daemon
RUN echo '[Unit]\nDescription=Vulnerable Custom Service\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/custom-daemon\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/vuln-service.service
COPY systemctl_mock.sh /tmp/systemctl_mock.sh
RUN mv /bin/systemctl /bin/systemctl.real && \
    cp /tmp/systemctl_mock.sh /bin/systemctl && \
    chmod +x /bin/systemctl && \
    rm /tmp/systemctl_mock.sh

# [9] Writable /etc/passwd: Make /etc/passwd writable
RUN chmod 666 /etc/passwd

# [10] Cron PATH Injection: Add cron job with student's home first in PATH
RUN sed -i 's|PATH=.*|PATH=/home/student:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin|g' /etc/crontab && \
    echo "* * * * * root cron_cleanup" >> /etc/crontab

# [11] NFS Misconfiguration: Export /srv/nfs and run simulated NFS auto-SUID daemon
RUN mkdir -p /srv/nfs && chmod 777 /srv/nfs && \
    echo "/srv/nfs *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports && \
    echo '#!/bin/bash\nif [ -f /srv/nfs/nfs_exploit ]; then chown root:root /srv/nfs/nfs_exploit && chmod u+s /srv/nfs/nfs_exploit; fi' > /usr/local/bin/nfs_sim.sh && \
    chmod +x /usr/local/bin/nfs_sim.sh && \
    echo "* * * * * root /usr/local/bin/nfs_sim.sh" >> /etc/crontab

# [12] Capabilities Abuse: Copy python3 and assign setuid capability
RUN cp /usr/bin/python3 /usr/bin/python3-cap && \
    setcap cap_setuid+ep /usr/bin/python3-cap

# [14] Kernel Version Enumeration (No Exploit): Compile the interactive challenge
COPY kernel_challenge.c /tmp/kernel_challenge.c
RUN gcc /tmp/kernel_challenge.c -o /usr/local/bin/kernel_challenge && \
    chmod u+s /usr/local/bin/kernel_challenge && \
    rm /tmp/kernel_challenge.c
RUN echo "System Kernel: Linux vulnerable-ubuntu 4.15.0-20-generic #21-Ubuntu SMP" > /home/student/kernel_info.txt && \
    chmod 644 /home/student/kernel_info.txt && \
    chown student:student /home/student/kernel_info.txt

# Sudo Permissions Setup (including [3] Sudo Rights & [13] Env Variable Abuse)
RUN echo "student ALL=(ALL, !root) NOPASSWD: ALL" > /etc/sudoers.d/student && \
    echo "student ALL=(root) NOPASSWD: /usr/bin/awk" >> /etc/sudoers.d/student && \
    echo "student ALL=(root) NOPASSWD: /bin/systemctl restart vuln-service.service" >> /etc/sudoers.d/student && \
    echo "Defaults env_keep += \"LD_PRELOAD\"" >> /etc/sudoers.d/student && \
    chmod 0440 /etc/sudoers.d/student

# Add startup entrypoint script to dynamically configure mapped docker socket GID
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SSH port
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
