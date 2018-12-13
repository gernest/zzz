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

## How it works

We can use the  following directory tree

```
.
├── lib
│   ├── clap
│   │   ├── example
│   │   │   ├── comptime-clap.zig
│   │   │   └── streaming-clap.zig
│   │   ├── src
│   │   │   ├── args.zig
│   │   │   ├── comptime.zig
│   │   │   ├── index.zig
│   │   │   └── streaming.zig
│   │   ├── LICENSE
│   │   ├── README.md
│   │   ├── build.zig
│   │   └── index.zig
│   └── zson
│       ├── src
│       │   ├── main.zig
│       │   └── main_test.zig
│       ├── README.md
│       └── build.zig
├── src
│   └── main.zig
├── zig-cache
│   ├── zzz
│   └── zzz.o
├── LICENCE
├── README.md
└── build.zig

8 directories, 20 files
```

### step 1

we walk recursively on the directory tree looking for files. For every file found we calculate `sha3` of its content and record the `{sha3} {file name}` string to a buffer.

For the directory tree we have, the buffer will contain.

```
77ad59954f6e1cdc64cc4972bd73926f5108baaadcef343601c71928e3f0423f ./build.zig
9d5f2eddab041df45f662fbc662d315fe1e42292bb16b1c982675788fd06052f ./lib/clap/build.zig
1509667b2eba4514fc227fa250cbd6c226774236405a0fee5803ada622d195fd ./lib/clap/example/comptime-clap.zig
0e51454a31a17079969db74ae60b283b128badf3357dc317145688a7e711ee76 ./lib/clap/example/streaming-clap.zig
33ef6d28c9d588a846d9f424a3d94873c8a0b385cb5d86840f0d93aa59f1a303 ./lib/clap/index.zig
dd749b5f96e0b68da349f8276c18f4e004ebb3f64acf8b4e1d251a5881f2fc3b ./lib/clap/LICENSE
4201544c87f3cefd4239e17d92965951033e62371db7ee7da287fc774c4c6b91 ./lib/clap/README.md
e4f99d2bdd3dfe48a1c8b513ee98bedb3bd4b444d9ae440678ecca1a09f4694d ./lib/clap/src/args.zig
84ec5ae5c2910875b34d3f651c974adc81e54db1dd7f292c26631db70578fbd7 ./lib/clap/src/comptime.zig
a2c507b97babc03e24137133be69f89ec7a1f0a437ea5ec9123cbe2a1919499c ./lib/clap/src/index.zig
192197c20129b5721d642000bc02f928392cc05b951e24ab3f14574e5e645441 ./lib/clap/src/streaming.zig
a65e0504482b15b59bfb0e502900eaa8cb08cfa82e501ad3664741ef7f099baf ./lib/zson/build.zig
147bd3743cb3b723327f8a2b43908aa321c1c3ad375458ff14734a9e7cfbda6f ./lib/zson/README.md
b0d3614c075ae589cbfaeed95de5c56db90fdeddc655a8714ff5d68c38a51ecb ./lib/zson/src/main.zig
ab5423b355d44620195927a214dc043964b7909f832b55ee1e9080ef8f87752b ./lib/zson/src/main_test.zig
cda681eb2161409b72418fac9f816a45584206dbc120ab77919977530a4cb51e ./LICENCE
cdea72e722afbc6cdfd52929d78ed9746b62c02b13bd289a3a56471e84ab4e54 ./README.md
82b37b8376e268a453238861c23e0df5f47a8954982bf002c17ca61deef4d642 ./src/main.zig
```

### step 2

we create `sha3` string of the buffer from step 2 above which will give `ebaf2e4194c2afdeb6b72ea734c3af3bf9c971250ba70e0335db739850e1d524`


### step 3

we use `base64` to encode the result from step 2 , we get `668uQZTCr962ty6nNMOvO/nJcSULpw4DNdtzmFDh1SQ=`


## Notes
In real usage, we only care about the source files so, `src` directory of zig projects. This tool doesn't make any assumptions.