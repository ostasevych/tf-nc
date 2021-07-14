# tf-nc
Building the cloud office for a small organisation.

The process includes:
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
