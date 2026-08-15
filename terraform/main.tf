#############################################
# main.tf
#
# Intentionally thin. Every resource lives directly in the .tf file
# named for its concern (vpc.tf, security-groups.tf, compute.tf,
# database.tf, monitoring.tf) — flat, no `module` blocks. See
# docs/design-decisions.md for why.
#
# Terraform doesn't care which file a resource is declared in within
# the same directory; this file exists as the conventional entry
# point / place for anything that doesn't obviously belong to one
# tier (currently: nothing). provider/version config lives in
# providers.tf, not here.
#############################################