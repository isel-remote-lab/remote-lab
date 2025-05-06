<p align="center"><a href="https://github.com/isel-remote-lab"><img src="https://github.com/isel-remote-lab/remote-lab/blob/main/img/transparent-logo.png" width="300"/></a></p>
<p align="center"><b>ISEL Remote Lab</b></p>
<p align="center">
  <a href="https://github.com/isel-remote-lab/api"><img alt="API" src="https://img.shields.io/badge/API-orange"></a>
  <a href="https://github.com/isel-remote-lab/website"><img alt="Website" src="https://img.shields.io/badge/Website-blue"></a>
  <a href="https://github.com/isel-remote-lab/documentation"><img alt="Documentation" src="https://img.shields.io/badge/Documentation-purple"></a>
</p>

------------------------------

# Remote Lab 🚀

This project is a platform that provides remote laboratories equipped with connected hardware, enabling remote configuration, visualization, and manipulation of these devices. An intuitive website and a RESTful API are provided to interact with the system. For better organization, this repository contains several sub-repositories. As their names indicate, they include all the necessary files for the platform to function. Check out the contents and respective documentation in the following repositories:
- **[API](https://github.com/isel-remote-lab/api)** -> Contains the API code, along with documentation for the REST API and separate build information for those who wish to build only the API. It was developed using Spring Boot and Kotlin. For more details, please refer to the repository page.
- **[Website](https://github.com/isel-remote-lab/website)** -> Includes the website code and its respective documentation. This project was developed using Next.js. For additional information, check the repository page.
- **[Documentation](https://github.com/isel-remote-lab/documentation)** -> Although the above repositories include documentation and wiki pages for build and execution information, this project was developed as a final project for a bachelor’s degree at ISEL. Therefore, a separate repository was created to house the final report and other important documents. Please see the repository page for detailed information or to review specific decisions and additional insights.

## What This Project Provides ⚙️

- **Remote Laboratories with Hardware Visualization**: By enabling real-time FPGA programming through the website, the platform offers remote laboratories where users can connect and interact with the lab's hardware as needed.
- **Separated Roles**: Designed for ISEL, the system features a Role-Based Access Control (RBAC) mechanism with distinct roles for Students, Teachers, and Administrators, ensuring that each user has the appropriate permissions.
- **Security**: By adhering to industry standards and keeping the software up-to-date, the platform minimizes potential vulnerabilities. For further security information, please refer to the [API repository](https://github.com/isel-remote-lab/api).

## About ℹ️
As mentioned above, this is a final project for the Computer Science and Computer Engineering bachelor’s degree at [ISEL](https://www.isel.pt/en). Many courses require physical FPGAs for testing VHDL code and manipulating switches. This project addresses several common challenges:

- **24/7 Availability**: FPGAs are not always available and are limited in quantity. The developed plataform allows students to access remote laboratories, which can have multiple hardware devices connected simultaneously, ensuring round-the-clock availability.
- **High Cost**: It is generally unrealistic to expect students to purchase an FPGA or similar hardware due to their high cost.
- **Compatibility**: Students using ARM-based computers might face compatibility issues with certain FPGAs. For example, ISEL uses the Intel DE-10 Lite in some courses, which may not be compatible with ARM-based systems due to specific software constraints. With this remote approach, students can connect to the laboratory from anywhere at any time and use the hardware without compatibility concerns.

### Project Details 📄
It's not provided a classic account registration method—instead, authentication is achieved using Microsoft OAuth via the NextAuth framework. The backend also supports other OAuth methods as long as they provide the basic information required by the database. For more details, please refer to the [API repository](https://github.com/isel-remote-lab/api). 

When a user logs in, they are greeted with the home page, where they can view their laboratories, account information, the current active role, an option to switch roles (if they have the proper permissions), and a search bar. If the user is logged in as a *Student*, they can enter a laboratory. In this case, the user joins a waiting queue and receives information about their current position and an estimated waiting time. Since a laboratory may have multiple hardware devices assigned, when the user reaches the front of the queue, they are connected to one of the available devices. At that moment, the dashboard of the laboratory is displayed, allowing real-time hardware visualization and manipulation.

For a *Teacher*, the home page offers additional functionalities. A teacher can create, update, or delete a laboratory. Moreover, teachers can view the page as a Student, as their permissions encompass all student functionalities. Teachers also have the ability to create groups and assign users to these groups. This grouping system is essential because it is the only method for users to join a laboratory. A teacher can assign multiple groups to a laboratory, and only the users in those groups will have access to view and join the laboratory. Note that only the owner of a laboratory is allowed to update its information and configuration.

# Setup 🛠️
Clone the repository and run the setup script. This script is the easiest way to build the project since it is designed to work with Docker containers. If you prefer to build the project separately—which is not recommended—we highly suggest reviewing the build instructions provided in each repository or examining the Docker Compose files available in this repository.

After executing the setup script, an intuitive setup guide will be displayed. Simply follow the instructions, and by the end you will have the project built and ready to use.
