# My Git Repository

## Overview
This project is designed to automate the process of building and running a Java application using a Bash script. It leverages Maven for building the application and ensures that the necessary tools are available before proceeding.

## Setup Instructions
1. **Clone the repository:**
   ```
   git clone https://your-repository-url.git
   cd my-git-repo
   ```

2. **Install Java and Maven:**
   Ensure that Java and Maven are installed on your system. You can verify their installation by running:
   ```
   java -version
   mvn -version
   ```

3. **Configure the script:**
   Modify the `scripts/java.sh` file if necessary to set the `TARGET_DIR` and `USERNAME` variables.

## Usage
To build and run the Java application, execute the following command:
```
bash scripts/java.sh [TARGET_DIR] [USERNAME]
```
- `TARGET_DIR`: The directory containing the Java application (default is the current directory).
- `USERNAME`: The user under which the application should run (default is the current user).

The script will compile the application, manage the execution of the generated JAR file, and log output to `app.log`.