<!-- run nodejs nginx and postgresql app locally -->


1. install postgresql / nodejs
2. fork repo
    - install npm packages

3. init postgresql

```
psql -U postgres

CREATE DATABASE url_shortener;

\c url_shortener;

CREATE TABLE urls (
    id SERIAL PRIMARY KEY,
    short_path TEXT UNIQUE NOT NULL,
    original_url TEXT NOT NULL
);
```

4. test url

```
curl -X POST http://localhost:3000/shorten -H "Content-Type: application/json" -d '{"originalUrl": "https://example.com"}'
```

```
curl -i http://localhost:3000/go/yak.whale.dog
```

5. SUCCESS - APP RUNNING LOCALLY

6. close app and run `npm test` to test app

<!-- TIME FOR DEPLOYMENT on aws with ec2 rds and alb -->

1. login to aws (sign in with root user email), create an account, and enable billing (maybe free trial)

2. look up aws rds
https://aws.amazon.com/rds/

3. create postgresql database (free tier)
    - give it a name url-shortener
    - username url_shortener
    - autogenerate password

    - instance config - db.t4g.micro (2vcps 1GiB ram network 2085mbps)
    - 20GiB allocated storage ssd

    - connect to an ec2 compute resource

4. pause, and create ec2 instance
    -  Amazon Linux 2023 (Recommended)
    AMI Name: Amazon Linux 2023 (AL2023) – Free Tier Eligible

    Why?
    ✅ Optimized for AWS
    ✅ Lightweight and secure
    ✅ Pre-installed with AWS CLI
    ✅ Long-term support from AWS
    ✅ Faster boot times compared to Ubuntu

    - name: url-shortener

    - don't change architecture
    - instance type - t2.micro (free tier eligible)
    - key pairs, or ssh keys allow us to securely access our ec2 instance
        A Key Pair consists of:

        Public Key (.pem) → Stored on your EC2 instance.
        Private Key (.pem) → Stored on your local machine. You need this to connect via SSH.
        AWS will never store your private key, so if you lose it, you won’t be able to access your instance via SSH (unless you manually add a new key).
        - create a key pair
            - Select Key Pair Name (e.g., url_shortener_key).
            Key Type: RSA (default)
            Key Format:
            PEM → Use this for Linux/macOS SSH.
            PPK → Use this for Windows PuTTY.
            Click "Create Key Pair" → AWS will automatically download the .pem file.
            save it in a separate directory specific to your device
            Store this file securely! If you lose it, you won’t be able to SSH into your instance.


            - B. Using the Key Pair to SSH into Your EC2 Instance
                Once your EC2 instance is running, you can connect to it using SSH and bash command:
                ```ssh -i /path/to/your-key.pem ec2-user@your-instance-ip```
                Breaking it down:

                ssh → Secure Shell command to access your server.
                -i /path/to/your-key.pem → Specifies the private key you downloaded.
                ec2-user@your-instance-ip → Logs in as ec2-user (Amazon Linux) or ubuntu (Ubuntu).
                your-instance-ip → Replace with your EC2 Public IPv4 address


        - network settings
            - create security group
                - allow ssh access - my ip address
            How to Fix This Later?
                Option 1: Update Security Group to Your New IP
                Go to AWS EC2 Dashboard → Security Groups.
                Find the Security Group attached to your EC2 instance.
                Click on the Inbound Rules tab.
                Find the SSH rule (port 22).
                Edit the rule and update "Source" to your new IP address (My IP).
                Click Save.
                ✅ Now you can SSH from your new network!


        - storage settings
            - settings are fine
                Size	8 GiB	The total storage capacity of your instance (8 Gibibytes, ≈8.6GB)
                Volume Type	gp3	General Purpose SSD, optimized for performance & cost
                IOPS	3000	Input/Output Operations Per Second, affecting read/write speed
                Encryption	Not enabled	Data is not encrypted at rest -  Recommended for production environments, especially if handling user data, logs, or database backups.
            - You can increase storage later (without stopping the instance).

            Should You Add Another Volume?
                If your app stores large files (e.g., user uploads, logs, backups), consider adding an extra volume.
                Example:
                Root volume (OS & App): 8-16 GiB (gp3)
                Additional volume (Data storage): 50-100 GiB (gp3/gp2)


        - advanced settings - negatory

        - launch instance

