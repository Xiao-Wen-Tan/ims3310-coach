# IMS 3310 Course Helper

A free web page for students in IMS 3310-501 International Business (UT Dallas, Professor Xiaowen Tan).

Open it here: https://wen-tan.com/ims3310-coach/

It shows the class schedule, exam dates and deadlines, grading and course policies, and the project requirements and rubrics, all from the course syllabus (revised 9 Oct 2024). The Ask tab has three modes:

- **Answer**: answers questions about the course and its concepts using the syllabus and the lecture slides.
- **Report tutor**: coaching for the mid-term and final group project reports. It either walks your group through a six-step tutorial, one step at a time with a goal, a to-do list and a coach for each step (progress is saved in your browser), or gives feedback on a draft, pasted as text (up to about 4,000 words, a whole report) or uploaded as a PDF (up to 5 MB), following the final report rubric or, for the mid-term, the syllabus description. It never writes report text and never predicts a grade. Drafts and files are not saved.
- **Practice quiz**: five multiple-choice questions at a time on a chapter, drawn from a fixed set of about 10 per chapter written from Professor Tan's lecture slides, with explanations and the slide numbers they come from. It works without the AI helper. Not graded.

The Deadlines tab can download every exam and due date as a calendar file. Questions are saved without names or network addresses so Professor Tan can see which topics are confusing; please don't type personal information.

AI answers can be wrong. The syllabus and Professor Tan's announcements in class or on eLearning are final. For extensions, make-up exams, grades or personal situations, email Xiaowen.Tan@utdallas.edu.

No account or sign-in is needed.

## How it is built

- `index.html` is the whole site. It is generated from the course files by a build script kept outside this repository.
- `worker/` is the small server that answers Ask-tab questions and runs the report tutor with Claude. See `worker/README.md`. The practice quiz does not use it.
