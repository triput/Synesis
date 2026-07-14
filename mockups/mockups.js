(() => {
  const stage = document.querySelector(".stage");
  if (!stage) return;

  const setAttr = (key, value) => {
    stage.dataset[key] = value;
  };

  document.querySelectorAll(".seg-btn[data-density]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".seg-btn[data-density]").forEach((b) => {
        b.classList.toggle("is-active", b === btn);
        b.setAttribute("aria-pressed", b === btn ? "true" : "false");
      });
      setAttr("density", btn.dataset.density);
    });
  });

  document.querySelectorAll(".seg-btn[data-frame]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".seg-btn[data-frame]").forEach((b) => {
        b.classList.toggle("is-active", b === btn);
        b.setAttribute("aria-pressed", b === btn ? "true" : "false");
      });
      setAttr("frame", btn.dataset.frame);
    });
  });

  const syncFocusButtons = (value) => {
    setAttr("focus", value);
    document.querySelectorAll(".seg-btn[data-focus]").forEach((b) => {
      const on = b.dataset.focus === value;
      b.classList.toggle("is-active", on);
      b.setAttribute("aria-pressed", on ? "true" : "false");
    });
    document.querySelectorAll(".focus-btn[data-set-focus]").forEach((b) => {
      b.classList.toggle("is-on", b.dataset.setFocus === value);
    });
  };

  document.querySelectorAll(".seg-btn[data-focus]").forEach((btn) => {
    btn.addEventListener("click", () => syncFocusButtons(btn.dataset.focus));
  });

  document.querySelectorAll(".focus-btn[data-set-focus]").forEach((btn) => {
    btn.addEventListener("click", () => syncFocusButtons(btn.dataset.setFocus));
  });

  document.querySelectorAll(".message-list .msg").forEach((row) => {
    row.addEventListener("click", () => {
      document.querySelectorAll(".message-list .msg").forEach((m) => m.classList.remove("is-selected"));
      row.classList.add("is-selected");
    });
  });
})();
