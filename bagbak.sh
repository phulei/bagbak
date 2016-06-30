#!/bin/bash

# This script backs up data bags from chef into an encrypted tarball.
# to restore them, decrypt the file, and you should be able to
#  knife data bag from file <blah> 
# in a loop

test_pass() {

    printf "[\e[1m\033[32mPASS\033[0m]\n"

}

test_fail() {

    printf "[\e[1m\033[31mFAIL\033[0m]\n"
    echo "$errmsg"
    exit 1

}

test_knife() {

    echo -n "Knife user check: "
    knife_return=$( knife node list > /dev/null 2>&1 ; echo $? )
    if [ "$knife_return" = "0" ] ;then
        test_pass
    else
        errmsg="This script requires a valid knife user"
        test_fail
    fi

}

test_gpg() {

    echo -n "GPG installed check: "
    gpg_return=$( which gpg > /dev/null 2>&1 ; echo $? )
    if [ "$gpg_return" = "0" ] ;then
        test_pass
    else
        errmsg="This script requires gpg to be installed"
        test_fail
    fi
}

test_gpg_dir() {

    echo -n "GPG directory check: "
    mkdir ~/.gnupg/ > /dev/null 2>&1
    gpg_return=$( touch ~/.gnupg/testfile > /dev/null 2>&1 ; echo $? )
    if [ "$gpg_return" = "0" ] ;then
        test_pass
    else
        errmsg="If ~/.gnupg/ is not writeable, gpg complains"
        test_fail
    fi
}


dump_bags() {

    # handle directories
    echo 
    echo "## Dumping data bags to files ##"
    rundir=$(pwd)
    timestamp=$(date +%F_%_H-%M-%S)
    dumpdir="databag-backup-$timestamp"
    dir="$rundir/$dumpdir" 
    mkdir -p $dir
    cd $dir

    # dump data bags
    for bag in $(knife data bag list) ;do
        mkdir $dir/$bag
        cd $dir/$bag
        for subbag in $(knife data bag show $bag) ;do
            knife data bag show $bag $subbag -F j > ${subbag}.json 2>/dev/null
            echo -n "."
        done
    done
    echo

}

tar_bags() {

    echo 
    echo "## Archiving bags ##"
    tarfile="${dumpdir}.tar"
    gzfile="${tarfile}.gz"
    cd $rundir
    tar -cf $tarfile $dumpdir
    gzip -9 $tarfile
    rm -rf $dumpdir

}

encrypt_bags() {

    echo 
    echo "## Encrypting archive ##" ;echo
    cd $rundir
    echo "Here are some strong passwords if you need one:"
    pwgen -sy 40 -n 10
    gpg --armor --symmetric --cipher-algo AES256 $gzfile
    rm -f $gzfile
    echo
    echo "Done. Encrypted file is ${gzfile}.asc (ascii armored, AES256)."
    echo

}

#main

#we require a valid knife user
test_knife
#we require pgp to be installed
test_gpg
test_gpg_dir

# do the needful
dump_bags
tar_bags
encrypt_bags