5. back to rds, and refresh ec2 check - select our new ec2 instance url_shortener
    - VPC - this removes your ability to select vpc - Adding an EC2 compute resource automatically selects the VPC, DB subnet group, and public access settings for this database.
        - A VPC (Virtual Private Cloud) is AWS’s isolated network where your resources (EC2, RDS, etc.) run.

    - db subnet group - automatic setup
    - public access, absolutely not
        - You can still access your RDS database if public access is disabled, but only by first SSH-ing into your EC2 instance and then connecting to the database from within the private network.
            - Option 1: SSH Into EC2, Then Connect to RDS
                1️⃣ SSH into your EC2 instance:
                ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-ip
                2️⃣ Use psql from inside EC2 to connect to RDS:

                psql -h your-rds-endpoint -U your_rds_username -d your_database_name
                3️⃣ Enter your database password when prompted. ✅



    - connectivity
        vpc security group firewall (choose existing) - Amazon RDS will add a new VPC security group rds-ec2-1 to allow connectivity with your compute resource.

    - certificate (default)

    - database authentication - password auth (default) is fine

    - monitoring (explained in the option) - default options

    - create database


6. find database credentials

     1️⃣ Find Your Database Username (RDS Console)
        Even though you can't retrieve the password, you can still find the database username:

        Go to AWS Console → RDS.
        Click on your database instance.
        In the "Configuration" tab, look for "Master username".
        This is your database login username.
        ✅ You now have your database username, but you still need a password reset.

    3️⃣ 2️⃣ Reset Your Database Password (Since You Can’t Retrieve It)
        Since AWS doesn’t let you recover the auto-generated password, the only option is to reset it manually.

        Reset Password via AWS Console
        Go to AWS Console → RDS.
        Click on your database instance.
        Click Modify (top right).
        Scroll down to "Settings" → Enter a new Master password.
        Click Continue, then Apply Changes.
        Choose "Apply Immediately" if you want the change to take effect now (otherwise, it applies during the next maintenance window).

    Find Your RDS Endpoint (-h your-rds-endpoint)
        This is your database hostname (not an IP address).

        📌 Steps to find it:

        Go to AWS Console → RDS.
        Click on your RDS instance.
        In the Connectivity & Security section, look for "Endpoint".
        It will look something like this:
        Copy
        Edit
        mydatabase.xxxxxx.us-east-1.rds.amazonaws.com
        Use this as your your-rds-endpoint.

   


7. test the login - can we access database via ssh into our ec2 instance (reminder to update security groups)

    ping ec2-54-252-239-140.ap-southeast-2.compute.amazonaws.com    


    Find Your EC2 Public IP in the AWS Console
    Go to AWS Console → EC2 → Instances.
    Find your EC2 instance in the list.
    Look for "Public IPv4 address" in the instance details.
    Example: 52.14.123.45 (this is your public IP).
    Your SSH login command will be:

    ssh -i /path/to/your-key.pem ec2-user@52.14.123.45
    -i is to identify a file
    ssh -i /Users/jamesmcarthur/downloads/url_shortener_key.pem ec2-user@54.252.239.140


    Replace /path/to/your-key.pem with the actual path to your private key.
    Replace 52.14.123.45 with your actual EC2 public IP.

    tighten permissions
        chmod 400 /Users/jamesmcarthur/downloads/url_shortener_key.pem

        ls -l /Users/jamesmcarthur/downloads/url_shortener_key.pem

    ✅ Amazon Linux 2023 does not include postgresql by default.
    ✅ Fix it by installing postgresql15:
        sudo dnf install -y postgresql15
        <!-- sudo yum install -y postgresql -->
        psql --version

    Both yum and dnf are package managers used in Red Hat-based Linux distributions (including Amazon Linux, CentOS, and RHEL).

    your final command
        psql -h url-shortener.c1mi0g482he4.ap-southeast-2.rds.amazonaws.com -U url_shortener -d postgres

    password eMGExPnD8m7IfS1g3xR2

    we have no database, so we can login and then create the database (we login using the default postgres one)
    Once logged in, run all the sql commands at the top to create ur database, and then you can login later directly to our database with this command
        psql -h url-shortener.c1mi0g482he4.ap-southeast-2.rds.amazonaws.com -U url_shortener -d url-shortener


