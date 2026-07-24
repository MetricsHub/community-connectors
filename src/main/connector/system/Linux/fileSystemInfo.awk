# Parse the output of:
# - GNU df from coreutils: df -B1 --output=source,target,fstype,used,avail,size
#   Used when the installed coreutils version supports --output, as on modern
#   Debian, Ubuntu, Fedora, RHEL 7+, CentOS 7+, Rocky Linux, AlmaLinux, and SUSE.
# - POSIX-style fallback: df -P -T -k
#   Used on older systems where GNU --output is unavailable, including older
#   Red Hat-like systems such as Oracle Linux 6, RHEL 6, and CentOS 6.
#   -P requests the portable one-line layout; -T is the Linux extension used for filesystem type.
#
# Output columns:
# id;target;type;used;available;used%;available%;reserved;reserved%
#
# The id is source(target). The Linux connector maps this same value to
# system.device, preserving the original connector output format.
BEGIN {
    OFS = ";"
}

# Return true for unsigned integer fields. This keeps header rows and malformed
# df lines from reaching the arithmetic below.
function isnum(v) {
    return v ~ /^[0-9]+$/
}

# Keep capacity-bearing filesystems and skip kernel/control/temporary mounts.
# This avoids relying on source paths such as /dev/*, so meaningful filesystems
# like NFS, CIFS, ZFS, Ceph, or other non-/dev sources can still be collected.
function isMeaningfulFs(type) {
    type = tolower(type)
    return type !~ /^(autofs|binfmt_misc|bpf|cgroup|cgroup2|configfs|debugfs|devpts|devtmpfs|efivarfs|fusectl|hugetlbfs|mqueue|nsfs|overlay|proc|pstore|ramfs|rootfs|securityfs|squashfs|sysfs|tmpfs|tracefs)$/
}

# GNU df branch for systems whose coreutils df supports --output.
# $1=source, $2=target, $3=type, $4=used bytes, $5=available bytes, $6=size bytes.
NR > 1 && isMeaningfulFs($3) && isnum($4) && isnum($5) && isnum($6) && $6 > 0 {
    print $1 "(" $2 ")", $2, $3, $4, $5, $4 / $6, $5 / $6, $6 - ($4 + $5), ($6 - ($4 + $5)) / $6
}

# POSIX-style df fallback branch for systems where GNU --output is unavailable.
# Older Red Hat-like systems, including Oracle Linux 6/RHEL 6/CentOS 6, land here.
# -P gives a predictable portable layout; -T adds the filesystem type on Linux.
# $1=source, $2=type, $3=size KiB, $4=used KiB, $5=available KiB, $7=target.
# Byte metrics are converted from KiB by multiplying by 1024.
NR > 1 && isMeaningfulFs($2) && NF >= 7 && isnum($3) && isnum($4) && isnum($5) && $3 > 0 {
    print $1 "(" $7 ")", $7, $2, $4 * 1024, $5 * 1024, $4 / $3, $5 / $3, ($3 - ($4 + $5)) * 1024, ($3 - ($4 + $5)) / $3
}
