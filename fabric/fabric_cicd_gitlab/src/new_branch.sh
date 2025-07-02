#!/bin/bash
git checkout -q $2
git pull -q origin $2
git checkout -q -b $1 --no-track HEAD
git update-index --assume-unchanged .gitignore
echo  >> .gitignore
echo "item-config.json" >> .gitignore
git update-index --assume-unchanged $(git ls-files "**/item-config.json")
git update-index --assume-unchanged ./config/.env
