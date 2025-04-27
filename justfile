# List available commands
default:
    just --list

# Setup rule to prepare Lambda and apply Terraform
setup:
    cd lambda_function && pnpm install
    cd lambda_function && zip -q -r ../lambda_function.zip . || echo "Error occurred during zip operation"
    terraform init
    terraform apply -auto-approve

# Teardown rule to destroy all resources
teardown:
    test -f lambda_function.zip || touch lambda_function.zip
    terraform destroy -auto-approve
    rm -f lambda_function.zip
