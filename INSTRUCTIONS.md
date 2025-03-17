# Running the Node.js, Nginx, and PostgreSQL App Locally  

Follow these steps to set up and run the URL shortener application locally.  

### 1. Install Dependencies  
Ensure you have the following installed on your system:  
- **PostgreSQL** (for the database)  
- **Node.js** (for running the application)  

### 2. Clone the Repository and Install Packages  
Fork the repository and install the required dependencies:  

```sh
git clone https://github.com/jamezmca/aws-full-course.git
cd aws-full-course
npm install
```

### 3. Initialize PostgreSQL  
Start PostgreSQL and create the database:  

```sh
psql -U postgres
```

Then, run the following SQL commands:  

```sql
CREATE DATABASE url_shortener;

\c url_shortener;

CREATE TABLE urls (
    id SERIAL PRIMARY KEY,
    short_path TEXT UNIQUE NOT NULL,
    original_url TEXT NOT NULL
);
```

### 4. Test the URL Shortener  

To shorten a URL:  

```sh
curl -X POST http://localhost:3000/shorten \
     -H "Content-Type: application/json" \
     -d '{"originalUrl": "https://example.com"}'
```

To retrieve a shortened URL:  

```sh
curl -i http://localhost:3000/go/yak.whale.dog
```

### 5. Success!  
If the responses return correctly, the app is now running locally.  

### 6. Run Tests  
Stop the application and run tests using:  

```sh
npm test
```

---

# Deploying the URL Shortener on AWS (EC2, RDS, ALB)  

Follow these steps to deploy the application on AWS using **EC2 (compute), RDS (database), and ALB (load balancing).**  

### 1. Sign in to AWS  
- Log in to **AWS Management Console** using your **root user email** or create an account if you don’t have one.  
- Ensure **billing is enabled** (you may qualify for a **free trial**).  

