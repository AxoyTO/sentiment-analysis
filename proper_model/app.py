from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline

app = FastAPI()
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

class SentimentRequest(BaseModel):
    text: str

@app.post("/predict")
def predict_sentiment(request: SentimentRequest):
    result = classifier(request.text)[0]
    return {"label": result["label"], "score": result["score"]}

@app.get("/health")
def health_check():
    return {"status": "ok"}