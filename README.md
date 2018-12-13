# zzz

Tool for hashing directories and verifying directory hashes. This was created
to be used on zig projects.

## files and folders that are ignored

- [x] any file/directory that begins with `.`
- [x] `zig-cache` found at the root of the directory.
- [ ] anything else you want ignored?

# Installation

Clone this repo and run `zig build`

# Usage

creating the hash
```
$ ./zig-cache/zzz --sum src/
qvyFo3ZHeVj3daZ/XRbya+nCeuUjaB0ReGC2pFknGq4=
```

verifying the hash against the directory
```
$ ./zig-cache/zzz --verify --hash qvyFo3ZHeVj3daZ/XRbya+nCeuUjaB0ReGC2pFknGq4=  src/
pass
```