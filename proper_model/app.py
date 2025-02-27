from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline
from fastapi.middleware.cors import CORSMiddleware
import textstat
import re

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

cola_model = pipeline("text-classification", model="textattack/bert-base-uncased-CoLA")

class SentimentRequest(BaseModel):
    text: str

def is_meaningless(text):
    if not text:
        return True
    
    if re.fullmatch(r"[^a-zA-Z]+", text):
        return True

    readability_score = textstat.flesch_reading_ease(text)
    if readability_score > 120:
        return True

    result = cola_model(text)[0]
    print(result)

    if result["label"] == "LABEL_0":
        return True

    return False

@app.post("/predict")
def predict_sentiment(request: SentimentRequest):
    text = request.text.strip()
    
    if is_meaningless(text):
        return {"label": "neutral", "score": 0.0}

    result = classifier(text)[0]
    
    return {"label": result["label"], "score": round(result["score"], 2)}

@app.get("/health")
def health_check():
    return {"status": "ok"}