### 2. Set Up Amazon RDS (PostgreSQL)  
Amazon **Relational Database Service (RDS)** will host our PostgreSQL database. Learn more about RDS [here](https://aws.amazon.com/rds/).  

#### Steps to Create the PostgreSQL Database:  
1. **Go to AWS RDS** and select **Create database**.  
2. **Choose PostgreSQL** as the database engine.  
3. **Select the Free Tier** configuration.  
4. Configure the database settings:  
   - **Database name:** `url-shortener`  
   - **Master username:** `url_shortener`  
   - **Password:** (Autogenerate and store securely)  
5. **Instance Configuration:**  
   - Instance type: **db.t4g.micro** (2 vCPUs, 1 GiB RAM, 2085 Mbps network)  
   - Storage: **20 GiB allocated SSD**  
6. **Connectivity:**  
   - Ensure the database **allows connections** from your EC2 instance.  

---

Next, we will **set up an EC2 instance** and connect it to this database.  

---


# 4. Create an EC2 Instance (Amazon Linux 2023)  

Next, we'll set up an **EC2 instance** to run our Node.js application.  

## Step 1: Launch an EC2 Instance  

1. **Go to the AWS EC2 Dashboard** and click **Launch Instance**.  
2. **Select Amazon Machine Image (AMI):**  
   - Choose **Amazon Linux 2023 (AL2023) – Free Tier Eligible**  
   - This is **optimized for AWS**, **lightweight**, **secure**, and **pre-installed with AWS CLI**.  
   - It has **long-term support** and **faster boot times** compared to Ubuntu.  
3. **Instance Name:**  
   - Name your instance: **url-shortener**  
4. **Instance Type:**  
   - Select **t2.micro** (Free Tier eligible).  
5. **Architecture:**  
   - Leave as **default**.  

---

## Step 2: Create a Key Pair for SSH Access  

- **What is a Key Pair?**  
  - **Public Key (.pem):** Stored on your EC2 instance.  
  - **Private Key (.pem):** Stored on your local machine. Needed for SSH access.  
  - **Important:** AWS **does not store your private key**, so if you lose it, you **cannot SSH into your instance** unless you manually add a new key.  

### Steps to Create a Key Pair:  

1. Click **Create a Key Pair**.  
2. Set a **Key Pair Name** (e.g., `url_shortener_key`).  
3. Select **RSA (default)** as the **Key Type**.  
4. Choose **Key Format**:  
   - **PEM** → For Linux/macOS SSH.  
   - **PPK** → For Windows PuTTY.  
5. Click **Create Key Pair**, and AWS will **automatically download** the `.pem` file.  
6. **Store it securely!** Save it in a separate directory for easy access.  

### SSH into Your EC2 Instance  

Once your EC2 instance is running, connect to it using SSH:  

```sh
ssh -i /path/to/your-key.pem ec2-user@your-instance-ip
```

**Breaking it down:**  
- `ssh` → Secure Shell command to access your server.  
- `-i /path/to/your-key.pem` → Specifies the private key for authentication.  
- `ec2-user@your-instance-ip` → Logs in as `ec2-user` (for Amazon Linux) or `ubuntu` (for Ubuntu).  
- **Replace** `your-instance-ip` with your **EC2 Public IPv4 address**.  

---

## Step 3: Configure Network & Security  

### Security Group Settings  
- **Create a new Security Group** to control access.  
- **Allow SSH access from your IP only** (for security).  

### Updating Security Group if Your IP Changes  
If your IP changes, update the security group:  
1. Go to **AWS EC2 Dashboard → Security Groups**.  
2. Find the **Security Group** attached to your EC2 instance.  
3. Click on the **Inbound Rules** tab.  
4. Find the **SSH rule (port 22)**.  
5. Edit the rule and update the **Source** to **My IP**.  
6. Click **Save** ✅  

---

## Step 4: Storage Settings  

- **Default settings are fine** for now:  
  - **Size:** `8 GiB` (≈8.6GB)  
  - **Volume Type:** `gp3` (General Purpose SSD)  
  - **IOPS:** `3000` (affects read/write speed)  
  - **Encryption:** ❌ Not enabled (Consider enabling for production environments).  
- **Storage can be increased later** without stopping the instance.  

### Should You Add Another Volume?  
If your app stores **large files** (e.g., user uploads, logs, backups), consider **adding an extra volume**:  
- **Root volume (OS & App):** `8-16 GiB (gp3)`  
- **Additional volume (Data storage):** `50-100 GiB (gp3/gp2)`  

---

## Step 5: Advanced Settings (Skip)  

No changes are needed here.  

---

## Step 6: Launch the EC2 Instance  

Click **Launch Instance**, and AWS will set it up! 🚀  

---

# 5. Link RDS to EC2 & Finalize Database Setup  

Now that our EC2 instance is running, we need to **link it to our RDS database** and configure its network settings.

---

## Step 1: Go Back to AWS RDS Creation Page  
- Revisit the **AWS RDS** creation page.
- Refresh the connected EC2 instance, and select your **new EC2 instance (`url_shortener`)** to associate it with the database.  

---

## Step 2: Configure VPC & Networking  

- **VPC (Virtual Private Cloud):**  
  - Automatically selected when linking EC2 to RDS.  
  - VPC isolates your resources (EC2, RDS, etc.) within a **private network**.  

- **DB Subnet Group:**  
  - Automatically configured.  

- **Public Access:** ❌ **Disable Public Access** (for security).  
  - If **public access is disabled**, you can **still access your RDS database** by first SSH-ing into your EC2 instance and then connecting from within the private network.  

---

## Step 3: Final Database Settings  

- **Connectivity:**  
  - Use **VPC Security Group Firewall**  
  - Amazon RDS will create a new **VPC security group (`rds-ec2-1`)** to allow connectivity between your EC2 instance and RDS database.  

- **Certificate:**  
  - Use **Default AWS RDS Certificate**.  

- **Database Authentication:**  
  - **Password authentication (default)** is fine.  

- **Monitoring:**  
  - Leave at **default settings** unless specific monitoring is required.  

---

## Step 4: Create the Database  

Click **Create Database** and wait for AWS to finish provisioning the RDS instance.  

---

## Step 5: Prepare to Connect to RDS via EC2  

### Option 1: SSH Into EC2, Then Connect to RDS  

1️⃣ **SSH into your EC2 instance:**  
```sh
ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-ip
```

2️⃣ **Use `psql` inside EC2 to connect to RDS:**  
```sh
psql -h your-rds-endpoint -U your_rds_username -d your_database_name
```

See below for where you can find this information.

3️⃣ **Enter your RDS database password when prompted.** ✅  


# 6. Retrieve Database Credentials  

To connect your Node.js application to RDS, you need the **database username, password, and endpoint**.  

---

## Step 1: Find Your Database Username  

Since AWS doesn’t allow you to retrieve your database password after creation, you **must reset it** if you don’t remember it. However, you can still find your **database username** easily.  

### 🔍 Find Your Database Username:  

1️⃣ Go to **AWS Console → RDS**.  
2️⃣ Click on your **database instance**.  
3️⃣ Navigate to the **Configuration** tab.  
4️⃣ Look for **Master username**.  

✅ **This is your database login username.** If you remember your password, you’re all set!  

---

## Step 2: Reset Your Database Password (If Needed)  

AWS **does not allow you to recover** the auto-generated password. If you need access, you must **reset it manually**.  

### 🔄 Reset Password via AWS Console:  

1️⃣ Go to **AWS Console → RDS**.  
2️⃣ Click on your **database instance**.  
3️⃣ Click **Modify** (top right corner).  
4️⃣ Scroll down to **Settings** → Enter a **new Master password**.  
5️⃣ Click **Continue**, then **Apply Changes**.  
6️⃣ **Select "Apply Immediately"** if you want the change to take effect right away.  

✅ You now have a new password! **Store it securely.**  

---

## Step 3: Find Your RDS Endpoint  

Your **RDS endpoint** is the hostname needed to connect your application to the database.  

### 🔍 Find Your RDS Endpoint:  

1️⃣ Go to **AWS Console → RDS**.  
2️⃣ Click on your **RDS instance**.  
3️⃣ In the **Connectivity & Security** section, find the **Endpoint** field.  
4️⃣ It will look something like this:  

```
mydatabase.xxxxxx.us-east-1.rds.amazonaws.com
```

✅ **Use this as your `your-rds-endpoint` when configuring your application.**  

---

# 7. Test Database Access via SSH (EC2 to RDS)  

Now that our **EC2 instance** and **RDS database** are set up, we need to test whether we can connect to RDS from within EC2.

---

## Step 1: Verify EC2 Instance is Reachable  

First, ensure your **EC2 instance is running** and accessible.  

### 🔍 Find Your EC2 Public IP  

1️⃣ Go to **AWS Console → EC2 → Instances**.  
2️⃣ Find your **EC2 instance** in the list.  
3️⃣ Look for **Public IPv4 Address** under **Instance Details**.  
4️⃣ Example: `52.14.123.45` (replace this with your actual IP).  

✅ **To check connectivity, ping your EC2 instance:**  

```sh
ping ec2-54-252-239-140.ap-southeast-2.compute.amazonaws.com
```

---

## Step 2: SSH into Your EC2 Instance  

Once your EC2 instance is running, log in via SSH.  

### 🔑 Secure Your Private Key  

AWS **requires strict permissions** on your private key file. Run the following:  

```sh
chmod 400 /path/to/your-key.pem
```

To verify permissions:  

```sh
ls -l /path/to/your-key.pem
```

### 🔗 SSH Into Your EC2 Instance  

```sh
ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-ip
```

Example:  

```sh
ssh -i /Users/jamesmcarthur/downloads/url_shortener_key.pem ec2-user@54.252.239.140
```

✅ **Replace:**  
- `/path/to/your-key.pem` → Actual path to your private key.  
- `your-ec2-public-ip` → Your EC2 instance’s **Public IPv4 Address**.  

---

## Step 3: Install PostgreSQL on EC2  

By default, **Amazon Linux 2023 does not include PostgreSQL**. Install it using:  

```sh
sudo dnf install -y postgresql15
```

Verify installation:  

```sh
psql --version
```

🔹 **Amazon Linux uses `dnf` as its package manager**, but older guides may reference `yum`:  

```sh
sudo yum install -y postgresql
```

Either works, but `dnf` is recommended for Amazon Linux 2023.

---

## Step 4: Connect to RDS from EC2  

Now, let's **test the database connection**.  

### 🔍 Find Your RDS Endpoint  

1️⃣ Go to **AWS Console → RDS**.  
2️⃣ Click on your **RDS instance**.  
3️⃣ Find the **Endpoint** under **Connectivity & Security**.  
4️⃣ Example:  

```
url-shortener.c1mi0g482he4.ap-southeast-2.rds.amazonaws.com
```

### 🔗 Connect to the Default `postgres` Database  

Run the following command inside EC2:  

```sh
psql -h url-shortener.c1mi0g482he4.ap-southeast-2.rds.amazonaws.com -U url_shortener -d postgres
```

Enter the **RDS password** when prompted:  

```
**********************************
```

✅ You are now connected to your **PostgreSQL database on RDS!**  

---

## Step 5: Create Your Database  

Since the RDS instance **does not have a database yet**, log in using the **default `postgres` database**, then create your own database.  

Once logged into PostgreSQL, run the following SQL commands to set up your database:  

```sql
CREATE DATABASE url_shortener;

\c url_shortener;

CREATE TABLE urls (
    id SERIAL PRIMARY KEY,
    short_path TEXT UNIQUE NOT NULL,
    original_url TEXT NOT NULL
);
```

---

## Step 6: Connect Directly to Your Database  

Now that the database is created, you can connect directly to it using:  

```sh
psql -h url-shortener.c1mi0g482he4.ap-southeast-2.rds.amazonaws.com -U url_shortener -d url_shortener
```

---

## ✅ Success!  
Your **EC2 instance can now connect to your RDS database**.  

---

# 8. Deploy the Node.js App with Nginx Reverse Proxy  

Now, we will **deploy the Node.js backend on EC2**, configure **Nginx as a reverse proxy**, and ensure **PM2** is managing the process.  

---

## Step 1: Upload and Run `start.sh` on EC2  

### 🔹 Upload the `start.sh` File to EC2  

1️⃣ Fill out the **`start.sh`** file with your **GitHub credentials** (if needed for cloning).  

2️⃣ Use **SCP** (Secure Copy Protocol) to transfer the file:  

```sh
scp -i /path/to/your-key.pem start.sh ec2-user@your-ec2-public-ip:/home/ec2-user/
```

✅ **Replace:**  
- `/path/to/your-key.pem` → Actual path to your **private key**.  
- `your-ec2-public-ip` → Your **EC2 instance’s public IP**.  

Now, **`start.sh` is uploaded** to `/home/ec2-user/` on your EC2 instance.  

---

## Step 2: Install Required Packages  

### 🔹 Replace `curl-minimal` with Full `curl`  

Amazon Linux 2023 **ships with a minimal version of curl**, which may cause issues. Replace it with the full version:  

```sh
sudo dnf swap curl-minimal curl -y
```

✅ This **removes `curl-minimal` and installs full `curl`** without breaking dependencies.  

---

## Step 3: Set Up `/var/www/` for Hosting  

### 🔹 Manually Create `/var/www/`  

```sh
sudo mkdir -p /var/www/
```

### 🔹 Grant Permissions to `/var/www/`  

Amazon Linux restricts write access to `/var/www/`. We need to allow `ec2-user` to manage it.  

#### 1️⃣ Change Ownership  

```sh
sudo chown -R ec2-user:ec2-user /var/www/
```

✅ Now `ec2-user` can write to `/var/www/myapp/`.  

#### 2️⃣ Set Correct Permissions  

```sh
sudo chmod -R 755 /var/www/
```

**Explanation:**  
- **755 Permission**:  
  - **Owner (ec2-user):** Read, write, execute  
  - **Group:** Read, execute  
  - **Others:** Read, execute  

✅ This ensures **files can be executed but not modified by unauthorized users**.  

---

## Step 4: Run the `start.sh` Deployment Script  

### 🔹 Make the script executable  

```sh
chmod +x start.sh
```

### 🔹 Run the deployment script  

```sh
./start.sh
```

✅ This script will **clone your repo, install dependencies, start the server**, and return an **HTTP URL for the backend**.  

---

## Step 5: Verify Deployment  

### 🔹 Check PM2  

PM2 should be running your Node.js app:  

```sh
pm2 list
```

### 🔹 Test Nginx Configuration  

Ensure Nginx is correctly configured:  

```sh
sudo nginx -t
```

### 🔹 View Logs in PM2  

- View the **last 100 lines** of logs:  

```sh
pm2 logs --lines 100
```

- View **error logs**:  

```sh
cat ~/.pm2/logs/myapp-error.log
```

---

## Step 6: Update EC2 Security Group  

To allow **web traffic**, update **EC2 inbound security rules**:  

### 🔹 Check Security Group Rules  

1️⃣ Go to **AWS Console → EC2 → Security Groups**.  
2️⃣ Find the **security group attached to your EC2 instance**.  
3️⃣ Click **Inbound Rules → Edit Inbound Rules**.  
4️⃣ Add the following rules **(if missing)**:  

| Type  | Protocol | Port Range | Source         |
|-------|---------|------------|---------------|
| HTTP  | TCP     | 80         | `0.0.0.0/0` (or your IP)  |
| HTTPS | TCP     | 443        | `0.0.0.0/0` (or your IP)  |

✅ **Now, Nginx should be reachable from the internet!**  

---

## Step 7: Upload Environment Variables (`.env`)  

Your app may require environment variables (e.g., database credentials).  

### 🔹 Upload the `.env` File to EC2  

```sh
scp -i /path/to/your-key.pem .env ec2-user@your-ec2-public-ip:/home/ec2-user/
```

### 🔹 Move `.env` to `/var/www/myapp/`  

```sh
sudo mv /home/ec2-user/.env /var/www/myapp/
```

✅ **Your application now has the necessary environment variables!**  

Then **restart your app** by running `./start.sh`.

---

## Step 8: Test the URL Shortener API  

### 🔹 Test URL Shortening (Localhost)  

```sh
curl -X POST http://localhost:3000/shorten -H "Content-Type: application/json" -d '{"originalUrl": "https://example.com"}'
```

### 🔹 Test Redirect (Localhost)  

```sh
curl -i http://localhost:3000/go/xylophone.banana.banana
```

### 🔹 Test URL Shortening (Public IP)  

```sh
curl -X POST http://your-ec2-public-ip/shorten -H "Content-Type: application/json" -d '{"originalUrl": "https://example.com"}'
```

### 🔹 Test Redirect (Public IP)  

```sh
curl -i http://your-ec2-public-ip/go/apple.vulture.monkey
```

---

## ✅ Success!  
Your **Node.js app is now deployed on EC2**, running behind **Nginx**, and using **RDS for PostgreSQL**. 🎉  

# 9. Set Up an AWS Application Load Balancer (ALB)  

To improve scalability, security, and fault tolerance, we will set up an **AWS Application Load Balancer (ALB)** to distribute traffic to our EC2 instance.  

---

## Why Use an ALB?  

✅ **Load Balancing:** Distributes traffic across multiple EC2 instances.  
✅ **Failover Handling:** Automatically routes traffic if an instance crashes.  
✅ **HTTPS Support:** Enables SSL/TLS encryption with **AWS Certificate Manager (ACM)**.  
✅ **Security Improvements:** Uses security groups & integrates with AWS Web Application Firewall (WAF).  

---

## Step 1: Create an Application Load Balancer  

### 🔹 Go to AWS **EC2 → Load Balancers**  
1️⃣ Click **"Create Load Balancer"**.  
2️⃣ Select **"Application Load Balancer"**.  

---

## Step 2: Configure ALB Settings  

- **Name:** Example → `aws-url-shortener-alb`  
- **Scheme:**  
  - **Internet-facing** (if users will access it from the internet).  
  - **Internal** (for internal AWS VPC communication only).  
- **IP Address Type:** Choose **IPv4**.  
- **VPC:** Select the **VPC where your EC2 instance is running**.  
- **Availability Zones:** Select **at least two subnets** for high availability.  

✅ Click **Next**.  

---

## Step 3: Configure Security Groups  

We will set up **two security groups**:  

### ✅ ALB Security Group (Public Access)  

1️⃣ **Go to AWS EC2 → Security Groups → Click "Create Security Group"**.  
2️⃣ **Name:** `alb-security-group`  
3️⃣ **Inbound Rules:**  

| Type  | Protocol | Port Range | Source         |
|-------|---------|------------|---------------|
| HTTP  | TCP     | 80         | `0.0.0.0/0` (Public access) |
| HTTPS | TCP     | 443        | `0.0.0.0/0` (For SSL) |

4️⃣ **Outbound Rules:** Leave default (`Allow all traffic`).  
5️⃣ Click **"Create Security Group"**.  

### ✅ EC2 Security Group (Restrict Access to ALB Only)  

1️⃣ **Find the security group attached to your EC2 instance.**  
2️⃣ **Edit inbound rules**:  

| Type        | Protocol | Port Range | Source (Security Group ID) |
|------------|---------|------------|----------------------------|
| Custom TCP | TCP     | 3000       | `sg-xxxxxxxxxxxx` (Your ALB Security Group) |

✅ This **restricts access** so only the ALB can send traffic to your EC2 instance.  

✅ Click **Save Changes**.  

---

## Step 4: Configure Listeners & Routing  

ALB **listeners** handle incoming traffic and forward it to the correct target group.  

### 🔹 HTTP Listener (Port 80 → Redirect to HTTPS)  

1️⃣ In the **ALB creation page**, go to **Listeners and Routing**.  
2️⃣ Find the **HTTP:80 listener**.  
3️⃣ Click **Create Target Group**:  
   - **Type:** Instances  
   - **Target Group Name:** `url-shortener-alb-80`  
   - **Protocol:** HTTP  
   - **Port:** 80  
   - **VPC:** Same as EC2  
4️⃣ Click **Next**.  
5️⃣ **Register the target**:  
   - Select your **EC2 instance**.  
   - Click **Include as pending below**.  
   - Click **Create Target Group**.  
6️⃣ Go back to **Listeners** → Refresh **HTTP:80 listener** → Select your new **Target Group**.  

### 🔹 HTTPS Listener (Port 443 → Forward to EC2)  

⚠️ **(Only if you have an SSL certificate in AWS Certificate Manager – Skip for now)**  

1️⃣ Click **Add Listener**.  
2️⃣ **Protocol:** HTTPS  
3️⃣ **Port:** 443  
4️⃣ **SSL Certificate:**  
   - If you have an **AWS ACM certificate**, select it.  
   - Otherwise, request a **free SSL certificate** in **AWS Certificate Manager**.  
5️⃣ **Forward Traffic to Target Group:**  
   - Click **Create Target Group**.  
   - **Name:** `my-app-tg`  
   - **Type:** Instance  
   - **Protocol:** HTTP  
   - **Port:** 3000  
   - **VPC:** Same as EC2  
   - **Health Check Path:** `/`  
6️⃣ Click **Next** → **Register Targets** → Select EC2 instance → **Include as pending** → **Create Target Group**.  
7️⃣ Save the listener configuration.  

✅ If SSL is not configured yet, **skip the HTTPS step for now**.  

---

## Step 5: Create the Load Balancer  

1️⃣ Click **"Create Load Balancer"**.  
2️⃣ **Wait for provisioning** (this may take a few minutes).  

---

## Step 6: Find Your ALB’s Public DNS  

1️⃣ Go to **AWS EC2 Console → Load Balancers**.  
2️⃣ Find your **ALB** in the list.  
3️⃣ Look for the **"DNS name"** field.  
4️⃣ It will look something like this:  

```
http://aws-url-shortener-alb-123456789.ap-southeast-1.elb.amazonaws.com
```

✅ **Now, all your API requests should use this new ALB URL instead of the EC2 public IP!**  

---

## Step 7: Test the ALB  

Now that the **ALB is active**, test the **URL shortener API** using the new **ALB URL**.  

### 🔹 Test URL Shortening (Public ALB URL)  

```sh
curl -X POST http://aws-url-shortener-alb-123456789.ap-southeast-1.elb.amazonaws.com/shorten \
     -H "Content-Type: application/json" \
     -d '{"originalUrl": "https://example.com"}'
```

### 🔹 Test Redirect via ALB  

```sh
curl -i http://aws-url-shortener-alb-123456789.ap-southeast-1.elb.amazonaws.com/go/apple.vulture.monkey
```

---

## ✅ Success!  

Your **ALB is now routing traffic to your EC2 instance**, making the app **publicly accessible**. 🎉  

These are great extra steps to enhance **reliability, automation, monitoring, and scalability** for your AWS deployment. Below is an outline of how we will proceed with each step.

---

# 🔥 EXTRA STEPS FOR A PRODUCTION-GRADE AWS DEPLOYMENT  

## 9️⃣ Automate RDS Backups into S3 with AWS Lambda & CloudWatch  

**Why?**  
✅ Ensures automated database backups.  
✅ Offloads storage to **S3**, reducing RDS costs.  
✅ Provides disaster recovery options.  

### 📌 Steps to Implement:  
1️⃣ **Create an S3 Bucket** to store backups.  
2️⃣ **Set Up AWS Lambda** to:  
   - Take **RDS snapshots** on a schedule.  
   - Export snapshots to **S3**.  
3️⃣ **Create a CloudWatch Rule** to trigger the Lambda function.  
4️⃣ **Test & Verify** that backups are stored correctly in **S3**.  

---

## 🔟 CI/CD Pipeline with GitHub Actions, S3, and AWS CodeDeploy  

**Why?**  
✅ Automates deployments **on push to GitHub**.  
✅ Eliminates manual SSH commands.  
✅ Ensures **zero-downtime deployments**.  

### 📌 Steps to Implement:  
1️⃣ **Set up AWS S3** to store deployment artifacts.  
2️⃣ **Create AWS CodeDeploy application**.  
3️⃣ **Configure EC2 instance to work with CodeDeploy**.  
4️⃣ **Write a GitHub Actions CI/CD pipeline** to:  
   - Build the app.  
   - Upload to S3.  
   - Trigger **AWS CodeDeploy** to deploy the latest version.  
5️⃣ **Test & Automate Future Deployments.**  

---

## 1️⃣1️⃣ Set Up AWS CloudWatch for Monitoring & Optimization  

**Why?**  
✅ Provides **real-time logs & performance metrics**.  
✅ Detects **high CPU usage, memory leaks, or slow queries**.  
✅ Alerts you when something goes wrong.  

### 📌 Steps to Implement:  
1️⃣ **Enable CloudWatch Logs** for EC2 & RDS.  
2️⃣ **Set up CloudWatch Alarms** to monitor:  
   - **High CPU Usage** (above 80%).  
   - **Memory Usage** (if using CloudWatch agent).  
   - **RDS Connection failures**.  
3️⃣ **Automate alerts** via AWS SNS (Email/Slack alerts).  

---

## 1️⃣2️⃣ Set Up Auto-Scaling for EC2 Instances  

**Why?**  
✅ Automatically **adds or removes** EC2 instances based on traffic.  
✅ Improves **availability & cost-efficiency**.  

### 📌 Steps to Implement:  
1️⃣ **Create an Auto-Scaling Group (ASG)**.  
2️⃣ **Define Scaling Policies**:  
   - Scale **up** if CPU > 70%.  
   - Scale **down** if CPU < 20%.  
3️⃣ **Attach ALB** to load balance new instances.  
4️⃣ **Test auto-scaling** by simulating traffic spikes.  

---

## 1️⃣3️⃣ Use the AWS JavaScript SDK  

**Why?**  
✅ **Programmatically interact** with AWS services.  
✅ Automate actions via **Node.js scripts**.  
✅ Manage **S3, RDS, EC2, and more** from your app.  

### 📌 Steps to Implement:  
1️⃣ Install AWS SDK in your project:  

```sh
npm install aws-sdk
```

2️⃣ Use SDK to:  
   - Upload/download files from **S3**.  
   - Start/stop **EC2 instances**.  
   - Fetch database snapshots from **RDS**.  
   - Send messages via **SNS**.  
3️⃣ Create **Lambda functions** using the SDK for automation.  

---

If you want to see a **Part 2** where we do these extra steps, let me know and be sure to ⭐️ the GitHub repo ☺️

Cheers,  
James