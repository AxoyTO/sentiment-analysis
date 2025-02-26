// Dynamically determine the API endpoint
const API_URL = determineAPIURL();

function determineAPIURL() {
    if (window.location.hostname === "localhost") {
        return "http://127.0.0.1:8000/predict";
    } 
    
    return "http://sentiment-lb.default.svc.cluster.local/predict";
}

const darkModeToggle = document.getElementById("dark-mode-toggle");

if (localStorage.getItem("dark-mode") === "enabled") {
    document.body.classList.add("dark-mode");
    darkModeToggle.innerText = "☀️";
}

darkModeToggle.addEventListener("click", () => {
    document.body.classList.toggle("dark-mode");

    if (document.body.classList.contains("dark-mode")) {
        localStorage.setItem("dark-mode", "enabled");
        darkModeToggle.innerText = "☀️";
    } else {
        localStorage.setItem("dark-mode", "disabled");
        darkModeToggle.innerText = "🌙";
    }
});

async function analyzeSentiment() {
    const text = document.getElementById("inputText").value;
    if (!text.trim()) {
        alert("Please enter text before analyzing.");
        return;
    }

    document.getElementById("loading").classList.remove("hidden");
    document.getElementById("result").innerHTML = "";

    try {
        const response = await fetch(API_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ text: text })
        });

        const data = await response.json();

        let color = "gray";
        if (data.label === "POSITIVE") color = "green";
        if (data.label === "NEGATIVE") color = "red";

        document.getElementById("result").innerHTML = `
            <span style="color: ${color}">${data.label.toUpperCase()}</span>
            <br>
            <small>Confidence Score: <strong>${parseFloat(data.score).toFixed(2)}</strong></small>
        `;
    } catch (error) {
        document.getElementById("result").innerHTML = "Error: Could not analyze sentiment.";
    }

    document.getElementById("loading").classList.add("hidden");
}
