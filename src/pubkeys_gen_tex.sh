#!/bin/bash

# Copyright 2017 Justin Gombos
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

pubkey_added=false

for key_fn in keys/*
do
    extension=${key_fn##*.}
    acct_id=$(basename ${key_fn##*_} .$extension)

    touch work/pubkeys_files.tex
    
    # Create a LaTeX command for any new public keys found in ./keys/
    if ! grep -q '\newcommand{\pgp'"$acct_id" work/pubkeys_files.tex
    then
        pubkey_added=true
        
        case "$key_fn" in
            *.asc|*.pgp)
                printf %s '
\newcommand{\pgp'"$acct_id"'}{\attachfile[%
  color=0 0 0,%
  appearance=true,%
  print=false,%
  mimetype=application/pgp,%
  subject={PGP public key},%
  description={PGP public key for '"$acct_id"'\dn}%
  ]{../'"$key_fn"'}}
' >> work/pubkeys_files.tex
                ;;
            *.pem)
                printf %s '
\newcommand{\cert'"$acct_id"'}{\attachfile[%
  color=0 0 0,%
  appearance=true,%
  print=false,%
  mimetype=application/pkcs12,%
  subject={S/MIME certificate},%
  description={S/MIME certificate for '"$acct_id"'\dn}%
  ]{../'"$key_fn"'}}
' >> work/pubkeys_files.tex
                ;;
        esac
    fi
done

if ! "$pubkey_added"
then
    printf '%s\n' 'No keys were added because none were found in ./keys/.  Building requires at least one public key to exist which conforms to the naming convention ./keys/pubkey_<unique id>.(asc|pem|pgp), where <unique id> can be anything.'
    exit 1
fi
