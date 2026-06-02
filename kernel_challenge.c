#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    // Escalate to root to read flag
    setuid(0);
    setgid(0);
    
    char cve[50];
    printf("====================================================================\n");
    printf("            KERNEL VERSION ENUMERATION CHALLENGE                    \n");
    printf("====================================================================\n");
    printf("Enumerate the OS/kernel version using standard commands (e.g. uname).\n");
    printf("Identify the famous 2021 OverlayFS Local Privilege Escalation CVE\n");
    printf("affecting Ubuntu 18.04 LTS.\n\n");
    printf("Enter the CVE ID (Format: CVE-YYYY-NNNN): ");
    
    if (scanf("%49s", cve) != 1) {
        return 1;
    }
    
    // Check if correct
    if (strcasecmp(cve, "CVE-2021-3493") == 0) {
        printf("\n[+] Correct! Here is your flag:\n");
        system("cat /root/flag14.txt");
    } else {
        printf("\n[-] Incorrect CVE ID. Hint: Look for OverlayFS exploit released in 2021 for Ubuntu Bionic.\n");
    }
    return 0;
}
