# Students 1st Actions

This procedure defines the first critical steps a student takes to get started. The goal is to move from "interested" to "actively working" in a personal local environment, while capturing intent early. Treat this moment as high-risk for drop-off.

## Purpose

- Ensure the student starts working locally in a personal branch.
- Capture goals and starting context early via a local tool (interactive Q&A).
- Persist the intent as a durable record in a personal folder.
- Enable the coach to review progress asynchronously.

## Outcomes

- A personal branch exists locally for the student.
- The student has answered initial questions and recorded them.
- A `learners-state.md` file is stored under the student GitHub handle folder.
- The coach receives a review artifact, even if GitHub is not ready.

## Location Conventions

- Personal folder: `procedures/learners/<github-handle>/`
- State file: `procedures/learners/<github-handle>/learners-state.md`
- Maintenance scripts: `procedures/bin/`

## Student Flow (First Actions)

1. Create a personal local branch
   - Branch name: `student/<github-handle>`
   - The student works locally in this branch from the first command onward.
2. Run the local intake tool
   - The tool is interactive and asks the "intake questions" below.
   - The student answers in the tool, not in a chat.
3. Persist the intake responses
   - The tool writes `procedures/learners/<github-handle>/learners-state.md`.
   - The file is considered the canonical intent record.
4. Send the review artifact to the coach
   - If GitHub is ready, open a PR or share the file link.
   - If GitHub is not ready, use the email template below.

## Intake Questions (Tool Prompts)

The tool must ask these questions so the student can think ahead and capture intent quickly:

1. What is your primary goal for this workshop? (1-2 sentences)
2. What is your current role or context? (team, product, workload)
3. What prior experience do you have with Kafka or Confluent Cloud?
4. Which environment constraints do you have locally? (OS, permissions, VPN, proxies)
5. What is your expected outcome by the end of the workshop?
6. What would make this workshop a success for you?
7. What is your GitHub handle (or preferred identifier)?

## Tool Usage

```bash
./procedures/bin/student-intake.sh
```

Output:
- `procedures/learners/<github-handle>/learners-state.md`
- `procedures/learners/<github-handle>/coach-review.md`

## Coach Review (Asynchronous)

- The coach reviews `learners-state.md` and provides a brief response.
- The response can be a PR comment or a separate review page sent back to the student.
- The review should confirm understanding, highlight risks, and propose the next step.

## Email Template (If GitHub Is Not Ready)

Subject: Workshop Intake - <github-handle> - First Actions

Hello <Coach Name>,

I completed the student intake questions for the workshop. Here are my answers:

1. Primary goal:
   <answer>

2. Current role/context:
   <answer>

3. Kafka/Confluent experience:
   <answer>

4. Local environment constraints:
   <answer>

5. Expected outcome:
   <answer>

6. Success criteria:
   <answer>

7. GitHub handle / identifier:
   <answer>

If you need the responses in another format, let me know. Once GitHub is ready, I will share the `learners-state.md` file.

Thanks,
<Your Name>

## Implementation Plan (Solution Steps)

1. Create a minimal local intake tool under `procedures/bin/`.
   - Accepts input interactively.
   - Writes `learners-state.md` to the personal folder.
2. Add a template generator for `learners-state.md`.
   - Pre-populates prompts and headers.
3. Add a validation step.
   - Ensure all required questions are answered before writing the file.
4. Add a coach review stub template.
   - A short review format saved next to the state file.
5. Document usage in this procedure.
   - Provide a one-line command and expected output location.

## Notes

This is a critical onboarding moment. If a student fails here, we likely lose them. Keep the steps short, the questions focused, and the output immediate.
