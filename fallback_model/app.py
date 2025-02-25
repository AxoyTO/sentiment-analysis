from fastapi import FastAPI
from pydantic import BaseModel
import string

app = FastAPI()

def load_keywords(file_path):
    try:
        with open(file_path, "r") as f:
            return [line.strip().lower() for line in f.readlines()]
    except FileNotFoundError:
        return []

KEYWORDS = {
    "positive": load_keywords("data/positive-words.txt"),
    "negative": load_keywords("data/negative-words.txt")
}


def clean_word(word):
    return word.strip(string.punctuation).lower()

def simple_sentiment_analysis(text: str):
    text = text.lower()
    sentiment = "neutral"
    overall_score = 0.0
    k = 0
    for label, words in KEYWORDS.items():
        for word in text.split(" "):
            word = clean_word(word)
            if word in words:
                k += 1
                if label == "positive":
                    overall_score += 1.0
                else:
                    overall_score -= 1.0
    
    if k > 0:
        overall_score /= k

    if overall_score > 0:
        sentiment = "positive"
    elif overall_score == 0:
        sentiment = "neutral"
    else:
        sentiment = "negative"

    return sentiment, overall_score

class SentimentRequest(BaseModel):
    text: str

@app.post("/predict")
def predict_sentiment(request: SentimentRequest):
    text = request.text
    label, score = simple_sentiment_analysis(text)
    return {"label": label, "score": score}