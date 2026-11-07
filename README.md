# IMS 3310 Course Helper

A free web page for students in IMS 3310-501 International Business (UT Dallas, Professor Xiaowen Tan).

Open it here: https://wen-tan.com/ims3310-coach/

It shows the class schedule, exam dates and deadlines, grading and course policies, and the project requirements and rubrics, all from the course syllabus (revised 9 Oct 2024). The Ask tab has three modes:

- **Answer**: answers questions about the course and its concepts using the syllabus and the lecture slides.
- **Hint-first tutor**: gives a hint and a guiding question first, and the full explanation once you have tried.
- **Practice quiz**: five multiple-choice questions on a chapter, written from the lecture slides, with explanations. Not graded.

The Deadlines tab can download every exam and due date as a calendar file. Questions are saved without names or network addresses so Professor Tan can see which topics are confusing; please don't type personal information.

AI answers can be wrong. The syllabus and Professor Tan's announcements in class or on eLearning are final. For extensions, make-up exams, grades or personal situations, email Xiaowen.Tan@utdallas.edu.

No account or sign-in is needed.

## How it is built

- `index.html` is the whole site. It is generated from the course files by a build script kept outside this repository.
- `worker/` is the small server that answers Ask-tab questions with Claude. See `worker/README.md`.
