#include <stdlib.h>
#include <unistd.h>

int main() {
    // Set real and effective UID/GID to root to preserve privileges
    setuid(0);
    setgid(0);
    
    // Call command without absolute path, enabling PATH hijacking
    system("service apache2 status");
    return 0;
}
