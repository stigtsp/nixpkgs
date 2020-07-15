#!/bin/sh
mkdir -p buildPerlLog
for i in $(cat perlPackages); do 
	echo "$i"
	nix-build -A perl532Packages.$i > buildPerlLog/$i.log 2>&1 || (mv buildPerlLog/$i.log buildPerlLog/$i.FAILED)
done

