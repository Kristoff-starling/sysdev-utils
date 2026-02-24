#!/bin/bash

set -ex

curl -sS https://webi.sh/k9s | sh
source ~/.config/envman/PATH.env

set +ex
