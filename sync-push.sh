#!/bin/bash
set -e
ROOT=~/Desktop/Kaizen-Home-Spa
MONO=$ROOT/kaizen-monorepo
EX=(--exclude='.git' --exclude='node_modules' --exclude='.next' --exclude='build' --exclude='.dart_tool' --exclude='.gradle' --exclude='Pods' --exclude='.vercel' --exclude='.env*' --exclude='.DS_Store')

rsync -a --delete "${EX[@]}" $ROOT/homespa_client/  $MONO/homespa_client/
rsync -a --delete "${EX[@]}" $ROOT/homespa-admin/   $MONO/homespa-admin/
rsync -a --delete "${EX[@]}" $ROOT/kaizen-website/  $MONO/kaizen-website/
rsync -a --delete "${EX[@]}" ~/kaizen_therapist/    $MONO/kaizen_therapist/

cd $MONO
git add -A
if git diff --cached --quiet; then echo "Tidak ada perubahan"; exit 0; fi
git commit -m "${1:-update $(date +%Y-%m-%d_%H:%M)}"
git push
