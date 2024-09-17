# Using Terraform to build Cross-Account Service Integrations with AWS PrivateLink
This project demonstrates how to use Terraform to Cross-Account Service Integrations with AWS PrivateLink

## Prerequisites
Before you begin, ensure you have the following:

- 2 AWS accounts
- Terraform installed locally
- AWS CLI installed and configured with appropriate access credentials profiles for the 2 AWS accounts

## Architecture
![Diagram](cross-account-privatelink-cross-account.webp)

---

## Project Structure
```bash
|- service_producer/
|- cross_account_service_consumer/
```
---
## Getting Started

Clone this repository:

   ```bash
   git clone https://github.com/FonNkwenti/tf-cross-account-privateLink.git
   ```


### Set up the PrivateLink Endpoint Service in the Service Producer's account
1. Navigate to the service-provider directory:
   ```bash
   cd service_producer/
   ```
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review and modify `variables.tf` if required
4. Create a `terraform.tfvars` file in the root directory and pass in values for the variables.
   ```bash
      region               = "eu-west-1"
      account_id           = <<aws_account_id_for_service_producer>>
      cross_account_id     = <<aws_account_id_for_cross_account_service_consumer>>
      environment          = "dev"
      project_name         = "tf-cross-account-privateLink"
      service_name         = "privateLink-service"
      cost_center          = "237"
   ```
5. Apply the Terraform configure:
   ```bash
   terraform apply --auto-approve
   ```
6. Copy the value of the `privateLink_service_name`. 
   ```bash
   Apply complete! Resources: 27 added, 0 changed, 0 destroyed.

   Outputs:

   privateLink_service_name = "com.amazonaws.vpce.eu-west-1.vpce-svc-058a2bf106bf77968"

   ```
7.   


### Set up the VPC Interface Endpoint in the Service Consumer's account
1. Navigate to the cross-account-service-consumer directory:
   ```bash
   cd cross-account-service-consumer/
   ```
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review and modify `variables.tf` if required
4. Create a `terraform.tfvars` file in the root directory and pass in values for the variables. Make sure you update the value of the `privateLink_service_name` copied from the Terraform output of the Endpoint service deployment.
   ```bash
      region                     = "eu-west-1"
      account_id                 = <<aws_account_id_for_service_producer>>
      cross_account_id           = <<aws_account_id_for_cross_account_service_consumer>>
      privateLink_service_name   = "com.amazonaws.vpce.eu-west-1.vpce-svc-0aa398ea0d6f8741a"
      environment                = "dev"
      project_name               = "tf-cross-account-privateLink"
      service_name               = "privateLink-service"
      cost_center                = "237"
   ```
5. Apply the Terraform configure:
   ```bash
   terraform apply --auto-approve
   ```
6. Copy the value of the `session_manager_link` from the Terraform output. Paste it in your broswer to open up an SSM Session Manager session to the EC2 instance in the cross account service consumer's account. 
   ```bash
   session_manager_link = "https://console.aws.amazon.com/systems-manager/session-manager/i-079d5d8918970a57a"

   ```
7. Copy the value of the `interface_endpoint_dns_name` from the Terraform output. Use `curl` to verify if you can access the service.   
   ```bash
   interface_endpoint_dns_name = "vpce-02623c0267accd034-0p68ymlz.vpce-svc-058a2bf106bf77968.eu-west-1.vpce.amazonaws.com"

   ```
---

## Testing
1. Paste the session manager link to the consumers EC2 instance in your web browser.
2. Test connectivity to the Endpoint service via the interface VPC endpoint
   ```bash
      sh-4.2$ curl http://vpce-026bc4f220976bfe7-uvx9sx52.vpce-svc-0f8de98ff3b50bd01.eu-west-1.vpce.amazonaws.com<html>
      <head>
         <title>Instance Information</title>
      </head>
      <body>
         <h1>Instance Information</h1>
         <p><strong>Instance Name:</strong> i-0cbd519ffe7583c5d</p>
         <p><strong>Private IP:</strong> 10.255.10.40</p>
         <p><strong>Public IP:</strong> No public IP assigned</p>
         <p><strong>Availability Zone:</strong> eu-west-1a</p>
         <p><strong>Region:</strong> eu-west-1</p>
      </body>
      </html>
   ```

## Clean up

### Remove all resources created by Terraform in the Service Consumer's account
1. Navigate to the cross-account-service-consumer directory:
   ```bash
   cd cross-account-service-consumer/
   ```
2. Destroy all Terraform resources:
   ```bash
   terraform destroy --auto-apply
   ```
---
### Remove all resources created by Terraform in the Service Producers's account
1. Navigate to the service-producer directory:
   ```bash
   cd service-producer/
   ```
2. Destroy all Terraform resources:
   ```bash
   terraform destroy --auto-apply
   ```
---


<!-- ## Step-by-step Turial -->


## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
