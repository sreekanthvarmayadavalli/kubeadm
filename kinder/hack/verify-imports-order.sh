#!/usr/bin/env bash

# Copyright 2021 The Kubernetes Authors.
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

# This script verifies that all the imports have our preferred order.
# see: https://github.com/kubernetes/kubeadm/issues/2515

# Usage: `./hack/verify-imports-order.sh "k8s.io/kubeadm" . `

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "$(dirname "$0")/utils.sh"
# cd to the root path
cd_root_path

export GO111MODULE=on
go build ./hack/orderimports/orderimports.go

# cleanup
exitHandler() (
  echo "Cleaning up..."
  rm orderimports
)
trap exitHandler EXIT

find_files() {
  find $1 -not \( \
      \( \
        -wholename './output' \
        -o -wholename './.git' \
        -o -wholename './_output' \
        -o -wholename './_gopath' \
        -o -wholename './release' \
        -o -wholename './target' \
        -o -wholename '*/third_party/*' \
        -o -wholename '*/vendor/*' \
        -o -wholename './staging/src/k8s.io/client-go/*vendor/*' \
        -o -wholename '*/bindata.go' \
        -o -wholename '*zz_generated*' \
      \) -prune \
    \) -name '*.go'
}

# orderimports exits with non-zero exit code if it finds a problem unrelated to
# formatting (e.g., a file does not parse correctly). Without "|| true" this
# would have led to no useful error message from orderimports, because the script would
# have failed before getting to the "echo" in the block below.
diff=$(find_files "$2"| xargs ./orderimports -d -p "$1" 2>&1) || true
if [[ -n "${diff}" ]]; then
  echo "${diff}" >&2
  echo >&2
  echo "Run ./hack/update-imports-order.sh" >&2
  exit 1
fi
