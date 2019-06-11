## zippyshare.sh (Random Algorithm)[https://github.com/JuniYadi/zippyshare/issues/1]

### bash script for downloading zippyshare files

##### Download single file from zippyshare

```bash
./zippyshare.sh url
```

##### Batch-download files from URL list (url-list.txt must contain one zippyshare.com url per line)

```bash
./zippyshare.sh url-list.txt
```

##### Example:

```bash
./zippyshare.sh https://www3.zippyshare.com/v/CDCi2wVT/file.html
```
### Requirements: `coreutils`, `curl`, `grep`, `sed`, `bc`
