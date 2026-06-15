# Anylinuxfs Reference Guide: Mounting Linux Filesystems on macOS

**Homepage / Repository:** https://github.com/nohajc/anylinuxfs

---

## 1. Installation & Trust

Run the following commands in the macOS Terminal to install anylinuxfs via Homebrew.
The `trust` command is required to bypass Homebrew's third-party safety guardrails.

```bash
$ brew tap nohajc/anylinuxfs
$ brew trust nohajc/anylinuxfs
$ brew install anylinuxfs
```

> **Note:** If using a VPN, disconnect it during installation and the first run
> to prevent DNS/network resolution errors within the background microVM.

There is also a GUI frontend available:

```bash
$ brew install fenio/tap/anylinuxfs-gui
```

---

## 2. Scanning & Listing Connected Devices

Plug in your USB/external drive. When macOS alerts that the drive is unreadable,
click **Ignore** (do not eject or initialize). Then scan for devices:

```bash
$ sudo anylinuxfs list
```

Review the output to determine if your partition uses a raw filesystem (xfs, ext4)
or an LVM container. The `IDENTIFIER` column shows the exact string to use when mounting.

---

## 3. Mounting

First, create the mount point directory if it does not already exist:

```bash
$ mkdir ~/usb-storage
```

### A. Plain Filesystem Partition (xfs, ext4, etc.)

```bash
$ sudo anylinuxfs mount disk4s1 ~/usb-storage
```

### B. LVM Logical Volume

Use the `IDENTIFIER` value shown in `anylinuxfs list` output:

```bash
$ sudo anylinuxfs mount lvm:<VolumeGroup>:<diskXsY>:<LogicalVolume> ~/usb-storage
```

For a VG that spans multiple physical volumes, include each disk in the identifier:

```bash
$ sudo anylinuxfs mount lvm:<VolumeGroup>:<diskXsY>:<diskXsZ>:<LogicalVolume> ~/usb-storage
```

> **Note:** `sudo` is required for mount — anylinuxfs needs raw disk access.
> The `~` expands correctly even under sudo, so `~/usb-storage` resolves to
> `/Users/<yourusername>/usb-storage`.

---

## 5. Accessing Files

Once mounted, files are accessible at `~/usb-storage/`.

**In Finder:** Press `Cmd + Shift + H` to open your Home directory, then open `usb-storage`.

**In Terminal:**
```bash
$ ls ~/usb-storage/
```

### Permission Denied Errors

Linux home directories are typically owned by a Linux UID (e.g., 1000) with `700`
permissions. macOS does not recognize these UIDs, so you may see permission errors:

```
ls: /Users/sbradley/usb-storage/home/sbradley/: Permission denied
```

Use `sudo` to access as root, which bypasses file permission checks:

```bash
$ sudo ls ~/usb-storage/home/sbradley/
$ sudo cp -r ~/usb-storage/home/sbradley/ ~/recovered-files/
```

---

## 6. Unmounting & Ejecting

Always unmount before unplugging to prevent filesystem corruption.

**Step 1 — Unmount the filesystem:**
```bash
$ umount ~/usb-storage
# or if permission denied:
$ sudo umount ~/usb-storage
```

**Step 2 — Eject the disk:**
```bash
$ diskutil eject /dev/disk4
```

Or right-click the drive in Finder and choose **Eject**.

---

## 7. Notes & Limitations

- **swap** partitions cannot be mounted — skip them.
- **VDO volumes** (`type: vdo`) require a special kernel module not available in the
  Alpine microVM used by anylinuxfs — these will not mount.
- **LVM volumes that were removed with `vgremove`** will not be enumerable. The PV
  appears as `LVM2_member` but no VG or LVs are shown. The raw_locn pointer in the
  LVM metadata area is zeroed by vgremove. Data blocks are not erased but recovery
  requires restoring the VG metadata from the ring buffer.
- anylinuxfs uses a lightweight Alpine Linux microVM (libkrun) internally. Running
  `sudo anylinuxfs list` produces verbose VM debug output — this is normal.

---

## 8. Real-World Example

### Disk with multi-PV LVM volume group (4 TB drive)

```bash
$ sudo anylinuxfs list
```

```
/dev/disk4 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *4.0 TB     disk4
   2:                        xfs                         1.1 GB     disk4s2
   3:                LVM2_member                         570.7 GB   disk4s3
   4:                LVM2_member                         3.4 TB     disk4s4

lvm:rhws_vg (volume group):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:                LVM2_scheme                        +4.0 TB     rhws_vg
                                 Physical Store disk4s3
                                                disk4s4
   1:                       swap                         33.8 GB    rhws_vg:disk4s3:swap
   2:                        xfs                         536.9 GB   rhws_vg:disk4s3:root
   3:                        xfs datastore               600.0 GB   rhws_vg:disk4s4:datastore
   4:                        xfs redhat_data             1.5 TB     rhws_vg:disk4s4:redhat_data
```

This disk has:
- A standalone XFS partition (`disk4s2`)
- An LVM volume group `rhws_vg` spanning two physical volumes (`disk4s3` and `disk4s4`)
- Four logical volumes — `swap` (skip), `root`, `datastore`, and `redhat_data`

### Mount each volume

```bash
# Standalone XFS partition
$ sudo anylinuxfs mount disk4s2 ~/usb-storage
$ sudo ls ~/usb-storage/
$ umount ~/usb-storage

# LVM root volume (on disk4s3)
$ sudo anylinuxfs mount lvm:rhws_vg:disk4s3:root ~/usb-storage
$ sudo ls ~/usb-storage/home/sbradley/
$ umount ~/usb-storage

# LVM datastore volume (on disk4s4)
$ sudo anylinuxfs mount lvm:rhws_vg:disk4s4:datastore ~/usb-storage
$ sudo ls ~/usb-storage/
$ umount ~/usb-storage

# LVM redhat_data volume (on disk4s4)
$ sudo anylinuxfs mount lvm:rhws_vg:disk4s4:redhat_data ~/usb-storage
$ sudo ls ~/usb-storage/
$ umount ~/usb-storage

# swap — skip, not mountable
```

### Eject when done

```bash
$ diskutil eject /dev/disk4
```
