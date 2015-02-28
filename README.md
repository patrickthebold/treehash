# treehash
sha256 treehash used for amazon glacier

To compile:
`gcc treehash.c -lcrypto -o treehash`
There will be some warnings (at least on os x) but that's just because sha256 isn't considered
secure, but you are probably using this for amazon glacier and not cryptographic purposes.

To run:
`cat file1 file2 | ./treehash`

If you want to install, put the treehash file somewhere in your `$PATH`, perhaps `/usr/local/bin`.