6.   simple deploy (nginx reverse proxy) - 

    fill out the start.sh file with your github credentials

    use scp to copy across the `start.sh` file
    `scp -i /User/to/your-key.pem start.sh ec2-user@your-ec2-public-ip:/home/ec2-user/`
        Replace /path/to/your-key.pem with your EC2 key file path.
        Replace your-ec2-public-ip with your instance’s public IP.

        ✅ Now, start.sh is uploaded to the home directory (/home/ec2-user/) on your EC2 instance.

    Replace curl-minimal With Full curl
    1️⃣ Use dnf swap to Replace Packages Safely
        `sudo dnf swap curl-minimal curl -y`
        Removes curl-minimal and libcurl-minimal.
        Installs the full curl package without breaking dependencies.

    Manually Create /var/www/
        `sudo mkdir -p /var/www/`


    Grant Permissions for /var/www/
        Amazon Linux restricts write access to /var/www/, which is usually reserved for web servers.
        To allow cloning into /var/www/myapp, follow these steps:

        1️⃣ Change Ownership of /var/www/
            `sudo chown -R ec2-user:ec2-user /var/www/`

        Changes the ownership of /var/www/ to your current user (ec2-user).
        Allows git clone to write files into /var/www/myapp.

    2️⃣ Set Correct Permissions
        `sudo chmod -R 755 /var/www/`
        🔹 What this does:
            755 means:
            Owner (ec2-user): read, write, execute
            Group: read, execute
            Others: read, execute

        The chmod command changes file permissions in Linux. It determines who can read, write, or execute files and directories.


    ✅ Run the script on your EC2 instance:

        ```chmod +x start.sh
        ./start.sh```

    this will give u an http url to access the backend

    test pm2 
        `pm2 list`

    test nginx
        `sudo nginx -t`

    view last 100 lines of logs in pm2
    `pm2 logs --lines 100`


    View error logs in pm2
    `cat ~/.pm2/logs/myapp-error.log`

    will need to update ec2 security group
        Check Security Group Rules
            Go to AWS Console → EC2 → Security Groups.
            Find the security group attached to your EC2 instance.
            Click Inbound Rules → Edit inbound rules.
            Add these rules (if missing):
            Type	Protocol	Port Range	Source
            HTTP	TCP	80	0.0.0.0/0 (or your IP)
            HTTPS	TCP	443	0.0.0.0/0 (or your IP)
            ✅ Now Nginx should be reachable from the internet!



        now copy over the .env file after completing it with your env variables and keys
        use scp to copy across the `.env` file
    `scp -i /User/to/your-key.pem .env ec2-user@your-ec2-public-ip:/home/ec2-user/`
    and then move it
            `sudo mv /home/ec2-user/.env /var/www/myapp/`


    test url

        ` curl -X POST http://localhost:3000/shorten -H "Content-Type: application/json" -d '{"originalUrl": "https://example.com"}'`

        `curl -i http://localhost:3000/go/xylophone.banana.banana`

        ```
        curl -X POST http://3.25.201.127/shorten -H "Content-Type: application/json" -d '{"originalUrl": "https://example.com"}'
        ```

        ```
        curl -i http://3.25.201.127/go/apple.vulture.monkey
        ```


