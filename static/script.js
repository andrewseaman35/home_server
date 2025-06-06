const API_URL = 'http://localhost:5889';
const form = document.getElementById('notifyForm');
const submitBtn = document.getElementById('submitBtn');
const statusDiv = document.getElementById('status');
const healthDiv = document.getElementById('healthStatus');

// Theme Toggle Logic
const themeToggle = document.getElementById('themeToggle');

// Check for saved theme preference or default to 'light'
const savedTheme = localStorage.getItem('theme') || 'light';
document.documentElement.setAttribute('data-theme', savedTheme);
themeToggle.checked = savedTheme === 'dark';

// Theme toggle handler
themeToggle.addEventListener('change', (e) => {
    const theme = e.target.checked ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
});

async function checkHealth() {
    try {
        const response = await fetch(`${API_URL}/health`);
        if (response.ok) {
            healthDiv.textContent = 'Service is healthy';
            healthDiv.className = 'health-status healthy';
            submitBtn.disabled = false;
        } else {
            throw new Error('Service unhealthy');
        }
    } catch (error) {
        healthDiv.textContent = 'Service is unavailable';
        healthDiv.className = 'health-status unhealthy';
        submitBtn.disabled = true;
    }
}

async function sendNotification(data) {
    submitBtn.disabled = true;
    try {
        const response = await fetch(`${API_URL}/notify`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            throw new Error(await response.text());
        }

        return response.json();
    } finally {
        submitBtn.disabled = false;
    }
}

form.addEventListener('submit', async (e) => {
    e.preventDefault();
    submitBtn.disabled = true;

    const data = {
        message: document.getElementById('message').value,
    };

    const subject = document.getElementById('subject').value;
    if (subject) {
        data.subject = subject;
    }

    try {
        const result = await sendNotification(data);
        statusDiv.textContent = `Notification sent successfully (ID: ${result.message_id})`;
        statusDiv.className = 'status success';
        form.reset();
    } catch (error) {
        statusDiv.textContent = `Error: ${error.message}`;
        statusDiv.className = 'status error';
    } finally {
        submitBtn.disabled = false;
    }
});

// Initialize health check
checkHealth();
setInterval(checkHealth, 30000);