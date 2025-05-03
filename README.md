## how to build for produciton

```sh
zig build -Doptimize=ReleaseSafe
docker build . --tag <tag> --progress=plain
```
