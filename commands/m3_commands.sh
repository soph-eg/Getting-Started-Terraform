# In this module, we are simply trying to get the configuration deployed.
# First we'll copy our file from the base_web_app to a working directory (cp)
mkdir globo_web_app
cp ./base_web_app/main.tf ./globo_web_app/main.tf

# Now we can work with the main.tf file in globo_web_app
cd globo_web_app

# Now we can initialize the Terraform working directory.
# This will download the AWS provider and set up the backend.
terraform init

## We need AWS credentials to plan and apply the configuration.
# You can set them in the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# or use the AWS CLI to configure them.
# If you have the AWS CLI installed, you can run:
aws configure

# If you have existing credentials, you can create a new profile for this project:
aws configure --profile globo_web_app

# Set the AWS profile to use for this Terraform project.
export AWS_PROFILE=globo_web_app # bash
$env:AWS_PROFILE="globo_web_app" # PowerShell

# Now we can run the plan command to see what Terraform will do.
terraform plan -out m3.tfplan

# Check out the plan to see what resources will be created.
terraform show m3.tfplan

# If the plan looks good, we can apply it.
# This will create the resources defined in the main.tf file.

# Try apply without any options first to see the interactive prompt.
terraform apply

# Now use the plan file to apply the changes.
# This is the preferred way to apply changes as it ensures the plan is used.
terraform apply m3.tfplan

# Go to the Console and get the Public DNS hostname for the EC2 instance
# and browse to port 80.

# If you are done, you can tear things down to save $$
terraform destroy