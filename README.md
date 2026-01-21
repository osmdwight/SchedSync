### In a student’s daily life, managing schedules can often feel overwhelming. Many students rely on manual planners, screenshots of class schedules, or even just mental notes to keep track of their commitments. This approach frequently leads to missed classes, activities, or deadlines, ultimately resulting in unproductivity and, in some cases, negatively impacting academic performance. To address this challenge, our group developed SchedSync, a digital scheduling solution designed specifically for students. Our mission is to help students manage their academic responsibilities more efficiently through a platform that is accessible, reliable and easy to use. SchedSync keeps students on track and stress-free, because every student deserves a tool that makes success simple.

#### Tech Stack Summary
---
**Flutter** - Used for Frontend Layer (UI/UX of the app)

**AWS API Gateway** - Used for API Layer (Connection)

**AWS DynamoD**B - Used for Database Layer (Student data, schedules, courses)

**AWS S3** - Used for Storage Layer (Admin Site)

**AAWS IAM** - Used for Security Layer (Service Permissions)

#### Database Schema
---
<img width="538" height="380" alt="image" src="https://github.com/user-attachments/assets/9a2d641a-dcc3-462d-b5b6-ddc85a63ccc3" />

#### System Structure Schema
---
<img width="284" height="258" alt="image" src="https://github.com/user-attachments/assets/4777726e-a093-4b81-b5aa-96b87ec63798" />

#### App Features
---
The developers used Flutter to create the mobile application, serving as the Frontend layer responsible for the application's UI/UX. 

**Core Screens and Parts:**
---
- Theme Management: Users can enable light and dark modes with the help of a particular function (switchTheme).

- Login and Registration: This Screen used a standard Flutter Form widgets with TextFormField to gather necessary information such as email address, first and last name, and password. 

- Profile Screen: This screen is used for managing the user's personal details (name, email, and password) and logout button

- Home Screen (Dashboard): This screen provides a quick, consolidated overview of the user's schedule, current date, and upcoming exams and submission.

- ClassScreen: This screen displays all classes the student has. It provides a single view of the user's classes and enables navigation to detailed course information. 

- Course Details (CourseScreen): This screen shows all detailed information about a single class, including its schedule, instructor, and all associated academic tasks (exams and submissions).

- Calendar view: It shows the monthly timeline, allowing users to visually track exam dates and submission deadlines.

**Add / Edit Screens**
- Add Class 
- Edit Class 
- Add Exam
- Edit Exam 
- Add Submission 
- Edit Submission 
- Each screen collects user input using the flutter forms and sends the data to the backend through the service functions 

Bottom Navigation Bar
Provides quick access between major sections of the app (Home, Add, Classes).

#### Documentation paper and presentation Report
---
The documentation of this application app can be accessed [here](https://docs.google.com/document/d/1pz2a9H-8t2r7Jo3kz5QnxLOXjTlRmxryQIpK_szd7oA/edit?usp=sharing) and the presentation can be accessed [here](https://www.canva.com/design/DAG6ChgHoII/t8kWz59ZvYSXNEohVu4W1w/edit)


#### Sample Outcome
---
<img width="944" height="1016" alt="image" src="https://github.com/user-attachments/assets/ff38b7e2-bb82-4083-af9a-85dbd21dd027" />

<img width="942" height="1010" alt="image" src="https://github.com/user-attachments/assets/cbdd3614-9e7a-4ace-bdf9-accd4d1b038e" />

<img width="591" height="431" alt="image" src="https://github.com/user-attachments/assets/510686fe-8b85-4f48-b5c1-ebc97887648c" />

<img width="580" height="402" alt="image" src="https://github.com/user-attachments/assets/c140c180-dfe7-4490-bdf6-91f0b5939abb" />




