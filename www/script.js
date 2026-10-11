document.addEventListener("DOMContentLoaded", () => {
    const title = document.querySelector("h1");
    const container = document.querySelector(".container");

    if (!title || !container) {
        return;
    }

    const message = document.createElement("p");
    message.className = "test-message";
    message.textContent = "JavaScript est bien chargé. Cliquez sur le titre pour le tester.";
    container.appendChild(message);

    title.addEventListener("click", () => {
        title.textContent = title.textContent.includes("!")
            ? "Hello AWS 🚀"
            : "Hello World ! 🚀";
    });
});
