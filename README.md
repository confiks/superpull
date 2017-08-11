# Superpull

This script will `git clone` all repositories from a Github user or organization, and keep them updated with `git pull --ff-only`. It is intended to be run in a folder that contains exlusively the repositories from that user or organisation. 

* Specific repositories can be ignored by added their names as lines to a `.superpull_ignore` file. 
* Repositories will only be updated if `.git/FETCH_HEAD` is older than three days, and the `pushed_at` time of the Github API result is newer than `.git/FETCH_HEAD`. See `stale_repository_criterium`.

#### Usage
```
Usage: ./superpull.rb [user|org] [account name]
```

#### Example
```
~/sources $ mkdir confiks_repositories
~/sources $ cd confiks_repositories

~/sources/confiks_repositories $ superpull user confiks
Doing request for: https://api.github.com/users/confiks/repos?per_page=100&page=1

Found 2 repositories through Github API. Ignored 0 through .superpull_ignore.
There are 2 new repositories to clone: idfaplanner, ipfs-dc.

Doing clone for: git@github.com:confiks/idfaplanner.git
Cloning into 'idfaplanner'...
remote: Counting objects: 7, done.
remote: Total 7 (delta 0), reused 0 (delta 0), pack-reused 7
Receiving objects: 100% (7/7), done.

Doing clone for: git@github.com:confiks/ipfs-dc.git
Cloning into 'ipfs-dc'...
remote: Counting objects: 245, done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 245 (delta 4), reused 3 (delta 3), pack-reused 240
Receiving objects: 100% (245/245), 70.86 KiB | 35.00 KiB/s, done.
Resolving deltas: 100% (112/112), done.

Found 0 git subdirectories that are stale.
```
