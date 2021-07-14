# tf-nc
A learning project to study CI/CI by building the cloud office for a small organisation.

## The process includes:
- creation of two EC2 instances: terraform-ci and docker-compose;
- generation of private key;
- adding security groups to instances (22; 8080; 80 and 443 ports).
- creation S3 bucket at the docker-compose instance;
- upgrading python; installing, Pygithub, Ansible, Java JDK, Jenkins at terraform-ci instance; 
- installing docker-compose at docker-compose instance;
- exporting Ansible variables to terraform-ci instance;
- exporting SSH keys to GitHub and instances, cloning this GIT repo on the terraform-ci instance;
- creation of webhook at GitHub;
- initialising Jenkins; importing scripts with predefined jobs: job-manage-nc-apps, job-manage-nc-users;
- starting dockers with applications with the help of docker-compose;
- initialising Nextcloud web app, creation of services;
- installing OnlyOffice Community Document Server (optional); 
- performing first run of jobs to update users and apps (optional);
- providing output with URLs of Jenkins and Web application.

##ToDo:
- Get rid of hard code.
- Place maximum provisioning from terraform to ansible playbooks.
- Transform sole ansible playbooks to the structured ansible roles.
- Get rid of docker-compose, but use ansible.
- To make configuration OS dependant where possible.
- To collect all variables in one configuration file.
- To rethink completely the authentication mechanisms and managing credentials, add aws_vault where possible.
- To add cleaning orphan keys in GitHub.
- Add own domain name and enable Let’s Encrypt certificate.
- To think about adding other targets apart of AWS.

##Disclaimer:
This is an educational project solely intended to present an example how the CI/CD logic may be implemented. While preparing this project I have intentionally used different solutions to show how it is possible to achieve the objective. 

For the learning goals the setup and provisioning data are stored in one GitHub repository, the S3 bucket is not persistent.

The project is recommended to use **only** for learning purposes.

There’s a lot to improve and clean the code.

Anybody may use, modify and share this code freely.


