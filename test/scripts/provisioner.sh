#!/bin/bash
if ! [ -f /tmp/results/hab_artifact.tar.gz ]; then
  echo "ERROR: No hab_artifact.tar.gz found, did you run 'hab pkg build .'?"
  exit 1
fi

export HAB_LICENSE="accept-no-persist"
export CHEF_LICENSE="accept-no-persist"

# Load variables for use in this script
source /tmp/results/last_build.env

# Extract Habitat artifact (contains `hab` binary and all keys/packages)
sudo tar xf /tmp/results/hab_artifact.tar.gz -C /

# Create `hab` user and group if they do not exist
if grep "^hab:" /etc/passwd > /dev/null; then
  echo "Hab user exists, skipping user creation"
else
  # NOTE: `useradd` also creates a group by default
  sudo useradd hab && true
fi

echo "Determine pkg_prefix for $pkg_artifact"
pkg_prefix=$(find "/hab/pkgs/$pkg_origin/$pkg_name" -maxdepth 2 -mindepth 2 | sort | tail -n 1)
echo "Found: $pkg_prefix"

# Execute Chef Infra client inside the package
echo "Running chef-client in $pkg_origin/$pkg_name"
cd "$pkg_prefix" || exit 1
sudo -E /hab/bin/hab pkg exec "$pkg_origin/$pkg_name" chef-client -z -c "$pkg_prefix/config/bootstrap-config.rb"


#### INSPEC AUDIT ####
# # Execute Chef Inspec client inside the package
# rm -f /inspec_pass

# echo "Running inspec from inspec_artifact.tar.gz"
# sudo tar xf /tmp/results/inspec_artifact.tar.gz -C /

# echo "Determine pkg_prefix for $pkg_artifact"
# pkg_prefix=$(find "/hab/pkgs/jvdemo/inspec-cis-centos7-demo" -maxdepth 2 -mindepth 2 | sort | tail -n 1)
# echo "Found: $pkg_prefix"

# # Execute InSpec inside the package (ignoring control failures)
# echo "Running Chef InSpec in jvdemo/inspec-cis-centos7-demo"
# cd "$pkg_prefix" || exit 1

# sudo -E /hab/bin/hab pkg exec "jvdemo/inspec-cis-centos7-demo" \
#                                 inspec exec "$pkg_prefix/dist"

# # Capture exit code of Chef InSpec command
# exit_code=$?

# # Exit 0 if non-zero exit is related to control failures
# if [ $exit_code -eq 0 ]; then
#   touch /tmp/inspec_pass
# else
#   echo "InSpec exited $exit_code, see https://www.inspec.io/docs/reference/cli/#exec"
# fi