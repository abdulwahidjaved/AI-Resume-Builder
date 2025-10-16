import PyPDF2
import google.generativeai as genai

# 🧠 STEP 1: Configure Gemini API key
genai.configure(api_key="AIzaSyCRCfv9auSVCTmSL-74mJBTRwraF0VwuXY")  # replace with your Gemini API key

# 🧩 STEP 2: Function to extract text from PDF
def extract_text_from_pdf(pdf_path):
    text = ""
    with open(pdf_path, "rb") as file:
        reader = PyPDF2.PdfReader(file)
        for page in reader.pages:
            text += page.extract_text() or ""
    return text

# 🎯 STEP 3: Start interactive interview loop
def start_interview(resume_text):
    model = genai.GenerativeModel("gemini-2.5-flash")

    # Keep track of all Q&A for scoring later
    conversation_history = []

    context_prompt = f"""
You are an AI interviewer. Based on the candidate's resume below, ask one interview question at a time.
Resume:
{resume_text}

Rules:
- Ask only one question at a time.
- Wait for the user's answer before continuing.
- Tailor questions to the candidate's skills, projects, and education.
- Be professional but friendly.
"""

    print("\n🤖 Gemini AI Interviewer Ready!")
    print("Type 'quit' anytime to end the interview.\n")

    # Generate first question
    response = model.generate_content(context_prompt)
    question = response.text.strip()
    print("Gemini:", question)

    while True:
        user_input = input("\nYou: ").strip()
        if user_input.lower() in ["quit", "exit", "stop"]:
            print("\nGemini: Sure, let's wrap up your interview. Evaluating your responses... ⏳\n")
            break

        conversation_history.append({"question": question, "answer": user_input})

        # Continue conversation
        followup_prompt = f"""
You are conducting an interview based on this resume:
{resume_text}

The last question you asked was:
{question}

The candidate's answer was:
{user_input}

Now:
1. Give a short acknowledgment or mini feedback (1–2 lines).
2. Then ask the next logical interview question.
"""

        try:
            response = model.generate_content(followup_prompt)
            question = response.text.strip()
            print("\nGemini:", question)
        except Exception as e:
            print("Error communicating with Gemini:", e)
            break

    # 🎓 After quitting, evaluate performance
    if conversation_history:
        evaluate_candidate(model, resume_text, conversation_history)
    else:
        print("No answers were recorded. Exiting.")


# 🏁 STEP 4: Evaluation Function
def evaluate_candidate(model, resume_text, conversation_history):
    all_qna = "\n".join(
        [f"Q: {item['question']}\nA: {item['answer']}" for item in conversation_history]
    )

    evaluation_prompt = f"""
You are an expert technical interviewer.
Evaluate the candidate based on their resume and the interview transcript below.

Resume:
{resume_text}

Interview Transcript:
{all_qna}

Provide:
1. A short summary of the candidate's strengths
2. One or two areas of improvement
3. An overall interview rating out of 10 (format: "Score: X/10")

Keep it under 150 words.
"""

    try:
        evaluation = model.generate_content(evaluation_prompt)
        print("\n🧾 Gemini Interview Evaluation:\n")
        print(evaluation.text.strip())
    except Exception as e:
        print("Error generating evaluation:", e)


# 🚀 STEP 5: Run the program
if __name__ == "__main__":
    pdf_path = input("Enter the path to your resume PDF: ").strip()
    try:
        resume_text = extract_text_from_pdf(pdf_path)
        print("\n✅ Resume loaded successfully.\n")
        start_interview(resume_text)
    except Exception as e:
        print("Error reading PDF:", e)
