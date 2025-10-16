import os
import uuid
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from PyPDF2 import PdfReader
import google.generativeai as genai

# Load key from env
GEMINI_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_KEY:
    raise RuntimeError("Please set GEMINI_API_KEY in .env")
genai.configure(api_key=GEMINI_KEY)
MODEL_NAME = "gemini-2.5-flash"

# --- In-memory stores (demo only). Use DB in production ---
RESUMES = {}        # resume_id -> resume_text
SESSIONS = {}       # session_id -> { resume_id, qna: [{q,a}], last_question }

def extract_text_from_file(file_obj):
    reader = PdfReader(file_obj)
    text = ""
    for page in reader.pages:
        text += page.extract_text() or ""
    return text

@csrf_exempt
@require_POST
def upload_resume(request):
    pdf = request.FILES.get("pdf")
    if not pdf:
        return JsonResponse({"status":"error","message":"No pdf file"}, status=400)
    try:
        text = extract_text_from_file(pdf)
        resume_id = str(uuid.uuid4())
        RESUMES[resume_id] = text
        return JsonResponse({"status":"success","resume_id": resume_id, "resume_text": text})
    except Exception as e:
        return JsonResponse({"status":"error","message": str(e)}, status=500)

@csrf_exempt
@require_POST
def start_interview(request):
    import json
    body = json.loads(request.body.decode("utf-8"))
    resume_id = body.get("resume_id")
    if not resume_id or resume_id not in RESUMES:
        return JsonResponse({"status":"error","message":"Invalid resume_id"}, status=400)

    resume_text = RESUMES[resume_id]
    session_id = str(uuid.uuid4())
    SESSIONS[session_id] = {"resume_id": resume_id, "qna": [], "last_question": None}

    prompt = f"""
You are an AI interviewer. Based on the resume below, ask ONE interview question to start.
Resume:
{resume_text}

Rules:
- Ask only one question. Keep it friendly and clear.
- Keep question short (1 sentence).
"""
    try:
        model = genai.GenerativeModel(MODEL_NAME)
        resp = model.generate_content(prompt)
        question = getattr(resp, "text", "").strip()
        SESSIONS[session_id]["last_question"] = question
        return JsonResponse({"status":"success","session_id":session_id,"question":question})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)}, status=500)

@csrf_exempt
@require_POST
def answer_question(request):
    import json
    body = json.loads(request.body.decode("utf-8"))
    session_id = body.get("session_id")
    answer = body.get("answer","").strip()
    if not session_id or session_id not in SESSIONS:
        return JsonResponse({"status":"error","message":"Invalid session_id"}, status=400)

    # If user wants to quit
    if answer.lower() in ("quit","exit","stop"):
        return JsonResponse({"status":"success","message":"quitting"})

    session = SESSIONS[session_id]
    last_q = session.get("last_question","")
    session["qna"].append({"question": last_q, "answer": answer})

    followup_prompt = f"""
You're conducting an interview. Resume:
{RESUMES[session['resume_id']]}

Last question:
{last_q}

Candidate's answer:
{answer}

Now:
1) Give a one-line acknowledgement or short feedback.
2) Ask the next logical interview question (only 1 sentence).
Return both separated by a newline. Keep short.
"""
    try:
        model = genai.GenerativeModel(MODEL_NAME)
        resp = model.generate_content(followup_prompt)
        text = getattr(resp, "text", "").strip()
        # split first line as ack, rest as next question (best-effort)
        parts = text.split("\n", 1)
        ack = parts[0].strip()
        next_q = parts[1].strip() if len(parts) > 1 else ""
        session["last_question"] = next_q
        return JsonResponse({"status":"success","ack":ack,"next_question":next_q})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)}, status=500)

@csrf_exempt
@require_POST
def finish_evaluate(request):
    import json
    body = json.loads(request.body.decode("utf-8"))
    session_id = body.get("session_id")
    if not session_id or session_id not in SESSIONS:
        return JsonResponse({"status":"error","message":"Invalid session_id"}, status=400)

    session = SESSIONS[session_id]
    qna_text = "\n".join([f"Q: {qa['question']}\nA: {qa['answer']}" for qa in session["qna"]])
    eval_prompt = f"""
You are an expert technical interviewer. Evaluate the candidate based on resume and interview below.

Resume:
{RESUMES[session['resume_id']]}

Interview transcript:
{qna_text}

Provide:
1) Short strengths (1-2 lines)
2) Areas to improve (1-2 lines)
3) Score from 0 to 10 in format: Score: X/10

Keep under 150 words.
"""
    try:
        model = genai.GenerativeModel(MODEL_NAME)
        resp = model.generate_content(eval_prompt)
        evaluation = getattr(resp, "text", "").strip()
        # Optionally persist session/result here
        return JsonResponse({"status":"success","evaluation":evaluation, "qna": session["qna"]})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)}, status=500)
