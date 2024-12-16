#!/bin/env bash

# MIT License
#
# Copyright (c) [year] [fullname]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

declare source_path="./nac_iac"
declare -a names=()
declare -a paths=()

function find_dcs_names () {
    printf 'Looking for files...\r'
    local int=0
    for _name in $(find "$source_path" -type f -name "*.y*ml"); do
        if [[ "$(yq '.kind' -r "$_name")" == "DeploymentConfig" ]]; then
            int=$(( int + 1 ))
            #            dcs+=("$_name")
            names+=("$(basename "$_name")")
            paths+=("$(dirname "$_name")")
            printf "Looking for files...(%s)\r" "$int"
        fi
    done
    printf "\n\n"
}

function create_dest_folder () {
    if [[ "${#paths[@]}" -gt 0 ]]; then
        printf 'Creating destination paths...'
        for path in $(echo "${paths[@]}" | tr ' ' '\n' | sort -u); do
            local new_path=""
            new_path="${path//DeploymentConfig/Deployment}"
            if [[ ! -d "$new_path" ]]; then
                mkdir -p "$new_path"
            fi
            unset new_path
        done
        printf 'Done!\n\n'
    else
        printf 'No paths available, exiting!\n\n'
        exit 1
    fi
}

function convert () {
    for iter in $( seq 0 $(( ${#paths[@]} - 1 ))); do
        local src="${paths[$iter]}/${names[$iter]}"
        local dest="${paths[$iter]//DeploymentConfig/Deployment}/${names[$iter]}"

        printf 'Converting %b into deployment\n' "$src"

        yq '.spec.template.metadata.labels' "$src" | sed 's|deploymentconfig|deployment|g' > labels.yaml
        yq 'del(.metadata.annotations)
        | del(.metadata.labels.*)
        | del(.spec.triggers)
        | del(.spec.selector.*)
        | del(.spec.template.metadata.labels.*)
        | del(.spec.test)
        | del(.status)
        | .metadata.labels = load("labels.yaml")
        | .spec.selector.matchLabels = load("labels.yaml")
        | .spec.template.metadata.labels = load("labels.yaml")
        | .apiVersion = "apps/v1"
        | .kind = "Deployment"
        | .spec.strategy.type = "RollingUpdate"' "$src" > "$dest"
        rm labels.yaml
    done
    printf 'Conversion completed\n\n'
}

function test () {

    printf 'Running tests\n'
    for iter in $( seq 0 $(( ${#paths[@]} - 1 ))); do
        local file="${paths[$iter]//DeploymentConfig/Deployment}/${names[$iter]}"
        oc apply -f "$file" --dry-run=server
    done
    printf 'Tests completed\n\n'
}

function main () {
    find_dcs_names
    create_dest_folder
    #edit_template
    convert
    test
    printf "All done!"
}

main
