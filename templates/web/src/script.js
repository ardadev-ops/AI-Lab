const message = document.getElementById("message");
if (message) {
    message.textContent = `Ladezeit: ${new Date().toLocaleTimeString()}`;
}