7. Set up an AWS Application Load Balancer (ALB) to distribute traffic to your EC2 instance.
    Why Use an ALB?
    ✅ Handles incoming traffic and distributes it across multiple EC2 instances.
    ✅ Provides automatic failover if an instance crashes.
    ✅ Supports HTTPS (with an SSL certificate via AWS ACM).
    ✅ Improves security with security groups & WAF integration.

    Create an Application Load Balancer
        Go to AWS Console → EC2 → Load Balancers.
        Click "Create Load Balancer".
        Select "Application Load Balancer".

    Configure ALB Settings
        Name:
        Example: aws-full-course-ec2-alb
        Scheme:
        Internet-facing (if users access it from the internet).
        Internal (if only accessed within AWS VPC).
        IP Address Type:
        Choose IPv4.
        VPC:
        Select the VPC where your EC2 instance is running.
        Availability Zones:
        Select at least two subnets for high availability.

    Configure Security Group
        create a new security group

        Security Groups for ALB & EC2
            You need two security groups:

            ALB Security Group

            Allows public traffic (HTTP & HTTPS).
            Only allows forwarding to EC2.
            EC2 Security Group

            Restricts inbound traffic to only accept traffic from ALB.
            Allows outbound requests (if needed for API calls, etc.).
            ✅ Step 1: Create an ALB Security Group
            Go to EC2 → Security Groups → Click "Create Security Group".
            Name: alb-security-group
            Inbound Rules:
            Allow HTTP (port 80) → 0.0.0.0/0 (Public access)
            Allow HTTPS (port 443) → 0.0.0.0/0 (For SSL)
            Outbound Rules: Leave default (Allow all traffic).
            Click "Create Security Group".
            ✅ Step 2: Modify EC2 Security Group to Allow Only ALB Traffic
            Find the security group attached to your EC2 instance (delete the existing).
            Edit inbound rules:
            Allow HTTP (port 3000) from the ALB security group (not 0.0.0.0/0 for security reasons).

                Type	Protocol	Port Range	Source
                Custom TCP	TCP	3000	sg-1234567890abcdef (Your ALB’s Security Group)
            Save changes.


    listeners and routing
    Configure Listeners & Routing
        You need two listeners:

        HTTP (port 80) → Redirect to HTTPS.
        HTTPS (port 443) → Forward to your EC2 instance via a target group.

        ✅ Step 3: Create the HTTP Listener (Redirect to HTTPS)
        In the ALB creation page, under Listeners and Routing, find the HTTP:80 listener.
        
        click to create a target group
            - type = instances
            - target group name = url-shortener-alb-80

        all the rest is default, click next

        register the target, 
        select our ec2 instance
        click -> include as pending below

        finally, click -> create target group

        come back to listener http:80 and click refresh, and then select the new target group
        
        ✅ Step 4: Create the HTTPS Listener (if u have ssl)
        Click "Add Listener".

        Protocol: HTTPS

        Port: 443

        SSL Certificate:

        If you have an existing certificate in AWS Certificate Manager (ACM), select it.
        If not, request a free SSL certificate in ACM.
        Forward to Target Group:

        Click Create Target Group.
        Name: my-app-tg
        Type: Instance
        Protocol: HTTP
        Port: 3000
        VPC: Choose the same VPC as your EC2.
        Health Check Path: /
        Click Next.
        Register Targets: Select your EC2 instance, include as pending and create target group.
        Save the listener configuration.

    secure listener settings (this is only relevant if u have ssl cert, which we don't atm so we will leave blank)

    create load balancer & wait for provisioning

    Find Your ALB’s Public DNS
        To get the ALB URL:

        Go to AWS EC2 Console → AWS Load Balancers.
        Find your ALB in the list.
        Look for the "DNS name" field.
        Copy the URL → It should look something like this:
        ```http://my-app-alb-123456789.ap-southeast-1.elb.amazonaws.com
        ```


    NOW YOU CAN RUN ALL YOUR COMMANDS USING THIS NEW URL

# EXTRA STEPS
 9. automate rds backups into s3 with aws lambda functions and cloudwatch
10. ci/cd pipeline with github actions / s3 and aws codedeploy
11. set up aws cloud watch for monitoring and optimizing
12. set up auto-scaling for ec2 instances
13. aws javascript sdk







